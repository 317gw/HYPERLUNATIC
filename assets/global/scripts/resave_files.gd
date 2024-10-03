# script goes through project resaving files in editor resolving invalid UID issues
# open script in editor and run with right-click
@tool
extends EditorScript

var files: Array[String]

func _run() -> void:
	files = []

	add_files("res://")

	for file in files:
		print("fix_uid: ",file)
		var res = load(file)
		ResourceSaver.save(res)

func add_files(dir: String):
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() == "tscn" or file.get_extension() == "tres" or file.get_extension() == "material":
			files.append(dir.path_join(file))

	for dr in DirAccess.get_directories_at(dir):
		add_files(dir.path_join(dr))
