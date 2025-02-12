@tool
extends Node3D

@export var size: Vector3 = Vector3.ONE
@export var layer: int = 4
@export var layer_ofset: float = 0.5
@export var reset: bool:
	set(value):
		set_multi_mesh()

var plane: Plane


@onready var multi_mesh_instance_3d: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var area_3d: Area3D = $Area3D
@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D



func _ready() -> void:
	set_multi_mesh()
	set_plane()


#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint():
	
	


func set_multi_mesh() -> void:
	multi_mesh_instance_3d.multimesh.set_instance_count(layer)
	for i in layer:
		var _transform: Transform3D = Transform3D(Basis.IDENTITY.from_scale(size), Vector3(0, i*layer_ofset, 0))
		multi_mesh_instance_3d.multimesh.set_instance_transform(i, _transform)


func set_plane() -> void:
	plane = Plane(-basis.y, global_position)
	collision_shape_3d.shape.plane = Plane(-basis.y)


func _on_area_3d_body_entered(body: Node3D) -> void:
	# 获取速度（支持RigidBody和CharacterBody）
	var velocity = _get_body_velocity(body)
	if velocity == Vector3.ZERO:
		return

	## 计算碰撞面法线方向（面朝Z+方向）
	#var normal = global_transform.basis.z.normalized()
	#
	## 计算位置关系
	#var position_vector = body.global_position - global_position
	#var position_dot = position_vector.dot(normal)
	#
	## 计算速度方向
	#var velocity_direction = velocity.normalized()
	#var velocity_dot = velocity_direction.dot(normal)
	#
	## 判断条件：在正面且速度方向朝向碰撞面内部
	#if position_dot > 0 and velocity_dot < 0:
	_handle_projectile(body)


func _get_body_velocity(body):
	if body is RigidBody3D:
		return body.linear_velocity
	elif body is CharacterBody3D:
		return body.velocity
	return Vector3.ZERO


func _handle_projectile(body):
	# 在这里实现你的碰撞处理逻辑
	print("Projectile detected:", body.name)
	# 示例：销毁弹射物
	#body.queue_free()


func _on_area_3d_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
