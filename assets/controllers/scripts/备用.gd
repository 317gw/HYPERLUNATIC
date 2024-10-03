extends Node

	
# 	#Movement(delta)
	
# 	#Current_Max_Speed

	
# 	#var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
# 	#if input_dir and is_on_floor():
# 		#var moveVector := transform.basis * Vector3(input_dir.x, 0, input_dir.y) * Current_Max_Speed
# 		#Do_Movement(moveVector)
# 		#Do_Accelerate(moveVector)
# 		#Do_Apply_Friction()
	

# func Movement(delta):
# 	# 获取输入方向并处理移动/减速
# 	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
# 	var direction :=(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() # 计算移动方向
# 	var direction2D := Vector2(direction.x, direction.z) # 归一化的
# 	var velocity2D := Vector2(velocity.x, velocity.z) # 水平速度
# 	if direction and is_on_floor(): # 如果有移动方向 地上
# 		if velocity2D.length() >= Normal_Speed:
# 			#var weight = Speed_Curve.sample(direction_Similarity)
# 			#var lerps = clamp(
# 				#lerp(
# 					#Acceleration_Normal, 
# 					#lerp(
# 						#Acceleration_Normal, 
# 						#Acceleration_Max, 
# 						#weight), 
# 					#velocity2D.length()/Normal_Speed), 
# 				#Acceleration_Max, 
# 				#Acceleration_Normal)
# 			#
# 			#velocity2D = velocity2D.move_toward(direction2D * Max_Speed, lerps * delta)
# 			var direction_Similarity = (velocity2D.dot(direction2D)+ 1)/ 2# 和方向的相似度 0~1
# 			var angle = velocity2D.angle_to(direction2D)
# 			if angle <= (30*PI/180):
# 				velocity2D = velocity2D.move_toward(direction2D * Max_Speed, Max_Speed / 0.2 * delta)
# 			elif angle <= (90*PI/180):
# 				velocity2D = velocity2D.move_toward(direction2D * Max_Speed, Max_Speed / 1 * delta)
# 			else:
# 				velocity2D = velocity2D.move_toward(direction2D * Max_Speed, Max_Speed / 5 * delta)
# 		elif velocity2D.length() == Normal_Speed:
# 			velocity2D = velocity2D.move_toward(direction2D * Normal_Speed, Acceleration_Normal * delta)
# 		else:
# 			velocity2D = velocity2D.move_toward(direction2D * Normal_Speed, Acceleration_Normal * delta)
# 	elif direction and not is_on_floor(): # 如果有移动方向 空中
# 		velocity2D = velocity2D.move_toward(direction2D * Air_Speed, Air_Acceleration * delta)
# 	elif is_on_floor(): # 地上
# 		velocity2D = velocity2D.move_toward(Vector2.ZERO, Normal_Speed) # x轴速度减速到0
	
	
# 	velocity.x = velocity2D.x
# 	velocity.z = velocity2D.y

# """
# if velocity2D.length() < Normal_Speed:
# 	Acceleration_Normal 移动快速响应
# if velocity2D.length() > Normal_Speed:
# 	最大Max_Speed
# 	目标速度方向在速度方向左右60度内 速度响应快
# 	其他水平180 减速到Normal_Speed
# 	方向向后水平180 刹车到0   -> 到正常流程
# """

# ##########
# func Get_Move_Vector() -> Vector3: # 获取移动向量
# 	var movement = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
# 	var angles = transform.basis # 获取当前角度
# 	return angles * movement * Current_Max_Speed # 返回移动向量


# func Do_Movement(moveVector: Vector3) -> void: # 执行移动
# 	if Should_Accelerate(): # 如果应该加速
# 		Do_Accelerate(moveVector) # 执行加速
# 	Do_Apply_Friction() # 执行应用摩擦力


# func Do_Accelerate(moveVector: Vector3) -> void: # 执行加速
# 	velocity = Accelerate(velocity, moveVector.normalized(), moveVector.length(), Current_Max_Speed, Acceleration) # 使用加速函数计算速度


# func Do_Apply_Friction() -> void: # 执行应用摩擦力
# 	velocity = Apply_Friction(velocity, Get_Friction()) # 使用摩擦力函数计算速度


# func Should_Accelerate() -> bool: # 是否应该加速
# 	if Is_Sliding(): # 如果正在滑动
# 		return false # 返回false
# 	return true # 返回true


# func Get_Friction() -> float: # 获取摩擦力
# 	if Is_Sliding(): # 如果正在滑动
# 		return Friction * 0.5 # 返回摩擦力的一半
# 	return Friction # 返回摩擦力

# ##########
# func Is_Sliding() -> bool: # 是否滑动
# 	return false # 返回false


