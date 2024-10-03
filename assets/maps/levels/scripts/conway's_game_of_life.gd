extends Node3D

signal tween_move
# length
# height

@export var height: int = 10 # 高度
@export var length: int = 50 # 长度
@export var width: int = 50 # 宽度

const ADJACENT_OFFSETS: Array = [
		Vector3i( + 1, 0, -1), Vector3i( + 1, 0, 0), Vector3i( + 1, 0, 1),
		Vector3i( + 0, 0, -1), Vector3i( + 0, 0, 1),
		Vector3i( - 1, 0, -1), Vector3i( - 1, 0, 0), Vector3i( - 1, 0, 1),
		]

var cells_quantity: int
var current_cells_pos: Array = []
var next_cells_item: Array = []
var game_plane: int = 0

@onready var map: Node3D = $Map
@onready var grid_map: GridMap = $Map/GridMap
@onready var depth_map: GridMap = $Map/DepthMap
@onready var turn_timer: Timer = $TurnTimer


func _ready() -> void:
	randomize()
	cells_quantity = length * width
	# calculate_next_cells_item()
	$Map/Pos1.visible = false
	$Map/Pos2.visible = false

	for cell in grid_map.get_used_cells():
		depth_map.set_cell_item(cell, 0)


func _on_turn_timer_timeout() -> void:
	calculate_next_cells_item()
	for cell in range(0, cells_quantity):
		var cell_pos = current_cells_pos[cell]
		if grid_map.get_cell_item(cell_pos) == 0:
			grid_map.set_cell_item(cell_pos, 1)
	game_plane += 1
	apply_cells()
	if game_plane >= height:
		for x in range(1, length + 1):
			for z in range(1, width + 1):
				var current_cell_pos = Vector3i(x, game_plane - height, z) # 当前单元格位置
				grid_map.set_cell_item(current_cell_pos, -1)
				depth_map.set_cell_item(current_cell_pos, -1)

	# set_color()
	tween_move.emit() # 下降


func apply_cells() -> void:
	for cell in range(0, cells_quantity):
		var cell_pos = current_cells_pos[cell]
		cell_pos.y = game_plane
		var cell_item = next_cells_item[cell]
		grid_map.set_cell_item(cell_pos, cell_item)
		depth_map.set_cell_item(cell_pos, cell_item)


func calculate_next_cells_item() -> void:
	current_cells_pos.clear() # 清空当前单元格位置
	next_cells_item.clear() # 清空下一单元格状态
	for x in range(1, length + 1):
		for z in range(1, width + 1):
			var current_cell_pos = Vector3i(x, game_plane, z) # 当前单元格位置
			current_cells_pos.append(current_cell_pos) # 添加当前单元格位置
			var current_cell_item = grid_map.get_cell_item(current_cell_pos)
			var neighbors: int = 0
			for offset in ADJACENT_OFFSETS:
				var adjacent_cell_pos = current_cell_pos + offset
				var adjacent_cell_item = grid_map.get_cell_item(adjacent_cell_pos)
				neighbors += adjacent_cell_item + 1
			var next_cell_item: int = -1
			if current_cell_item == 0 and neighbors > 3: # 拥挤
				next_cell_item = -1
			if current_cell_item == 0 and neighbors < 2: # 孤独
				next_cell_item = -1
			if current_cell_item == 0 and neighbors == 2 or neighbors == 3: # 存活 S23
				next_cell_item = 0
			if current_cell_item == - 1 and neighbors == 3: # 繁殖 B3
				next_cell_item = 0
			next_cells_item.append(next_cell_item)


func cells_down() -> void:
	var last_used_cells: Array = grid_map.get_used_cells()
	grid_map.clear()
	for cell in last_used_cells:
		cell.y -= 1
		grid_map.set_cell_item(cell, 0)


func set_color() -> void:
	var mesh_data = grid_map.mesh_library.get_item_mesh(1)
	if mesh_data:
		var material = mesh_data.surface_get_material(0)
		for cell_pos in grid_map.get_used_cells():
			material.set_shader_parameter("Position", cell_pos)


"""
# 获取特定单元格的 MeshLibrary 项索引
var cell_position = Vector3i(1, 0, 3)  # 通过设置相应的单元格坐标
var item_index = grid_map.get_cell_item(cell_position)
# 从 MeshLibrary 中检索相应的材质信息
if item_index != GridMap.INVALID_CELL_ITEM:
	var mesh_data = grid_map.mesh_library.surface_get_item(item_index)  # 根据索引获取 MeshLibrary 中的项
	var material = mesh_data.surface_get_material(0)  # 假设材质位于索引 0
	# 执行您的操作，使用检索到的材质信息
else:
	# 单元格为空，执行相应的处理
"""
