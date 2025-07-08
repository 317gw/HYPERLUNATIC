class_name SpatialPartitionSystem
extends Node

# 配置参数
@export var grid_size: Vector3 = Vector3(5.0, 5.0, 5.0)  # 每个网格单元的大小
@export var max_objects_per_cell: int = 100  # 单个网格最大对象数
@export var debug_draw: bool = false  # 调试模式

# 内部数据结构
var grid_cells: Dictionary = {}
var object_registry: Dictionary = {}  # obj: {category, grid_position}
var active_cells: Array = []  # 当前活动的网格单元
var grid_dimensions: Vector3i = Vector3i.ZERO

# 初始化系统
func _ready() -> void:
	# 计算网格维度
	calculate_grid_dimensions()

	# 初始化网格
	initialize_grid()

	# 调试绘制
	if debug_draw:
		set_process(true)

# 计算网格维度
func calculate_grid_dimensions() -> void:
	var world_size = Vector3(1000.0, 500.0, 1000.0)  # 假设世界尺寸
	grid_dimensions = Vector3i(
		ceil(world_size.x / grid_size.x),
		ceil(world_size.y / grid_size.y),
		ceil(world_size.z / grid_size.z)
	)

# 初始化网格
func initialize_grid() -> void:
	grid_cells.clear()
	for x in range(-grid_dimensions.x, grid_dimensions.x + 1):
		for y in range(-grid_dimensions.y, grid_dimensions.y + 1):
			for z in range(-grid_dimensions.z, grid_dimensions.z + 1):
				var cell_pos = Vector3i(x, y, z)
				grid_cells[cell_pos] = GridCell.new(cell_pos)

# 注册对象
func register_object(obj: Node3D, category: String) -> void:
	if not is_instance_valid(obj):
		return

	# 如果对象已注册，先注销
	if object_registry.has(obj):
		unregister_object(obj)

	# 获取网格位置
	var grid_pos = world_to_grid(obj.global_position)

	# 添加到网格
	if grid_cells.has(grid_pos):
		grid_cells[grid_pos].add_object(obj, category)
		object_registry[obj] = {
			"category": category,
			"grid_position": grid_pos
		}

		# 标记为活动网格
		if not active_cells.has(grid_pos):
			active_cells.append(grid_pos)

# 注销对象
func unregister_object(obj: Node3D) -> void:
	if not object_registry.has(obj):
		return

	var grid_pos = object_registry[obj].grid_position
	if grid_cells.has(grid_pos):
		grid_cells[grid_pos].remove_object(obj)

	object_registry.erase(obj)

	# 检查网格是否变为空
	if grid_cells[grid_pos].is_empty():
		var index = active_cells.find(grid_pos)
		if index != -1:
			active_cells.remove_at(index)

# 更新对象位置
func update_object_position(obj: Node3D, new_position: Vector3) -> void:
	if not object_registry.has(obj):
		return

	var old_grid_pos = object_registry[obj].grid_position
	var new_grid_pos = world_to_grid(new_position)

	# 如果网格位置发生变化
	if old_grid_pos != new_grid_pos:
		# 从旧网格移除
		if grid_cells.has(old_grid_pos):
			grid_cells[old_grid_pos].remove_object(obj)

			# 检查旧网格是否变为空
			if grid_cells[old_grid_pos].is_empty():
				var index = active_cells.find(old_grid_pos)
				if index != -1:
					active_cells.remove_at(index)

		# 添加到新网格
		if grid_cells.has(new_grid_pos):
			grid_cells[new_grid_pos].add_object(obj, object_registry[obj].category)
			object_registry[obj].grid_position = new_grid_pos

			# 标记新网格为活动
			if not active_cells.has(new_grid_pos):
				active_cells.append(new_grid_pos)

# 世界坐标转网格坐标
func world_to_grid(position: Vector3) -> Vector3i:
	return Vector3i(
		floori(position.x / grid_size.x),
		floori(position.y / grid_size.y),
		floori(position.z / grid_size.z)
	)

# 网格坐标转世界坐标
func grid_to_world(grid_pos: Vector3i) -> Vector3:
	return Vector3(
		grid_pos.x * grid_size.x,
		grid_pos.y * grid_size.y,
		grid_pos.z * grid_size.z
	)

# 查询附近对象
func query_nearby(position: Vector3, radius: float, categories: Array[String] = []) -> Array[Node3D]:
	var center_grid = world_to_grid(position)
	var radius_cells = ceil(radius / min(grid_size.x, grid_size.y, grid_size.z))

	var results = []

	# 计算需要查询的网格范围
	for x in range(center_grid.x - radius_cells, center_grid.x + radius_cells + 1):
		for y in range(center_grid.y - radius_cells, center_grid.y + radius_cells + 1):
			for z in range(center_grid.z - radius_cells, center_grid.z + radius_cells + 1):
				var grid_pos = Vector3i(x, y, z)
				if grid_cells.has(grid_pos):
					results.append_array(grid_cells[grid_pos].get_objects(categories))

	# 精确距离过滤
	var sqr_radius = radius * radius
	var filtered_results = []
	for obj in results:
		if position.distance_squared_to(obj.global_position) <= sqr_radius:
			filtered_results.append(obj)

	return filtered_results

# 查询区域内的对象
func query_in_volume(aabb: AABB, categories: Array[String] = []) -> Array[Node3D]:
	var min_grid = world_to_grid(aabb.position)
	var max_grid = world_to_grid(aabb.end)

	var results = []

	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			for z in range(min_grid.z, max_grid.z + 1):
				var grid_pos = Vector3i(x, y, z)
				if grid_cells.has(grid_pos):
					results.append_array(grid_cells[grid_pos].get_objects(categories))

	# 精确AABB过滤
	var filtered_results = []
	for obj in results:
		if aabb.has_point(obj.global_position):
			filtered_results.append(obj)

	return filtered_results

# 获取特定类别的所有对象
func get_all_objects_in_category(category: String) -> Array[Node3D]:
	var results = []
	for cell in active_cells:
		if grid_cells.has(cell):
			results.append_array(grid_cells[cell].get_objects([category]))
	return results

# 调试绘制
func _process(_delta: float) -> void:
	if not debug_draw:
		return

	for grid_pos in active_cells:
		if grid_cells.has(grid_pos):
			var cell = grid_cells[grid_pos]
			var world_pos = grid_to_world(grid_pos)

			# 绘制网格边界
			DebugDraw.draw_box(
				world_pos + grid_size * 0.5,
				grid_size,
				Color(1, 0, 0, 0.2),
				0.0
			)

			# 显示对象数量
			var obj_count = cell.object_count()
			DebugDraw.draw_text_3d(
				world_pos + Vector3(0, grid_size.y, 0),
				str(obj_count),
				Color.WHITE
			)
