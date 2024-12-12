extends Node3D

@export var Fish: PackedScene
@export var fishs: int = 20
@export var sice: float = 20

var octree: Octree
var boids = []
#var thread_queue: ThreadQueue
#var searcher: OctreeSearcher

func _ready():
	#octree = Octree.new()
	#thread_queue = ThreadQueue.new()
	
	for _i in range(fishs):
		var fish: Node3D = Fish.instantiate()
		fish.position = Vector3(randf_range(-sice, sice), 1, randf_range(-sice, sice))
		#fish.add_to_group("FlyingFish")
		add_child(fish)
		boids.append(fish)
		#octree.insert(fish.position, fish)
		#fish.activity_center = Vector3.ZERO


#
#func _physics_process(delta: float) -> void:
	#searcher = octree.instantiate_searcher(thread_queue)
	#searcher.ray_search()
