@tool
extends RefCounted
class_name GameplayTag

## 标签名称
var name: String

## 父标签
var parent: GameplayTag

## 子标签
var children: Array[GameplayTag] = []

static func create(tag_name: String) -> GameplayTag:
	var tag := GameplayTag.new()
	tag.name = tag_name
	return tag

## 添加子标签
func add_child(child: GameplayTag) -> void:
	if not child in children:
		children.append(child)
		child.parent = self

## 移除子标签
func remove_child(child: GameplayTag) -> void:
	if child in children:
		children.erase(child)
		child.parent = null

## 获取完整路径
func get_full_path() -> String:
	if parent:
		return parent.get_full_path() + "." + name
	return name

## 获取所有子标签（递归）
func get_all_children() -> Array[GameplayTag]:
	var result: Array[GameplayTag] = []
	for child in children:
		result.append(child)
		result.append_array(child.get_all_children())
	return result

## 检查是否匹配目标标签
## exact: 是否精确匹配。如果为false，则会检查层级关系
func matches(other: GameplayTag, exact: bool = true) -> bool:
	if exact:
		return get_full_path() == other.get_full_path()
	
	# 检查是否是目标标签的父标签
	var current := other
	while current:
		if current == self:
			return true
		current = current.parent
	
	# 检查是否是目标标签的子标签
	current = self
	while current:
		if current == other:
			return true
		current = current.parent
	
	return false
