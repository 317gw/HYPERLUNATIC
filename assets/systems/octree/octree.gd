class_name Octree
extends RefCounted
## OctreeNode wrapper for spatially storing data.
##
## @desc:
##     This class is effectively a wrapper around OctreeNode, it provides an abstraction over
##     OctreeNode that allows for easier searches and insertions from multiple Threads.
##     The main mechanism by which this is provided is by instantiating the top-level OctreeNode
##     pre-subdivided and providing Mutexes for the `top-level` OctreeNodes during insertions.

## The effective top-level OctreeNodes,
var _octant_nodes: Array

## The top-level OctreeNode Mutexes used during insertions.
var _octant_mutexes: Array

## The actual top-level OctreeNode.
var _octree: OctreeNode

## OctreeSearcher instance configured for relatively "efficient" searching from a ThreadQueue.
var _searcher: OctreeSearcher


## Create a new Octree instance
func _init(center := Vector3.ZERO, size := 1.0, max_items := 1000):
	_octant_mutexes = []
	_octant_nodes = []

	_octree = OctreeNode.new(center, size, max_items)
	_octree._create_octant_nodes()

	for node in _octree._octant_nodes:
		node._create_octant_nodes()

		# Use nested Arrays so that we can still use OctreeNode._get_octant_index
		_octant_nodes.append(node._octant_nodes)
		_octant_mutexes.append(
			[
				Mutex.new(),
				Mutex.new(),
				Mutex.new(),
				Mutex.new(),
				Mutex.new(),
				Mutex.new(),
				Mutex.new(),
				Mutex.new()
			]
		)


## Instantiates and returns an OctreeSearcher for this Octree.
func instantiate_searcher(thread_queue: ThreadQueue) -> OctreeSearcher:
	_searcher = OctreeSearcher.new(
		_get_flat_storage_array(),
		thread_queue
	)

	return _searcher


## Convenience method that returns the total number of items stored within the OctreeNodes
func data_count() -> int:
	if not _octant_nodes.is_empty():
		var count := 0
		for octant_node in _get_flat_storage_array():
			count += octant_node.data_count()

		return count

	return 0


## Inserts data into the Octree at the given position.[br]
## [br]This is effectively a wrapper method around the underlying OctreeNodes's insert method.
## It is a bit messy, but it provides some convenience within this class by abstracting away
## management of Mutexes and allows naive insertions from Threads.[br]
## [br]It *should* be safe to use this from Threads
func insert(position: Vector3, data) -> bool:
	var octant_index_1 = OctreeNode._get_octant_index(position, _octree._center)
	var octant_index_2 = OctreeNode._get_octant_index(
		position, _octree._octant_nodes[octant_index_1]._center
	)

	return _octant_nodes[octant_index_1][octant_index_2].insert(
		position, data, _octant_mutexes[octant_index_1][octant_index_2]
	)


## Returns a flat Array containing each of the effective top-level OctreeNodes
func _get_flat_storage_array() -> Array:
	var nodes := []
	for _octant_node_array in _octant_nodes:
		nodes += _octant_node_array

	return nodes


## Returns a flat Array containing Mutexes that accompany the OctreeNodes
func _get_flat_mutex_array() -> Array:
	var mutexes := []
	for _octant_mutex_array in _octant_mutexes:
		mutexes += _octant_mutex_array

	return mutexes
