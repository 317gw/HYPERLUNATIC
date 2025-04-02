extends Node2D

## 角色的标签容器
var tag_container : GameplayTagContainer:
	get:
		if not tag_container:
			tag_container = GameplayTagContainer.new()
		return tag_container

## 添加标签
func add_tag(tag: String) -> void:
	tag_container.add_tag(tag)

## 移除标签
func remove_tag(tag: String) -> void:
	tag_container.remove_tag(tag)

## 检查是否有标签
func has_tag(tag: String, exact: bool = true) -> bool:
	return tag_container.has_tag(tag, exact)

## 获取所有标签
func get_tags() -> Array:
	return tag_container.get_tags()