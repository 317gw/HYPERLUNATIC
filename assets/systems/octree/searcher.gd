class_name OctreeSearcher
extends RefCounted
## Helper for searching [OctreeNode] instances.

## Array of OctreeNodes that this OctreeSearcher instance will operate on.
var _octrees: Array

## The [ThreadQueue] instance that search Jobs are submitted to.
var _thread_queue: ThreadQueue

## A [Mutex] for search opeations, used for locking search state, not the search function itself.
var _mtx := Mutex.new()

## Whether or not a search is currently running.
var _searching := false

## The number of search Jobs that the current search has submitted to the [ThreadQueue].
var _search_steps := 0

## The number of completed search Jobs.
var _search_steps_complete := 0

## Results of the most recent search, not intended to be accessed,
## use the callback functions instead.
var _search_results := []

## The OctreeNodes that the most recent search intersected with
var _search_nodes := []

## The callback [Callable] that was used in the most recent search request.
var _current_callback: Callable

## The [Callable] used by the most recent search request.
var _current_sorter: Callable

## A Vector3 origin used as a reference by the sorter
var _current_sort_origin: Vector3

## The [method hash] of the most recent search configuration,
## this is used to skip unnecessary search requests by excessive callers.
var last_search_config : int = 0

## floating point value used to grow the search area when searches do not return results.
var radial_distance_accumulator := 0.0

## The most recent searches radial_distance parameter
var last_radial_distance := 0.0

## Stores the search start time, used for performance debugging
var search_start_time := 0.0

## The number of attempts the current search config has made,
## each attempt increases the radial_distance_accumulator and therefore increases the search area.
var attempts = 0


func _init(octrees: Array, thread_queue: ThreadQueue):
	_octrees = octrees
	_thread_queue = thread_queue


## Method used to collect results from search Jobs, perform user callback when results are ready.
## This method is called internally by each search Job.
func _callback(results: Array) -> void:
	_mtx.lock()

	if _search_steps > 0:
		_search_steps_complete += 1
		_search_results += results[0]
		_search_nodes += results[1]

		if _search_steps == _search_steps_complete:
			_search_steps = 0
			_search_steps_complete = 0
			_searching = false
			_search_results.sort_custom(_current_sorter)
			_current_callback.call_deferred(_search_results, _search_nodes)

			if _search_results.is_empty():
				if radial_distance_accumulator == 0.0:
					radial_distance_accumulator = last_radial_distance

				radial_distance_accumulator *= 2.0
				attempts += 1
			else:
				print(
					"attempts: %s\tmsecs: %s\tradial_accumulator: %s" %
					[attempts, Time.get_ticks_msec() - search_start_time, radial_distance_accumulator]
				)
				attempts = 0

	_mtx.unlock()


## Perform a ray search on the OctreeNodes, find items within radial_distance from the ray line.
## Calls the user provided callback [Callable] with results.
## Set sort_origin for custom sort reference point.
func ray_search(origin: Vector3, direction: Vector3, radial_distance: float, callback: Callable, sort_origin = null) -> int:
	if _searching:
		return ERR_BUSY

	if _octrees:
		_mtx.lock()
		search_start_time = Time.get_ticks_msec()
		_searching = true

		if sort_origin:
			_current_sort_origin = sort_origin
		else:
			_current_sort_origin = origin

		_search_steps = 0
		_search_steps_complete = 0

		var search_config = {
			"origin": origin,
			"direction": direction,
			"radial_distance": radial_distance,
			"sort_origin": _current_sort_origin
		}.hash()

		if (search_config == last_search_config):
				if attempts >= 10 or not _search_results.is_empty():
					last_search_config = search_config
					last_radial_distance = radial_distance
					_searching = false
					_mtx.unlock()
					# The caller should already have the results
					return OK
		else:
			radial_distance_accumulator = 0.0

		_current_sorter = sort_radial
		_current_callback = callback
		_search_results = []
		_search_nodes = []
		last_search_config = search_config
		last_radial_distance = radial_distance

		for o in _octrees:
			_search_steps += 1

			_thread_queue.add_job(
				_ray_hits,
				_callback,
				[
					o,
					origin,
					direction,
					radial_distance + radial_distance_accumulator
				]
			)

		_thread_queue.start()
		_mtx.unlock()
	return OK


## Finds the points that match the current search config,
## submits search results to internal _callback method.
func _ray_hits(args) -> Array:
	# Single argument wrapper around Octree._ray_nodes
	var node = args[0]
	var origin: Vector3 = args[1]
	var normal: Vector3 = args[2]
	#var camera: Camera3D = args[3]
	var radial_distance: float = args[3]

	var hits := []
	var nodes := []

	for o in node._ray_nodes(origin, normal, radial_distance):
		if o._data.size() > 0:
			nodes.append(o)
			for position in o._data.keys():
				var dist = _dist_of_nearest_point_along_ray_segment(
					origin, origin + (normal * Global.galaxy_scale * 2), position
				)

				if (dist[0] < radial_distance * dist[1]):
					hits.append([o._data[position], dist[0], dist[1]])

	return [hits, nodes]


func aabb_search(aabb: AABB, callback: Callable) -> int:
	if _searching:
		return ERR_BUSY

	if _octrees:
		_mtx.lock()
		search_start_time = Time.get_ticks_msec()
		_searching = true

		_current_sort_origin = aabb.position

		_search_steps = 0
		_search_steps_complete = 0

		var search_config = {
			"position": aabb.position,
			"size": aabb.size
		}.hash()

		if (search_config == last_search_config):
				if not _search_results.is_empty():
					last_search_config = search_config
					last_radial_distance = 0.0
					_searching = false
					_mtx.unlock()
					# The caller should already have the results
					return OK
		else:
			radial_distance_accumulator = 0.0

		_current_sorter = sort_distance
		_current_callback = callback
		_search_results = []
		_search_nodes = []
		last_search_config = search_config

		for o in _octrees:
			_search_steps += 1
			_thread_queue.add_job(_aabb_hits, _callback, [o, aabb])

		_thread_queue.start()
		_mtx.unlock()
	return OK


func _aabb_hits(args) -> Array:
	# Single argument wrapper around Octree._aabb_nodes
	var node = args[0]
	var aabb = args[1]

	var hits := []
	var nodes := []

	for o in node._aabb_nodes(aabb):
		if o._item_count > 0:
			nodes.append(o)
			for position in o._data.keys():
				if aabb.has_point(position):
					if _current_sort_origin.distance_to(position) < 2.0:
						hits.append([o._data[position], position])

	return [hits, nodes]


## Sorting function based on distance to the sort reference position.
func sort_distance(a, b) -> bool:

	return (
		a[1].distance_squared_to(_current_sort_origin) >
		b[1].distance_squared_to(_current_sort_origin)
	)


## Sorting function based on distance to the ray line
func sort_radial(a, b) -> bool:
	# div by distance along ray to remove bias to nearer points
	return (a[1] / a[2]) < (b[1] / b[2])


## Given a ray segment, calculate the distance of point to the closest point along the ray.
func _dist_of_nearest_point_along_ray_segment(
		start : Vector3, end : Vector3, point : Vector3
	) -> Array:
	# returns array == [dist_to_ray, dist_along_ray]
	var dir : Vector3 = (start - end).normalized()
	var v : Vector3 = point - start
	var d : float = v.dot(dir)

	return [
		abs(point.distance_to(start + dir * d)),
		abs(d),
	]
