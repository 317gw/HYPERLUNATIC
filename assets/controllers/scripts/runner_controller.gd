extends Player

# # https://github.com/selimnahimi/runnervision/blob/dev-preview/code/pawn/PawnController.Util.cs
# class_name RunnerController

# var Entity: CharacterBody3D

# func _init(Body3D: CharacterBody3D):
# 	Entity = Body3D

# #Rotation
# func Get_Velocity_Rotation() -> Vector3:
# 	return Entity.Velocity.normalized()


# func Angle_Within_Range(directionVector1: Vector3, directionVector2: Vector3, minAngle: float = 0, maxAngle: float = 360) -> bool:
# 	if (directionVector1.angle_to(directionVector2) > maxAngle):
# 		return false
# 	if (directionVector1.angle_to(directionVector2) < minAngle):
# 		return false
# 	return true


# func Get_Move_Vector():
# 	var movement = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
# 	var angles = Entity.transform.basis
# 	return angles * movement * Current_Max_Speed


# func Update_Dash() -> void:
# 	if Time_Since_Dash > 0.5:
# 		Dashing = 0


# func Initiate_Jump_Off_Wall() -> void:
# 	pass