@tool
extends EditorPlugin

var run_button: Button

func _enter_tree() -> void:
	# 1. Création du bouton d'interface
	run_button = Button.new()
	run_button.text = "▶ Run Testiny"
	run_button.tooltip_text = "Execute active test file (Ctrl + Maj + T)"
	run_button.pressed.connect(_run_active_test)
	
	# 2. Ajout du bouton dans le conteneur principal de l'éditeur de code
	add_control_to_container(CONTAINER_TOOLBAR, run_button)

func _exit_tree() -> void:
	# Nettoyage à la désactivation du plugin
	if run_button:
		remove_control_from_container(CONTAINER_TOOLBAR, run_button)
		run_button.queue_free()

## Raccourci clavier (Ctrl + Shift + T / Cmd + Shift + T)
func _unhandled_key_input(event: InputEvent) -> void:
	if not run_button or not run_button.visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var command_or_ctrl = event.ctrl_pressed or event.meta_pressed
		if command_or_ctrl and event.shift_pressed and event.keycode == KEY_T:
			_run_active_test()
			get_viewport().set_input_as_handled()

## Logique d'exécution du test actif
func _run_active_test() -> void:
	#var script_editor = get_editor_interface().get_script_editor()
	#var current_script = script_editor.get_current_script()
	#var test_instance = current_script.new()

	var tester: Testiny = Testiny.new()
	tester._run()
	