# func Accelerate(Velocity: Vector3, wishdir: Vector3, wishspeed: float, speedLimit: float, acceleration: float) -> Vector3: # 加速函数
# 	if speedLimit > 0 and wishspeed > speedLimit: # 如果速度限制大于0且期望速度大于速度限制
# 		wishspeed = speedLimit # 期望速度设为速度限制
# 	Velocity = Velocity.lerp(wishdir * wishspeed, get_physics_process_delta_time() * 45.0 * acceleration) # 使用线性插值函数计算速度
# 	return Velocity # 返回速度


# func Apply_Friction(Velocity: Vector3, frictionAmount: float) -> Vector3: # 摩擦力函数
# 	var StopSpeed: float = 7.0 # 停止速度
# 	var speed = Velocity.length() # 计算速度大小
# 	if speed < 0.1: # 如果速度小于0.1
# 		return Velocity # 返回速度
	
# 	# 减少一些速度，但如果速度小于减速阈值，就减少阈值的量。
# 	var control: float = StopSpeed if speed < StopSpeed else speed # 控制速度
# 	var drop = control * get_physics_process_delta_time() * frictionAmount # 计算减速量
	
# 	# 缩放速度
# 	var newspeed: float = speed - drop # 计算新速度
# 	if newspeed < 0: # 如果新速度小于0
# 		newspeed = 0 # 新速度设为0
# 	if newspeed == speed: # 如果新速度等于原速度
# 		return Velocity # 返回速度
	
# 	newspeed /= speed # 计算新速度比例
# 	Velocity *= newspeed # 缩放速度
# 	return Velocity # 返回速度





# func Apply_Friction(Velocity: Vector2, frictionAmount: float) -> Vector2: # 摩擦力函数
# 	var StopSpeed: float = 5.0 # 停止速度
# 	var speed = Velocity.length() # 计算速度大小
# 	if speed < 0.1: # 如果速度小于0.1
# 		return Velocity # 返回速度
	
# 	# 减少一些速度，但如果速度小于减速阈值，就减少阈值的量。
# 	var control: float # 控制速度
# 	if speed < StopSpeed:
# 		control = StopSpeed 
# 	else:
# 		control = speed
# 	frictionAmount = clamp(frictionAmount, 0, Current_Speed_Max)
# 	var drop = control * get_physics_process_delta_time() * 5 # 计算减速量
	
# 	# 缩放速度
# 	var newspeed: float = speed - drop # 计算新速度
# 	if newspeed < 0: # 如果新速度小于0
# 		newspeed = 0 # 新速度设为0
# 	if newspeed == speed: # 如果新速度等于原速度
# 		return Velocity # 返回速度
	
# 	Velocity *= newspeed / speed #  计算新速度比例 缩放速度
# 	return Velocity # 返回速度







# func Look_back_and_Turn_round2():
# 	if is_look_back:
# 		look_back_rotation = lerp(look_back_rotation, PI*angle_sign, PI*DELTA / LookTurn_Time) # Q键回头
	
# 	if not is_look_back and is_turn_round:
# 		look_back_rotation = lerp(look_back_rotation, 0.0, PI*DELTA / LookTurn_Time)
	
# 	if is_turn_round:
# 		turn_round_rotation = lerp(turn_round_rotation, PI*angle_sign, PI*DELTA / LookTurn_Time)
# 		if is_equal_approx(turn_round_rotation, PI):
# 			turn_round_rotation = 0.0
# 			_mouse_rotation.y += PI
# 			is_turn_round = false



# func Look_back():
# 	if look_back_disabled_timer.time_left == 0:
# 		if Input.is_action_just_pressed("look_back") and look_back_timer.time_left == 0:
# 			look_back_timer.start()
# 			is_look_back = true
# 			if Input.is_action_pressed("look_back"):
# 				is_look_back = true
# 	if look_back_timer.is_stopped() and not Input.is_action_pressed("look_back"):
# 		is_look_back = false
	
	
	
	



# func Turn_round():
# 	if Input.is_action_pressed("turn_round"):
# 		if turn_round_timer.time_left == 0:
# 			turn_round_timer.start()
# 		else:
# 			turn_round_timer.stop()
# 			is_turn_round = true
# 			is_look_back = false
# 			if look_back_disabled_timer.time_left == 0:
# 				look_back_disabled_timer.start()



# func _Look_back_and_Turn_round():
# 	var can_look_back = 0
	
# 	var camera2D := CAMERA_CONTROLLER.global_rotation.y
# 	var forward2D := Vector2(transform.basis.z.z, transform.basis.z.x)
# 	print(
# 		str(rad_to_deg(forward2D.angle()))  + " - " +
# 		str(rad_to_deg(camera2D)) +  " = " +
# 		str(rad_to_deg(forward2D.angle() - camera2D)))
	
