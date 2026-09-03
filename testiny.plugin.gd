@tool
extends EditorPlugin

#const AUTOLOAD_NAME = "__APP_CLASS_NAME__"
#const AUTOLOAD_PATH = "./testiny.bundle.gd"
#const Testiny = preload(AUTOLOAD_PATH)

var ui_scene: PackedScene = preload("./testiny.ui.tscn")
var ui_ref: MarginContainer

func _enter_tree() -> void:
	# add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	# quick-run button
	if ui_ref:
		remove_control_from_bottom_panel(ui_ref)
		ui_ref.queue_free()
	ui_ref = ui_scene.instantiate()
	add_control_to_bottom_panel(ui_ref, "Testiny")
	print("[__APP_NAME__] plugin activated")


func _exit_tree() -> void:
	# remove_autoload_singleton(AUTOLOAD_NAME)
	if ui_ref:
		remove_control_from_bottom_panel(ui_ref)
		ui_ref.queue_free()
	print("[__APP_NAME__] plugin de-activated")
