class_name GridCell
extends RefCounted

var coordinates: Vector3i
var objects_by_category: Dictionary = {}

func _init(pos: Vector3i) -> void:
	coordinates = pos

# 添加对象
func add_object(obj: Node3D, category: String) -> void:
	if not objects_by_category.has(category):
		objects_by_category[category] = []

	if not objects_by_category[category].has(obj):
		objects_by_category[category].append(obj)

# 移除对象
func remove_object(obj: Node3D) -> void:
	for category in objects_by_category:
		if objects_by_category[category].has(obj):
			objects_by_category[category].erase(obj)

			# 如果类别为空，移除类别
			if objects_by_category[category].is_empty():
				objects_by_category.erase(category)
			return

# 获取对象
func get_objects(categories: Array[String] = []) -> Array[Node3D]:
	var results = []

	if categories.is_empty():
		# 返回所有对象
		for category in objects_by_category:
			results.append_array(objects_by_category[category])
	else:
		# 返回指定类别的对象
		for category in categories:
			if objects_by_category.has(category):
				results.append_array(objects_by_category[category])

	return results

# 检查是否为空
func is_empty() -> bool:
	return objects_by_category.is_empty()

# 获取对象数量
func object_count() -> int:
	var count = 0
	for category in objects_by_category:
		count += objects_by_category[category].size()
	return count