# 	if Input.is_action_just_pressed("look_back_and_turn_round"):
# 		if abs(Velocity2D.angle_to(forward2D)) < deg_to_rad(15):
# 			angle_sign = 1 if _rotation_input >= 0 else -1
# 		else:
# 			angle_sign = 1 if forward2D.angle() >= camera2D else -1
	
	
# 	if Input.is_action_pressed("look_back_and_turn_round"):
# 		is_look_back = true
# 	else:
# 		is_look_back = false
	
	
# 	if is_look_back:
# 		look_back_rotation = lerp(look_back_rotation, PI, PI*DELTA / LookTurn_Time) # 回头
# 	else:
# 		look_back_rotation = lerp(look_back_rotation, 0.0, PI*DELTA / LookTurn_Time)


# #func Get_angle_sign(event):
# 	#if event.is_action_pressed("look_back_and_turn_round"):
# 		#angle_sign = 1 if _rotation_input >= 0 else -1






	# print("player.direction:", player.direction, "player.dash_dir3d:", player.dash_dir3d, "target_pos:", target_pos)
	# if player.is_player_idle():
	# 	target_pos = collision.global_position

	# # 方向为当前全局位置指向目标位置的向量
	# var direction: Vector3 = global_position.direction_to(target_pos)
	# var distance = global_position.distance_to(target_pos)

	# XXXX限制线性阻尼
	# 把global_position限定到以collision.global_position为圆心，limit_distance为半径的球内

	# if global_position.distance_to(collision.global_position) > limit_distance:
	# 	# linear_damp = linear_damp_max / distance # * abs(v) * 0.1
	# 	global_position = collision.global_position + collision.global_position.direction_to(global_position) * limit_distance

	# linear_damp = clamp(linear_damp, 0, linear_damp_max)

	# # 在吸附距离内时，设置线性速度为零，并将全局位置设置为碰撞体的全局位置
	# if distance < sorption_distance:
	# 	linear_velocity = Vector3.ZERO
	# 	global_position = collision.global_position



	



	# // 使用噪声材质的偏移
	# //vec4 noise_tex = texture(ring_noise, UV + noise_offset);

	# //vec2 uvb = UV; // * uv1_scale + uv1_offset
	# //vec2 uvb = coordinates(UV,effect_center, ring_noise_scale, ring_noise_offset);

	# //float x = UV.x * 5.0;
	# //float m = min(fract(x), fract(1.0 - x));

	# //ALBEDO = texture(ring_noise, uvb).rgb;

	# //ALBEDO = vec3(glow);
	# // * vec3(power)

	# //临时借用texture_multiplier
	# //vec4 txt_mult = texture(texture_multiplier, UV);
	# //ALPHA = luminance(txt_mult.rgb);



	# for i in range(cloud_count):
	# 	var cloud = CLOUD_SPRITES.instantiate()

	# 	var rand_pos: Vector3 = Vector3.ZERO
	# 	rand_pos.y = height + rand(height_offset)

	# 	#随机水平角度
	# 	var rand_angle = randf_range(0, TAU)
	# 	rand_pos.x = radius * sin(rand_angle) + rand(radius_offset)
	# 	rand_pos.z = radius * cos(rand_angle) + rand(radius_offset)


	# 	# var rand_dir: Vector3 = Vector3(rand(2) - 1, 0, rand(2) - 1)
	# 	# rand_dir = rand_dir.normalized()


	# 	# Vector3(radius + rand(radius_offset), height + rand(height_offset), radius + rand(radius_offset))
	# 	cloud.set_position(rand_pos)
	# 	cloud.set_scale(cloud_scale * Vector3.ONE)

	# 	cloud.frame = randi_range(0, 10)
	# 	cloud.set_rotation(Vector3(0, 0, cloud_rotation))
	# 	#cloud.set_speed(cloud_speed)
	# 	#cloud.set_texture(cloud_texture)
	# 	#cloud.set_color(cloud_color)
	# 	add_child(cloud)



	# for child: AnimatedSprite3D  in get_children():
	# 	center = self.global_position
	# 	var speed = cloud_speed * _delta
	# 	var direction = self.global_position.direction_to(child.global_position)

	# 	var distance = self.global_position.distance_to(child.global_position)
	# 	var polar_angle_xz = -Vector2(direction.x, direction.z).angle_to(Vector2.RIGHT)

	# 	child.global_position = polar_vector(polar_angle_xz + speed, 800, child.global_position.y)

	# 	# 让z轴方向的云面向父节点的中心
	# 	# and center.angle_to(Vector3(0, 1, 0)) > 0
	# 	if child.global_position != center:
	# 		child.look_at(center)
	# 	child.rotation.x = 0
	# 	child.rotation.z = 0

	# 	var cloud_scale_temp = cloud_scale
	# 	if r_offset != 0:
	# 		cloud_scale += r_offset_x_scale *((distance - cloud_radius + r_offset)/(2 * r_offset))
	# 	child.set_scale(cloud_scale_temp * Vector3.ONE)

	# 	# child.position += direction * speed

	# 	# child.position = Vector3( # 绕父节点中心Y轴水平旋转
	# 	# 	child.position.x * cos(speed) - child.position.z * sin(speed),
	# 	# 	child.position.y,
	# 	# 	child.position.x * sin(speed) + child.position.z * cos(speed)
	# 	# )


