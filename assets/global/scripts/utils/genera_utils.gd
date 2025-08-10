class_name GeneralUtils
extends NAMESPACE


## 遍历queue_free子节点
static func children_queue_free(node: Node) -> void:
	if node and node.get_child_count() > 0:
		for child in node.get_children():
			child.queue_free()


## 递归查找节点下特定类型的子节点
static func find_child_node_type(node: Node, child_type: String) -> Node:
	if node.get_class() == child_type:
		return node
	for i in range(node.get_child_count()):
		var child_node = node.get_child(i)
		var result = find_child_node_type(child_node, child_type)
		if result:
			return result
	return null


## 获取两个数组的并集
static func array_union(arr1: Array, arr2: Array) -> Array:
	var result = []
	for item in arr1: # 添加第一个数组的所有元素，查重
		if not result.has(item):
			result.append(item)
	for item in arr2: # 添加第二个数组中不存在于结果中的元素
		if not result.has(item):
			result.append(item)
	return result


## 获取两个数组的交集
static func array_intersection(arr1: Array, arr2: Array) -> Array:
	var result = []
	for item in arr1: # 遍历第一个数组
		# 检查元素是否存在于第二个数组且尚未添加到结果中
		if arr2.has(item) and not result.has(item):
			result.append(item)
	return result
