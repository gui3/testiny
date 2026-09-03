@tool
extends MarginContainer

var tree: Tree

var current_phases: Array[___Testiny_Phase]

func _ready() -> void:
	tree = $Layout/View/HSplit/TestTree/Tree
	tree.columns = 3
	#tree.set_column_expand(0, true)
	#tree.set_column_expand_ratio(0, 60) # description
	#tree.set_column_expand(1, true) 
	#tree.set_column_expand_ratio(1, 20) # status icon
	#tree.set_column_expand(2, true)
	#tree.set_column_expand_ratio(2, 20) # run button
	_load()

func _load() -> void:
	print("[__APP_NAME__] reloading suites...")
	var session := ___Testiny_Session.new()
	await session._load()
	current_phases = session.phases
	print_debug(current_phases.size())
	for phase in current_phases:
		await phase._load()
	_refresh_tree()

func _refresh_tree() -> void:
	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true
	for phase in current_phases:
		if phase is ___Testiny_Suite:
			var item: TreeItem = tree.create_item(root)
			item.set_text(0, phase.description)
			item.set_text(2, "Run Suite")
			item.set_metadata(0, phase)
			for case in phase.cases:
				var sub_item: TreeItem = item.create_child()
				sub_item.set_text(0, case.description)
				sub_item.set_metadata(0, case)
				sub_item.set_text(2, "Run Case")

func _on_reload_button_pressed() -> void:
	await _load()