# 		//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;

# 	//vec3 normal = normalize(NORMAL);
# 	//vec3 view_dir = normalize(VIEW);
# 	//n_dot_l = dot(normal, LIGHT);
# 	//n_dot_v = dot(normal, view_dir);

# 	//// 双面透光效果
# 	//vec3 normal = normalize(NORMAL);
# 	//vec3 view_dir = normalize(VIEW);
# 	//float NdotL = dot(normal, LIGHT);
# 	//float NdotV = dot(normal, view_dir);
# //
# 	//// 计算光照强度
# 	//float diffuse = max(0.0, NdotL);
# 	//float specular = pow(max(0.0, dot(reflect(-LIGHT, normal), view_dir)), 32.0);
# //
# 	//// 应用光照
# 	//DIFFUSE_LIGHT *= diffuse + specular;







# struct LuminanceWeight {
# 	float luminance;
# 	float weight;
# };

# LuminanceWeight average_luminance_gaussian(sampler2D tex, vec2 uv, vec2 viewport_size, float sigma) {
# 	vec2 one_pixel = 1.0 / viewport_size;
# 	float sum = 0.0;
# 	float weight_sum = 0.0;
# 	int radius = int(ceil(3.0 * sigma)); // 通常取3倍标准差作为半径

# 	for (int x = -radius; x <= radius; x++) {
# 		for (int y = -radius; y <= radius; y++) {
# 			vec2 offset = vec2(float(x), float(y)) * one_pixel;
# 			float weight = gaussian_weight(x, y, sigma);
# 			vec3 sample_color = texture(tex, uv + offset).rgb;
# 			float luminance = dot(sample_color, vec3(0.2126, 0.7152, 0.0722)); // 计算亮度
# 			sum += luminance * weight;
# 			weight_sum += weight;
# 		}
# 	}
# 	return LuminanceWeight(sum / weight_sum, weight_sum);
# }

# float double_blur(sampler2D tex, vec2 uv, vec2 viewport_size, float sigma) {
# 	LuminanceWeight first_blur = average_luminance_gaussian(tex, uv, viewport_size, sigma);
# 	LuminanceWeight second_blur = average_luminance_gaussian(tex, uv, viewport_size, sigma);
# 	return (first_blur.luminance * first_blur.weight + second_blur.luminance * second_blur.weight) / (first_blur.weight + second_blur.weight);
# }





# //uniform vec3 COLOR_A : source_color;
# //uniform vec3 COLOR_B : source_color;
# //uniform float THRESHOLD: hint_range(-1,1) = 0.;
# //
# //void light() {
# 	//// you can add more colors, or perhaps a texture
# 	//vec3 f = mix(COLOR_A,COLOR_B, step(THRESHOLD, dot(NORMAL, LIGHT)));
# 	//// normalize the lighting, by dividing by the number of effective lights, or some other function
# 	//f /= 5.;
# 	//DIFFUSE_LIGHT += f;
# //}




	# var tween = create_tween() # 渐入渐出动画
	# tween.set_trans(Tween.TRANS_CUBIC)
	# tween.tween_property(self, "target_player_rotation", target_rotation, target_player_rotation_speed)



			#staticbody.rotation = Vector3.ZERO
		#picked_object.look_at(camera_3d.global_position)

		#var tween := get_tree().create_tween()
		#tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		#tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
		#tween.set_trans(Tween.TRANS_LINEAR)
		#tween.set_ease(Tween.EASE_IN_OUT)
		#tween.tween_property(staticbody, "rotation", staticbody.rotation - picked_object.rotation, 1)

		#var rr = obj_rota_in_camera_basis

		#staticbody.rotation = picked_object.rotation * camera_3d.global_basis
		#picked_object.rotation

		# var last_rota = picked_object.global_rotation
		# picked_object.look_at(camera_3d.global_position)
		# var new_rota = picked_object.global_rotation
		# print(last_rota, "   ", new_rota)


