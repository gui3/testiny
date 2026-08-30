extends Node

static func open_control_in_new_window(content: Control, title: String) -> Window:
	var new_window = Window.new()
	new_window.title = title
	new_window.size = Vector2i(600, 400)
	new_window.translucent = false
	new_window.close_requested.connect(func(): new_window.queue_free())
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_window.add_child(content)
	Engine.get_main_loop().add_child(new_window)
	new_window.popup_centered()
	return new_window
