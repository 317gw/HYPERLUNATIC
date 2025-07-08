@tool
class_name Mesh3DBatchCreator
extends Node

enum SaveMode {MESH_INSTANCE_3D, STATIC_BODY_3D, MESH_RESOURCE}

@export var go_create: bool = false:
	set(v):
		create()
@export var go_texture_test: bool = false:
	set(v):
		texture_test()

@export var mesh_instance_3d_group: Node

@export var save_path: String
@export var save_mode: SaveMode = SaveMode.MESH_INSTANCE_3D
@export var transform_normalized: bool = true
@export var cover_duplicate_items: bool = false ## 覆盖或者命名后缀.001
@export var create_exhibition_scene: bool = true
@export var exhibition_scene_name: String

@export_group("Collision")
@export var  physics_material_override: PhysicsMaterial
@export_flags_3d_physics var collision_layer: int = 1
@export_flags_3d_physics var collision_mask: int = 1

@export_group("Name")
@export var find_name: String ## lower
@export var replace_name: String ## lower
@export var case_sensitive: bool = false ## 区分大小写
@export var custom_prefix: String
@export var custom_suffix: String
@export var suffix_of_save_mode: bool = false

@export_category("Material")
@export var textures_path: String
@export var default_standard_material_3d: StandardMaterial3D ## 推荐启用本地化到场景

var exhibition_scene: Node3D

var albedo_list: Array[String]
var roughness_list: Array[String]
var metallic_list: Array[String]
var normal_list: Array[String]

@onready var static_body_temp: Node = $StaticBodyTemp
@onready var exhibition_temp: Node = $ExhibitionTemp


func _ready() -> void:
	exhibition_scene = null
	albedo_list.clear()
	roughness_list.clear()
	metallic_list.clear()
	normal_list.clear()

	if static_body_temp.get_child_count() > 0:
		for child in static_body_temp.get_children():
			child.queue_free()


func create() -> void:
	#print("\n【Mesh3DBatchCreator】go create")
	print("")
	# 检查
	if not mesh_instance_3d_group:
		push_error("未设置MeshInstance3D组")
		return

	if not save_path or not save_path.is_absolute_path():
		push_error('保存路径无效，必须是绝对路径，包括以 "res://"、"user://"、"C:\\"、"/" 等开头的路径。')
		return

	if save_mode == SaveMode.MESH_INSTANCE_3D or save_mode == SaveMode.STATIC_BODY_3D:
		if textures_path:
			# 处理纹理
			if not _handle_textures():
				push_error("纹理路径不存在")
				return
		else:
			push_error("未设置纹理路径")

		if not default_standard_material_3d:
			push_error("缺少默认StandardMaterial3D材质")
			return

	# 制作展览场景
	if create_exhibition_scene:
		exhibition_scene = Node3D.new()
		exhibition_temp.add_child(exhibition_scene, true)
		exhibition_scene.owner = exhibition_temp
		exhibition_scene.name = exhibition_scene_name.to_pascal_case() if exhibition_scene_name else"ExhibitionMeshs"

	# 循环
	var meshs: Array[Node] = mesh_instance_3d_group.get_children(true)
	for _mesh in meshs:
		if _mesh is not MeshInstance3D:
			continue
		_create_single(_mesh)

	# 制作展览场景
	if create_exhibition_scene:
		exhibition_scene.owner = null
		var scene:= PackedScene.new()
		var result = scene.pack(exhibition_scene)
		var es_name: String = exhibition_scene_name.to_snake_case() if exhibition_scene_name else "exhibition_meshs"
		var es_save_path: String = configuration_path(save_path, es_name)
		if result == OK:
			var error = ResourceSaver.save(scene, es_save_path + ".tscn")
			if error != OK:
				push_error(es_name, " 将e场景保存到磁盘时出错。")


