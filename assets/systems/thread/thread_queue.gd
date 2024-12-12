class_name ThreadQueue
extends RefCounted
# Thread helper for batch jobs.

signal _thread_finished

var threads_max: int = 1

var _threads: int = 0
var _jobs := []
var _mtx := Mutex.new()
var _working: bool = false

func _nop(arg=null): pass

func _init(tmax : int = 1):
	if tmax < 1:
		tmax = 1

	threads_max = tmax
	_thread_finished.connect(__thread_finished)

func clear_jobs() -> void:
	_mtx.lock()
	_jobs.clear()
	_mtx.unlock()

func add_job(function: Callable, callback: Callable = _nop, arguments = null) -> void:
	_mtx.lock()
	_jobs.append(Job.new(function, callback, arguments))
	_mtx.unlock()


func start() -> void:
	_mtx.lock()

	if not _working:
		_working = true

		while _working and _jobs.size() and _threads < threads_max:

			var thread = Thread.new()
			_threads += 1

			thread.start(_work, Thread.PRIORITY_LOW)
	_mtx.unlock()

func _work(thread) -> void:
	while true:
		_mtx.lock()

		if _jobs.size():
			var job = _jobs.pop_front()
			_mtx.unlock()

			if job:
				job.execute()
		else:
			_mtx.unlock()
			break

	# Shitty hack so that we safely(i think) end this Thread
	(
		func(_thread_finished, thread):
			_thread_finished.emit(thread)
	).call_deferred(_thread_finished, thread)

func __thread_finished(_thread: Thread) -> void:
	_mtx.lock()
	_threads -= 1

	# Fairly certain that this Thread should already be dead
	#if thread.is_active():
	#    thread.wait_to_finish.call_deferred()

	if _threads < 0:
		_threads = 0

	if not (_threads and _jobs.size()):
		_working = false

	_mtx.unlock()

class Job extends RefCounted:
	var _function : Callable
	var _callback : Callable
	var _arguments

	func _init(function: Callable, callback: Callable, arguments):
		_function = function
		_callback = callback
		_arguments = arguments

	func execute() -> void:
		_callback.call(_function.call(_arguments))