## 下面的废了
## https://github.com/mrezai/GodotStairs
#const STAIRS_FEELING_COEFFICIENT: float = 2.5 ## 楼梯上的移动感觉
#const WALL_MARGIN: float = 0.001 ## 墙壁边缘的容差
#const STEP_DOWN_MARGIN: float = 0.01 ## 步下时的容差
#const STEP_HEIGHT_DEFAULT: Vector3 = Vector3(0, 0.6, 0) ## 步高默认值
#const STEP_HEIGHT_IN_AIR_DEFAULT: Vector3 = Vector3(0, 0.6, 0) ## 空中步高默认值
#const STEP_MAX_SLOPE_DEGREE: float = 45.0 ## 最大斜坡度
#const STEP_CHECK_COUNT: int = 2 ## 步进检测次数
#const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT: float = 0.4 ## 跳跃后速度限制系数
#const SPEED_CLAMP_SLOPE_STEP_UP_COEFFICIENT: float = 0.4 ## 斜坡上升时的速度限制系数
#
#@export var is_enabled_stair_stepping_in_air: bool = true
#
#var is_step: bool = false ## 是否在步行
#var step_height_main: Vector3 ## 步高
#var step_incremental_check_height: Vector3 ## 步进检测高度
#
#class StepResult:
	#var diff_position: Vector3 = Vector3.ZERO
	#var normal: Vector3 = Vector3.ZERO
	#var is_step_up: bool = false
#
#
#func step_check2(delta: float, is_jumping: bool, step_result: StepResult):
	#is_step = false
#
	#step_height_main = STEP_HEIGHT_DEFAULT
	#step_incremental_check_height = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
	#if is_in_air() and is_enabled_stair_stepping_in_air:
		##print("设置步高为空中默认步高")
		#step_height_main = STEP_HEIGHT_IN_AIR_DEFAULT
		#step_incremental_check_height = STEP_HEIGHT_IN_AIR_DEFAULT / STEP_CHECK_COUNT
#
	#print("     ")
	#print("     ")
	#if velocity.y >= 0: # 向上运动
		#print("-1step_up")
		#step_up(delta, step_result)
#
	#if not is_jumping and not is_step and is_on_floor(): # 如果没有在跳跃，且没有在步行，且在地面上，则进行下降检测
		#print("-2step_down")
		#step_down(delta, step_result)
	#return is_step
#
#
#func step_up(delta, step_result) -> void:
	#for i in range(STEP_CHECK_COUNT):
		#var step_height: Vector3 = step_height_main - i * step_incremental_check_height
#
		#var test_motion_result:= PhysicsTestMotionResult3D.new()
		#var test_motion_params:= PhysicsTestMotionParameters3D.new()
		#var transform3d: Transform3D = global_transform
		#var motion: Vector3 = step_height
#
		#var is_player_collided: bool = test_player_collided(test_motion_params, transform3d, motion, test_motion_result)
#
		## 如果检测到碰撞且碰撞法线方向向下，则跳过此次检查。
		#if is_player_collided and test_motion_result.get_collision_normal().y < 0:
			#print("Continue")
			#continue
		#transform3d.origin += step_height
		#motion = Vector3(vel2d.x, 0, vel2d.y) * delta
		#is_player_collided = test_player_collided(test_motion_params, transform3d, motion, test_motion_result)
#
		#if not is_player_collided:
			#print("step_up1")
			#if collided_check_A(is_player_collided, motion, transform3d, test_motion_params, test_motion_result, step_result, step_height):
				#print("break1")
				#break
		#else: # 如果检测到墙壁碰撞，则处理墙壁碰撞并继续检查步进。
			#print("step_up2")
			#var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			#transform3d.origin += wall_collision_normal * WALL_MARGIN
			#motion = (Vector3(vel2d.x, 0, vel2d.y) * delta).slide(wall_collision_normal)
			#is_player_collided = test_player_collided(test_motion_params, transform3d, motion, test_motion_result)
			#if not is_player_collided:
				#print("step_up3")
				#if collided_check_A(is_player_collided, motion, transform3d, test_motion_params, test_motion_result, step_result, step_height):
					#print("break2")
					#break
	#print("step_up out")
#
#
#func step_down(delta, step_result) -> void:
	#step_result.is_step_up = false
#
	#var test_motion_result:= PhysicsTestMotionResult3D.new()
	#var test_motion_params:= PhysicsTestMotionParameters3D.new()
	#var transform3d: Transform3D = global_transform
	#var motion: Vector3 = Vector3(vel2d.x, 0, vel2d.y) * delta
#
	#test_motion_params.recovery_as_collision = true
#
	#var is_player_collided: bool = test_player_collided(test_motion_params, transform3d, motion, test_motion_result)
#
	#if not is_player_collided:
		#print("step_down1")
		#collided_check_B(is_player_collided, motion, transform3d, test_motion_params, test_motion_result, step_result)
	#elif is_zero_approx(test_motion_result.get_collision_normal().y):
		#print("step_down2")
		#var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
		#transform3d.origin += wall_collision_normal * WALL_MARGIN
		#motion = (Vector3(vel2d.x, 0, vel2d.y) * delta).slide(wall_collision_normal)
		#is_player_collided = test_player_collided(test_motion_params, transform3d, motion, test_motion_result)
		#if not is_player_collided:
			#print("step_down3")
			#collided_check_B(is_player_collided, motion, transform3d, test_motion_params, test_motion_result, step_result)
	#print("step_down out")
