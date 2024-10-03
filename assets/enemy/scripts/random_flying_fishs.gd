extends Node3D

@export var Fish: PackedScene
@export var fishs: int = 20
@export var sice: float = 20


func _ready():
	for _i in range(fishs):
		randomize()
		var fish = Fish.instantiate()
		# var sice := 20.0
		fish.position = Vector3(randf_range(-sice, sice), 1, randf_range(-sice, sice))
		fish.add_to_group("FlyingFish")
		add_child(fish)
