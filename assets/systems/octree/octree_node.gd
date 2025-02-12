class_name OctreeNode
extends RefCounted
## Shitty Octree implementation for spatially storing data.

## The center position of the OctreeNode volume.
var _center : Vector3

## The OctreeNode volume size.
var _size : float

## The OctreeNode volume size, halved.
var _half_size : float

## An [AABB] instance for this OctreeNode, used for intersection math.
## This *might* be null if used externally.
var _aabb

## A [Dictionary] used for storing the data within this OctreeNode,
## is empty when this OctreeNode is subdivided.
var _data: Dictionary = {}

## An [Array] for storing this OctreeNode octant children,
## is empty until this OctreeNode is subdividied.
var _octant_nodes : Array = []

## The maximum number of items this OctreeNode can store before being subdividied.
var max_items : int


func _init(center: Vector3 = Vector3.ZERO, size: float = 1.0, _max_items: int = 1000):
	max_items = _max_items
	_center = center
	_size = size
	_half_size = _size * 0.5


## Helper method for recursively counting the number of items stored within this OctreeNode.
func data_count() -> int:
	if not _octant_nodes.is_empty():
		var count = 0
		for node in _octant_nodes:
			count += node.data_count()

		return count
	else:
		return _data.size()


## Generate, store and return AABB for native intersection math
func _get_aabb() -> AABB:
	if _aabb:
		return _aabb

	_aabb = AABB(_center - Vector3.ONE * _half_size, Vector3.ONE * _size)
	return _aabb


## Add data to this Node for a given Vector3 position
func insert(position : Vector3, data, mtx : Mutex) -> bool:
	if not _get_aabb().has_point(position):
		# Early exit if this position is not valid for this OctreeNode
		return false

	if not _octant_nodes.is_empty():
		# We have children so offload to them
		mtx.lock()
		var node = _octant_nodes[_get_octant_index(position, _center)]
		mtx.unlock()

		if node == null:
			# Position is outside of Octree Node area
			return false

		return node.insert(position, data, mtx)
	else:
		# Add this request payload to appropriate node
		# Store in _data
		mtx.lock()

		if _data.keys().has(position):
			# we already have this position
			mtx.unlock()
			return false

		_data[position] = data

		if _data.size() >= max_items:
			# Too much data, spawn octant nodes and shuffle data to them
			_create_octant_nodes()

			# Transfor data from this node into its octant nodes
			for key in _data.keys():
				var node = _octant_nodes[_get_octant_index(position, _center)]
				node._data[key] = _data[key]

			_data.clear()

		mtx.unlock()
		return true


## Compute the index of this OctreeNode's _octant_nodes Array that would store the given position.
## the computed index aligns with the _octant_nodes Array order.
static func _get_octant_index(position: Vector3, center: Vector3) -> int:
	var oct = 0

	if position.x >= center.x:
		oct |= 4

	if position.y >= center.y:
		oct |= 2

	if position.z >= center.z:
		oct |= 1

	return oct


## Create child Nodes for this Octree Node, produces 8 octant child Nodes.
func _create_octant_nodes() -> void:
	var n_size = _half_size
	#var n_hsize = n_size * 0.5
#
	for i in range(0, 8):
		var n_center = _center
		if i&4:
			n_center.x += n_size * 0.5
		else:
			n_center.x += n_size * -0.5

		if i&2:
			n_center.y += n_size * 0.5
		else:
			n_center.y += n_size * -0.5

		if i&1:
			n_center.z += n_size * 0.5
		else:
			n_center.z += n_size * -0.5

		_octant_nodes.append(
			OctreeNode.new(n_center, n_size, max_items)
		)


## Given a ray (origin, direction), find all intersecting OctreeNodes.
## The grow argument will increase the size of the underlying AABB's for more generous ray
## intersections, this is useful for volume "ray" hits.
func _ray_nodes(origin: Vector3, direction: Vector3, grow: float = 0.0) -> Array:
	if _octant_nodes.is_empty():
		# This node has no children and therefore stores data, return self
		if _get_aabb().grow(grow).intersects_ray(origin, direction):
			return [self]
	else:
		# This node has children, we should check with its children if the ray intersects
		var c = []
		for child in _octant_nodes:
			var r = child._ray_nodes(origin, direction, grow)
			if r:
				c += r
		return c

	return []


## Given a AABB, find all intersecting OctreeNodes.
func _aabb_nodes(aabb: AABB) -> Array:
	if _octant_nodes.is_empty():
		# This node has no children and therefore stores data, return self
		if _get_aabb().intersects(aabb):
			return [self]
	else:
		# This node has children, we should check with its children if the ray intersects
		var c = []
		for child in _octant_nodes:
			var r = child._aabb_nodes(aabb)
			if r:
				c += r
		return c
	return []
