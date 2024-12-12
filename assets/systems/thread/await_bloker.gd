# https://www.bilibili.com/video/BV1spBRYcEFp/?spm_id_from=333.337.search-card.all.click&vd_source=c94b03c06d9c9a8ac9161e5edeb2be10

class_name AwaitBloker

# NOTE: 用作 await 信号的中继器
signal continued

func go_on_deferred():
	continued.emit.call_deferred()


"""
	var blocker:= AwaitBloker.new()
	WorkerThreadPool.add_task(func():
		blocker.set_meta("vectors", get_flock_status(_flock, self_pos))
		blocker.go_on_deferred()
	)
	await blocker.continued
	var vectors = blocker.get_meta("vectors")
"""