func _create_single(_mesh: Node3D) -> void:
	# 配置场景
	var _mesh_packed: Node3D
	var _mesh_name:= _mesh.name.to_snake_case()
	match save_mode:
		SaveMode.MESH_INSTANCE_3D:
			_mesh_packed = _mesh.duplicate()
			_mesh_packed.material_override = _set_material(_mesh_name)
			if transform_normalized:
				_mesh_packed.transform = Transform3D.IDENTITY
			_mesh_packed.owner = null

		SaveMode.STATIC_BODY_3D:
			var static_body:= StaticBody3D.new()
			static_body_temp.add_child(static_body)
			static_body.physics_material_override = physics_material_override
			static_body.collision_layer = collision_layer
			static_body.collision_mask = collision_mask

			var mesh_inst:= _mesh.duplicate()
			static_body.add_child(mesh_inst)
			mesh_inst.name = "MeshInstance3D"
			mesh_inst.owner = static_body
			mesh_inst.material_override = _set_material(_mesh_name)

			# 设置碰撞
			var collision_shape:= CollisionShape3D.new()
			static_body.add_child(collision_shape, true)
			collision_shape.owner = static_body
			# 设置形状
			var cps3d:= ConcavePolygonShape3D.new()
			var __mesh: Mesh = _mesh.mesh
			cps3d.set_faces(__mesh.get_faces())
			collision_shape.shape = cps3d

			_mesh_packed = static_body
			# 归一化
			if transform_normalized:
				mesh_inst.transform = Transform3D.IDENTITY
				static_body.transform = Transform3D.IDENTITY
				collision_shape.transform = Transform3D.IDENTITY
			_mesh_packed.owner = null

			if static_body_temp.get_child_count() > 0:
				for child in static_body_temp.get_children():
					child.queue_free()

	# 配置名称
	# 查找替换
	if find_name != "" and replace_name != "":
		if case_sensitive:
			_mesh_name = _mesh_name.replace(find_name, replace_name)
		else:
			_mesh_name = _mesh_name.replacen(find_name, replace_name)

	# 前缀后缀
	_mesh_name = custom_prefix + _mesh_name
	_mesh_name += custom_suffix
	# 保存模式后缀
	if suffix_of_save_mode:
		match save_mode:
			SaveMode.MESH_INSTANCE_3D:
				_mesh_name += "_instance"
			SaveMode.STATIC_BODY_3D:
				_mesh_name += "_static_body"
			SaveMode.MESH_RESOURCE:
				_mesh_name += "_resource"

	# 审查
	var _name: StringName
	for i in _mesh_name:
		if not i in '.:\"@/\\%':
			_name += i
	_mesh_packed.name = _name

	# 配置路径
	var _save_path: String = configuration_path(save_path, _mesh_name)

# FileAccess.file_exists
# ResourceLoader.exists

	# 开始保存
	if save_mode == SaveMode.MESH_RESOURCE:
		var mesh_resource:Mesh = _mesh.mesh.duplicate()
		var error = ResourceSaver.save(mesh_resource, _save_path + ".tres")
		if error != OK:
			push_error(_name, " 将网格资源保存到磁盘时出错。")
	else:
		var scene:= PackedScene.new()
		var result = scene.pack(_mesh_packed)
		if result == OK:
			var error = ResourceSaver.save(scene, _save_path + ".tscn")
			if error == OK:
				# 制作展览场景
				if create_exhibition_scene:
					var _scene = load(_save_path + ".tscn").instantiate() as Node3D
					exhibition_scene.add_child(_scene)
					_scene.owner = exhibition_scene
					_scene.global_transform = _mesh.global_transform
			else:
				push_error(_name, " 将场景保存到磁盘时出错。")


