class_name IndieBlueprintObjectPoolWrapper extends RefCounted


var pool: IndieBlueprintObjectPool
var instance: Node
var sleeping: bool = true
var id: int


func _init(_pool: IndieBlueprintObjectPool, _id: int) -> void:
	id = _id
	pool = _pool
	instance = pool.scene.instantiate()


func kill() -> void:
	pool.kill(self)


func queue_free() -> void:
	if is_instance_valid(self) and not pool.instance.is_queued_for_deletion():
		pool.instance.queue_free()
		free()