#
#
#func test_player_collided(test_motion_params, transform3d, motion, test_motion_result) -> bool:
	#test_motion_params.from = transform3d
	#test_motion_params.motion = motion
	#return PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
#
#
#func collided_check_A(is_player_collided, motion, transform3d, params:PhysicsTestMotionParameters3D, result:PhysicsTestMotionResult3D, step_result, step_height) -> bool:
	#transform3d.origin += motion
	#motion = -step_height
	#is_player_collided = test_player_collided(params, transform3d, motion, result)
	#if is_player_collided:
		#print("A1")
		#prints(
			#result.get_collision_normal(),
			#result.get_collision_normal().angle_to(Vector3.UP),
			#deg_to_rad(STEP_MAX_SLOPE_DEGREE))
		#if result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
			#print("A2")
			#is_step = true
			#step_result.is_step_up = true
			#step_result.diff_position = -result.get_remainder()
			#step_result.normal = result.get_collision_normal()
			#return true
	#print("Aout")
	#return false
#
#
#func collided_check_B(is_player_collided, motion, transform3d, params:PhysicsTestMotionParameters3D, result:PhysicsTestMotionResult3D, step_result) -> void:
	#transform3d.origin += motion
	#motion = -step_height_main
	#is_player_collided = test_player_collided(params, transform3d, motion, result)
	#if is_player_collided and result.get_travel().y < -STEP_DOWN_MARGIN:
		#print("B1")
		#if result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
			#print("B2")
			#is_step = true
			#step_result.diff_position = result.get_travel()
			#step_result.normal = result.get_collision_normal()
	#print("Bout")


# float fresnel(float amount, vec3 normal, vec3 view)
# {
# 	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
# }





"""

func calculate_roughness(normals: PackedVector3Array) -> float:
	var num_normals = normals.size()
	if num_normals == 0:
		return 0.0

	# 计算法线的平均值
	var sum = Vector3.ZERO
	for normal in normals:
		sum += normal
	var mean_normal = sum / num_normals

	# 计算法线与平均值的差的平方和
	var variance_sum = 0.0
	for normal in normals:
		var diff = normal - mean_normal
		variance_sum += diff.length_squared()

	# 计算标准差
	var variance = variance_sum / num_normals
	var roughness = sqrt(variance)
	return roughness


func calculate_roughness2(normals: PackedVector3Array) -> float:
	var num_normals = normals.size()
	if num_normals == 0:
		return 0.0

	# 标准化所有法线
	var normalized_normals = PackedVector3Array()
	for normal in normals:
		normalized_normals.append(normal.normalized())

	# 计算平均法线
	var sum = Vector3.ZERO
	for normal in normalized_normals:
		sum += normal
	var mean_normal = sum / num_normals
	mean_normal = mean_normal.normalized()

	# 计算每个法线与平均法线之间的角度差异
	var angle_sum = 0.0
	for normal in normalized_normals:
		var dot_product = normal.dot(mean_normal)
		var angle = acos(clamp(dot_product, -1.0, 1.0))
		angle_sum += angle

	# 计算平均角度差异
	var average_angle = angle_sum / num_normals

	# 标准化粗糙度
	var roughness = average_angle / PI  # 标准化到 [0, 1] 范围
	return roughness

func calculate_roughness3(normals: PackedVector3Array, vertices: PackedVector3Array, indices: PackedInt32Array) -> float:
	var num_normals = normals.size()
	if num_normals == 0:
		return 0.0
	# 标准化所有法线
	var normalized_normals = PackedVector3Array()
	for normal in normals:
		normalized_normals.append(normal.normalized())
	# 计算平均法线
	var sum = Vector3.ZERO
	for normal in normalized_normals:
		sum += normal
	var mean_normal = sum / num_normals
	mean_normal = mean_normal.normalized()

	# 计算每个法线与平均法线之间的角度差异，并考虑多边形面积加权
	var angle_sum = 0.0
	var total_area = 0.0
	for i in range(0, indices.size(), 3):
		var v1 = vertices[indices[i]]
		var v2 = vertices[indices[i + 1]]
		var v3 = vertices[indices[i + 2]]
		# 计算三角形面积
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var cross_product = edge1.cross(edge2)
		var triangle_area = cross_product.length() / 2.0
		# 计算每个法线与平均法线之间的角度差异
		var normal = normalized_normals[i % 3]
		var dot_product = normal.dot(mean_normal)
		var angle = acos(clamp(dot_product, -1.0, 1.0))
		# 加权角度差异
		angle_sum += angle * triangle_area
		total_area += triangle_area

	# 计算加权平均角度差异
	var weighted_average_angle = angle_sum / total_area
	# 标准化粗糙度
	var roughness = weighted_average_angle / PI  # 标准化到 [0, 1] 范围
	return roughness


这是修改calculate_roughness函数三次的测试数据

1次
5号四棱锥
Roughness: 0.96715148818681
4号正方体
Roughness: 0.99999997019768
6号球体
Roughness: 0.99995490847416

2次
5号四棱锥
Roughness: 0.39841084516579
4号正方体
Roughness: 0.49999571225485
6号球体
Roughness: 0.49627127545809

3次
5号四棱锥
Roughness: 0.41969224578033
4号正方体
Roughness: 0.89182114849173
6号球体
Roughness: 0.50028812448435


"""



		#var probe_pos: Vector3 = Vector3.ZERO
		#var attempts = 0
		#while attempts < attempts_time:  # 增加尝试次数以确保找到合适的点
			#probe_pos = random_pos_in_aabb(aabb)
			#if is_point_inside_mesh(probe_pos, _mesh):
				#break
			#attempts += 1
		#if attempts >= attempts_time:
			#print("Failed to find a valid probe position after %s attempts." %attempts_time)
			#continue

	#var attempts = 0
	#while attempts < attempts_time:  # 增加尝试次数以确保找到合适的点
		#for i in range(probe_number):
			#var probe_pos = probes[i]
			#randomize()
			#if not is_point_inside_mesh(probe_pos, _mesh):
				#probe_pos = random_pos_in_aabb(aabb)
		#attempts += 1
	#if attempts >= attempts_time:
		#print("Failed to find a valid probe position after %s attempts." %attempts_time)


