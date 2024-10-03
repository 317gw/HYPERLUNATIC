@tool # 将此脚本标记为编辑器工具，允许在编辑器中运行
extends MeshInstance3D # 继承MeshInstance3D类

var cam_pos_prev = Vector3() # 上一帧相机的位置
var cam_rot_prev = Quaternion() # 上一帧相机的旋转四元数

func _process(_delta): # _process函数，每一帧都会调用
	
	# OS.delay_msec(30) # 延迟30毫秒
	
	var mat: ShaderMaterial = get_surface_override_material(0) # 获取材质
	var cam = get_parent() # 获取父节点，通常是相机
	assert(cam is Camera3D) # 断言父节点是Camera3D类型
	
	# 线性速度是两帧之间位置的差
	var velocity = cam.global_transform.origin - cam_pos_prev # 计算线性速度
	
	# 计算角速度稍微复杂一些
	# 参考 https://math.stackexchange.com/questions/160908/how-to-get-angular-velocity-from-difference-orientation-quaternion-and-time
	var cam_rot = Quaternion(cam.global_transform.basis) # 当前帧相机的旋转四元数
	var cam_rot_diff = cam_rot - cam_rot_prev # 旋转差
	var cam_rot_conj = conjugate(cam_rot) # 当前帧相机旋转四元数的共轭
	var ang_vel = (cam_rot_diff * 2.0) * cam_rot_conj # 计算角速度
	ang_vel = Vector3(ang_vel.x, ang_vel.y, ang_vel.z) # 将四元数转换为Vector3
	
	mat.set_shader_parameter("linear_velocity", velocity) # 设置着色器的线性速度参数
	mat.set_shader_parameter("angular_velocity", ang_vel) # 设置着色器的角速度参数
		
	cam_pos_prev = cam.global_transform.origin # 更新上一帧相机位置
	cam_rot_prev = Quaternion(cam.global_transform.basis) # 更新上一帧相机旋转
	
# 计算四元数的共轭
func conjugate(quat):
	return Quaternion(-quat.x, -quat.y, -quat.z, quat.w) # 返回四元数的共轭