func configuration_path(_path: String, _name: String) -> String:
	var return_path: String
	if cover_duplicate_items:
		return_path = _path.path_join(_name)
	else: # 重名处理
		var counter := 0
		while true:
			var suffix = "" if counter == 0 else "_" + str(counter).pad_zeros(3)
			return_path = _path.path_join(_name + suffix)
			print(return_path)
			if save_mode == SaveMode.MESH_RESOURCE:
				if not ResourceLoader.exists(return_path + ".tres"):
					break
			else:
				if not ResourceLoader.exists(return_path + ".tscn"):
					break
			counter += 1
	return return_path


func texture_test() -> void:
	if not textures_path:
		push_error("未设置纹理路径")
		return

	if not _handle_textures():
		push_error("纹理路径不存在")
		return

	var textures_dir:= DirAccess.get_files_at(textures_path)
	prints("\nDirAccess.get_files_at ", textures_dir)
	var re_type:= ResourceLoader.get_recognized_extensions_for_type(textures_path)
	prints("\nResourceLoader.get_recognized_extensions_for_type ", re_type)
	prints("\nalbedo_list ", albedo_list)
	prints("\nroughness_list ", roughness_list)
	prints("\nmetallic_list ", metallic_list)
	prints("\nnormal_list ", normal_list)


func _handle_textures() -> bool:
	albedo_list.clear()
	roughness_list.clear()
	metallic_list.clear()
	normal_list.clear()

	var ok:= DirAccess.dir_exists_absolute(textures_path)
	if not ok:
		return false

	var textures_dir:= DirAccess.get_files_at(textures_path)
	for file in textures_dir:
		if ".import" in file:
			continue
		var file_lower = file.to_lower()

		if "albedo" in file_lower or "diffuse" in file_lower:
			albedo_list.append(file)
		elif "roughness" in file_lower:
			roughness_list.append(file)
		elif "metallic" in file_lower:
			metallic_list.append(file)
		elif "normal" in file_lower:
			normal_list.append(file)
	return true


## 匹配贴图
func _set_material(mesh_name: StringName) -> StandardMaterial3D:
	var result := default_standard_material_3d.duplicate()
	## 匹配基础色贴图
	#for _name in albedo_list:
		#if mesh_name in _name.to_snake_case().replace(".", "_"):
			#result.albedo_texture = _load_texture(_name)
	## 匹配粗糙度贴图
	#for _name in roughness_list:
		#if mesh_name in _name.to_snake_case().replace(".", "_"):
			#result.roughness_texture = _load_texture(_name)
	## 匹配金属度贴图
	#for _name in metallic_list:
		#if mesh_name in _name.to_snake_case().replace(".", "_"):
			#result.metallic_texture = _load_texture(_name)
	## 匹配法线贴图
	#if result.normal_enabled:
		#for _name in normal_list:
			#if mesh_name in _name.to_snake_case().replace(".", "_"):
				#result.normal_texture = _load_texture(_name)

	var _return_name_albedo: String = _find_most_similar(mesh_name, albedo_list)
	var _return_name_roughness: String = _find_most_similar(mesh_name, roughness_list)
	var _return_name_metallic: String = _find_most_similar(mesh_name, metallic_list)
	var _return_name_normal: String = _find_most_similar(mesh_name, normal_list)

	result.albedo_texture = _load_texture(_return_name_albedo)
	result.roughness_texture = _load_texture(_return_name_roughness)
	result.metallic_texture = _load_texture(_return_name_metallic)
	if result.normal_enabled:
		result.normal_texture = _load_texture(_return_name_normal)

	albedo_list.erase(_return_name_albedo)
	roughness_list.erase(_return_name_roughness)
	metallic_list.erase(_return_name_metallic)
	normal_list.erase(_return_name_normal)

	return result


func _find_most_similar(target: String, name_list: Array) -> String:
	if name_list.is_empty():
		return ""

	var _candidates: Array = []
	for _name in name_list:
		if target in _name.to_snake_case().replace(".", "_"):
			_candidates.append(_name)
	return HL.find_most_similar(target, _candidates)


func _load_texture(file: String) -> Texture2D:
	return ResourceLoader.load(textures_path.path_join(file), "Texture2D")
