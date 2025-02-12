class_name SaveLoadManager
extends Node

#@export var player : Node2D
const SAVE_PATH = "user://"

static func save_node(_node: Node, _node_name: String, save_path: String) -> void:
	var data: Resource = SceneData.new()
	
	var _node_scene = PackedScene.new()
	if _node_scene.pack(_node) != OK:
		print("Error: Failed to PACK the node into a scene.")
		return
	
	data.scenes_dictionary[_node_name] = _node_scene
	
	var result = ResourceSaver.save(data, save_path)
	if result != OK:
		print("Error: Failed to SAVE the resource to %s." % save_path)
	else:
		print("Node saved successfully!")


static func load_node(_node_name: String, save_path: String) -> PackedScene:
	var data: SceneData = ResourceLoader.load(save_path) as SceneData
	if data == null:
		print("Error: Failed to LOAD the resource from %s." % save_path)
		return null
	
	if not data.scenes_dictionary.has(_node_name):
		print("Error: The node %s does not exist in the loaded data." % _node_name)
		return null
	
	print("Node loaded successfully!")
	return data.scenes_dictionary[_node_name]