# # 计算表面积
# func calculate_surface_area() -> float:
# 	# 获取网格的顶点和索引
# 	var mesh_surface = mesh.surface_get_arrays(0)
# 	var vertices = mesh_surface[Mesh.ARRAY_VERTEX] as PackedVector3Array
# 	var indices = mesh_surface[Mesh.ARRAY_INDEX] as PackedInt32Array

# 	# 计算网格的包围盒
# 	var aabb: AABB = mesh.get_aabb()

# 	# 计算网格的总面积
# 	var total_area = 0.0
# 	for i in range(0, indices.size(), 3):
# 		var v1 = vertices[indices[i]]
# 		var v2 = vertices[indices[i + 1]]
# 		var v3 = vertices[indices[i + 2]]
# 		var edge1 = v2 - v1
# 		var edge2 = v3 - v1
# 		var cross_product = edge1.cross(edge2)
# 		var triangle_area = cross_product.length() / 2.0
# 		total_area += triangle_area


	## 提前计算每个三角形的面积并存储到数组中
	#var triangle_areas = []
	#for i in range(0, indices.size(), 3):
		#var v1 = vertices[indices[i]]
		#var v2 = vertices[indices[i + 1]]
		#var v3 = vertices[indices[i + 2]]
		#var edge1 = v2 - v1
		#var edge2 = v3 - v1
		#var cross_product = edge1.cross(edge2)
		#var triangle_area = cross_product.length() / 2.0
		#triangle_areas.append(triangle_area)

				#mesh_instance_3d.global_position.x = global_position.x
				#mesh_instance_3d.global_position.z = global_position.z
				#mesh_instance_3d.global_position.y = Global.exponential_decay(mesh_instance_3d.global_position.y, global_position.y, delta)
				#mesh_instance_3d.global_position = lerp(global_position, mesh_instance_3d.global_position, high_diff_0_1)
				#mesh_instance_3d.global_rotation = Global.exponential_decay_vec3(mesh_instance_3d.global_rotation, global_rotation, delta)
				#mesh_instance_3d.global_rotation = lerp(global_rotation, mesh_instance_3d.global_rotation, high_diff_0_1)
				#var current_error = mesh_instance_3d.global_position - global_position
				#var derivative: Vector3 = (current_error - last_error) / delta # 微分项是误差变化率
				#derivative.x *= 0.1
				#derivative.z *= 0.1
				#derivative = lerp(Vector3.ZERO, derivative, high_diff_0_1)
				#_parent_rigid_body.apply_central_force(Kd * derivative)
				#last_error = current_error # 更新上一个误差为当前误差，用于下次计算


# 圆形网格的纯线顶点绘制
	# # 确定扇形的起点和终点
	# var pointA = center # 圆心
	# var pointB = center + Vector3(radius * cos(start_angle), 0, radius * sin(start_angle)) # 扇形起点
	# var pointC = center + Vector3(radius * cos(end_angle), 0, radius * sin(end_angle)) # 扇形终点
	## 绘制扇形的边界
	#draw_line(pointA, pointB, color) # 绘制圆心到起点的线
	#draw_line(pointA, pointC, color) # 绘制起点到终点的线

	## 计算细分数
	#var num_segments = max(int(angle_span / (PI / 18)), 1)
	#var angle_increment = angle_span / num_segments # 每段的角度增量
	## 绘制扇形的封闭边
	#var previous_point = center
	#for i in range(num_segments + 1):
		#var angle = start_angle + angle_increment * i # 计算当前角度
		#var curve_point = center + Vector3(radius * cos(angle), 0, radius * sin(angle)) # 计算每个点
		#if i > 0: # 绘制线条只在第二个点及之后
			#draw_line(previous_point, curve_point, color) # 绘制当前点与上一个点之间的线
		#previous_point = curve_point # 更新上一个点




