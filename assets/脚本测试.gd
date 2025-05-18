@tool
extends Node3D

#height: float = 1.7 ## 身高
#mass: float = 60.0 ## 质量 2m->78kg  1.7m->60kg
#slow_rigid_force: float = 10.0 ## 低速移动推力
#speed_slow: float = 2.0 ## 低速移动速度
#speed_normal: float = 6.0 ## 地面普通移动速度
#speed_max: float = 10.0 ## 地面奔跑最大速度
#acc_normal_time: float = 0.1 ## 地面普通移动加速度时间 ACC -> Acceleration
#acc_max_time: float = 6.0 ## 地面奔跑加速度时间
#jump_height: float = 5.0 ## 普通跳跃高度
#jump_time: float = 1.5 ## 普通跳跃时间
#mouse_wheel_jump_height: float = 1.7 ## 滚轮跳高度
#jump_distance_min: float = 10.0 ## 最小跳跃距离
#jump_distance_max: float = 16.5 ## 跳跃距离
#air_speed_max: float = 12.0 ## 空中移动最大速度





func _ready() -> void:
	#for i in range(100):
		#var _in: int = randi_range(0, 255)
		#prints(_in, _in & 3, _in % 4, _in/4.0)
	#prints(1e-2, 1e05)

	#var vvvvvv = Vector3(3, 5, 8)
	#prints(vvvvvv * vvvvvv, vvvvvv.normalized() * vvvvvv.length()**2)
	#prints(AC)

	#var aaaa = TranslationServer.get_translation_object("")
	#print(aaaa)

	var aaaa


	#aaaa = HL.next_power_of_two(2001)
	aaaa = HL.nearest_power_of_two(5)

	prints(-4 ** 0.5, HL.power(-4, 0.5))
	prints(0 ** 0, pow(0, 0), HL.power(0, 0))

#var ttt = 0
#func _input(event: InputEvent) -> void:
	#if event.is_action("mouse_wheel_down") or event.is_action("move_forward"):
		#ttt += 1
		#prints("_input", get_tree().get_frame(), ttt)
#
#func _physics_process(delta: float) -> void:
	#ttt += 2
	#prints("_physics_process", get_tree().get_frame(), ttt)


const AC: float = 6.02e23 # Avogado Constant 阿伏伽德罗常量（约6.02×10^23）个微粒
#const Water = Particle.new()

class Particle: # 单个粒子
	var mass: float # 质量 > 0
	var appearance_volume: float # 含孔隙 外观体积 > 0
	var density: float # 密度 > 0
	var shape_factor: float # 形状因子 [0, 1] 0不定形 1球
	#var base_poriness: float # 基本孔隙率 [0, 1]
	var base_dense_degree: float # 基本密实度 [0, 1]
	var multi: float # 计数时的倍率 用于协调不同粒子的差距 > 0
	var use_molar: bool # mol

	func _init(mass: float, appearance_volume: float, shape_factor: float, base_dense_degree: float, multi: float = 1.0, use_molar: bool = false) -> void:
		self.mass = max(mass, 0.0)
		self.appearance_volume = max(appearance_volume, 1e-6)
		self.density = max(mass/appearance_volume, 0.0)
		self.shape_factor = clampf(shape_factor, 0.0, 1.0)
		self.base_dense_degree = clampf(base_dense_degree, 0.0, 1.0)
		self.multi = max(multi, 0.0)
		self.use_molar = use_molar


class Substance: # pure substance 一堆的纯净物
	var particle: Particle # 依据的粒子
	var quantity: float # 粒子数量
	var mass: float # 质量 > 0
	var appearance_volume: float # 含孔隙 外观体积 > 0
	var density: float # 密度 > 0
	#var poriness: float # 孔隙率 [0, 1]
	var dense_degree: float # 密实度 [0, 1]
	var mole: float

	func _init(particle: Particle, volume: float) -> void:
		self.particle = particle
		self.appearance_volume = volume
		self.dense_degree = particle.base_dense_degree * lerpf(0.07, 0.74, particle.shape_factor)
		self.quantity = (volume * self.dense_degree) / (particle.appearance_volume * particle.base_dense_degree)
		self.mass = particle.mass * self.quantity
		self.density = self.mass / volume

		#if particle.use_molar:
		#else:
		self.mole = self.quantity / AC if particle.use_molar else 0.0


class LiquidProperty: # 液
	var density: float # 外观体积 质量密度 > 0
	var dense_degree: float # 密实度 [0, 1]

	func _init(density: float, dense_degree: float) -> void:
		self.density = density
		self.dense_degree = dense_degree


class Liquid: # pure 一堆纯净液体
	var mass: float # 质量 > 0
	var appearance_volume: float # 含孔隙 外观体积 > 0
	var density: float # 密度 > 0
	var dense_degree: float # 密实度 [0, 1]

	func _init(mass: float, appearance_volume: float, dense_degree: float) -> void:
		self.mass = mass
		self.appearance_volume = appearance_volume
		self.density = mass / appearance_volume
		self.dense_degree = clampf(dense_degree, 0.0, 1.0)


class Mixture: # 混合物
	var substance_element: Array[Substance]
	var liquid_element: Array[Liquid]

	func add_substance(sub: Substance) -> void:
		substance_element.append(sub)

	func calculate_total_density() -> float:
		var total_mass = 0.0
		var total_volume = 0.0
		for s in substance_element:
			total_mass += s.mass
			total_volume += s.appearance_volume
		for l in liquid_element:
			total_mass += l.mass
			total_volume += l.appearance_volume
		return total_mass / total_volume if total_volume > 0 else 0.0






pass
