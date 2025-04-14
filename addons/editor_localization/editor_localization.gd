#@tool
extends EditorPlugin

var translation: Translation

func _enter_tree():
	translation = Translation.new()
	translation.locale = "zh_CN"  # 目标语言

	for key in translations:
		translation.add_message(key, translations[key])

	#TranslationServer.add_translation(translation)

func _exit_tree():
	pass  # 清理逻辑


var translations:Dictionary = {
	"": 1,



}