"""
func save_exported_properties() -> void:
	var properties: Dictionary = {
		"velocity": velocity,
		"acceleration": acceleration,
		"center_position": center_position,
		"fire_period": fire_period,
		"fire_count": fire_count,
		"interpolate_position": interpolate_position,
		"start_fire_once": start_fire_once,
		"reset_mode": reset_mode,
		"reset_time": reset_time,
		"reset_count": reset_count,
		"disk_count": disk_count,
		"disk_angle": disk_angle,
		"disk_range": disk_range,
		"disk_radius": disk_radius,
		"stripe_count": stripe_count,
		"stripe_angle": stripe_angle,
		"stripe_range": stripe_range,
		"stripe_radius": stripe_radius,
		"ues_spherical": ues_spherical,
		"spherical_count": spherical_count,
		"ratio": ratio,
		"bullet_scene": bullet_scene,
		"bullet_mass": bullet_mass,
		"max_bullet": max_bullet,
		"bullet_lifetime": bullet_lifetime,
		"bullet_collision_enabled": bullet_collision_enabled,
		"exceeding_the_cap_mode": exceeding_the_cap_mode,
		"bullet_speed": bullet_speed,
		"bullet_acceleration": bullet_acceleration,
		"bullet_rotation": bullet_rotation,
		"bullet_color": bullet_color,
		"bullet_scale": bullet_scale,
		"bullet_blend_mode": bullet_blend_mode,
		"spawn_effect": spawn_effect,
		"destroy_effect": destroy_effect,
		"trail_effect": trail_effect,
		"disk_debug_display": disk_debug_display,
		"stripe_debug_display": stripe_debug_display,
		"display_radius": display_radius,
	}
	reset_data = properties.duplicate() # 保存当前属性值


func load_exported_properties() -> void:
	if reset_data == null:
		return
	velocity = reset_data["velocity"]
	acceleration = reset_data["acceleration"]
	center_position = reset_data["center_position"]
	fire_period = reset_data["fire_period"]
	fire_count = reset_data["fire_count"]
	interpolate_position = reset_data["interpolate_position"]
	start_fire_once = reset_data["start_fire_once"]
	reset_mode = reset_data["reset_mode"]
	reset_time = reset_data["reset_time"]
	reset_count = reset_data["reset_count"]
	disk_count = reset_data["disk_count"]
	disk_angle = reset_data["disk_angle"]
	disk_range = reset_data["disk_range"]
	disk_radius = reset_data["disk_radius"]
	stripe_count = reset_data["stripe_count"]
	stripe_angle = reset_data["stripe_angle"]
	stripe_range = reset_data["stripe_range"]
	stripe_radius = reset_data["stripe_radius"]
	ues_spherical = reset_data["ues_spherical"]
	spherical_count = reset_data["spherical_count"]
	ratio = reset_data["ratio"]
	bullet_scene = reset_data["bullet_scene"]
	bullet_mass = reset_data["bullet_mass"]
	max_bullet = reset_data["max_bullet"]
	bullet_lifetime = reset_data["bullet_lifetime"]
	bullet_collision_enabled = reset_data["bullet_collision_enabled"]
	exceeding_the_cap_mode = reset_data["exceeding_the_cap_mode"]
	bullet_speed = reset_data["bullet_speed"]
	bullet_acceleration = reset_data["bullet_acceleration"]
	bullet_rotation = reset_data["bullet_rotation"]
	bullet_color = reset_data["bullet_color"]
	bullet_scale = reset_data["bullet_scale"]
	bullet_blend_mode = reset_data["bullet_blend_mode"]
	spawn_effect = reset_data["spawn_effect"]
	destroy_effect = reset_data["destroy_effect"]
	trail_effect = reset_data["trail_effect"]
	disk_debug_display = reset_data["disk_debug_display"]
	stripe_debug_display = reset_data["stripe_debug_display"]
	display_radius = reset_data["display_radius"]



# var bullet_settings: Dictionary = {
# 	"ID": 1,
# 	# "层ID": 1,
# 	"binding": false,
# 	"position": Vector3.ZERO,
# 	"launch_rotation": Vector3.ZERO,
# 	"speed": 8,
# 	"lifetime": 10.0, ## 新增：弹幕生存时间（秒）
# 	"type": "normal",
# }
