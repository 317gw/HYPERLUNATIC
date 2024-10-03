@tool
extends Node3D

@onready var pos_1: CSGBox3D = $Pos1
@onready var pos_2: CSGBox3D = $Pos2
@onready var life_game: Node3D = $".."
@onready var grid_map: GridMap = $GridMap


func _ready() -> void:
	var size = Vector3(life_game.length, 0, life_game.width)
	position = -size / 2
	pos_1.position = Vector3.ZERO
	pos_2.position = size

	#grid_map.clear()
	#var cob = 10
	#for x in range(1, cob+1):
		#for z in range(1, cob+1):
			#for y in range(1, cob+1):
				#var pos = Vector3(x, y, z)
				#grid_map.set_cell_item(pos, 1)
