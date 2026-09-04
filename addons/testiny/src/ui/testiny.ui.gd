@tool
extends MarginContainer

const Testiny = preload("../testiny.gd")

var tree: Tree

var current_phases: Array[Testiny.Phase]
var recorder := Testiny.Recorder.new()

# icons
const i_idle: Texture2D = preload("res://addons/testiny/art/Icon_IDLE_black.svg")
const i_success: Texture2D = preload("res://addons/testiny/art/Icon_SUCCESS_black.svg")
const i_waiting: Texture2D = preload("res://addons/testiny/art/Icon_WAITING_black.svg")
const i_failed: Texture2D = preload("res://addons/testiny/art/Icon_FAILED_black.svg")
const i_crashed: Texture2D = preload("res://addons/testiny/art/Icon_CRASHED_black.svg")
const i_run: Texture2D = preload("res://addons/testiny/art/Icon_RUN_black.svg")
const i_stop: Texture2D = preload("res://addons/testiny/art/Icon_STOP_black.svg")

static func get_status_icon(status: Testiny.Constant.Status) -> Texture2D:
	var category: Testiny.Constant.StatusCategory = Testiny.Constant.get_category(status)
	match category:
		Testiny.Constant.StatusCategory.CRASHED:
			return i_crashed
		Testiny.Constant.StatusCategory.FAILED:
			return i_failed
		Testiny.Constant.StatusCategory.WAITING:
			return i_waiting
		Testiny.Constant.StatusCategory.IDLE:
			return i_idle
		Testiny.Constant.StatusCategory.STOPPED:
			return i_stop
		Testiny.Constant.StatusCategory.OK:
			return i_success
	return i_idle # default (should not go there

func _ready() -> void:
	tree = $Layout/View/HSplit/TestTree/Tree
	tree.columns = 1
	reset_details()

func _load() -> Testiny.Session:
	print("[Testiny] reloading suites...")
	tree.clear()
	var session := Testiny.Session.new()
	await session._load()
	current_phases = session.phases
	print_debug(current_phases.size())
	for phase in current_phases:
		await phase._load()
	_refresh_tree()
	return session

## (async)
func _run() -> void :
	print("[Testiny UI] running all tests")
	var session: Testiny.Session = await _load()
	await session._run()

func _refresh_tree() -> void:
	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true
	for phase in current_phases:
		if phase is Testiny.Suite:
			var item: TreeItem = tree.create_item(root)
			item.set_metadata(0, phase)
			
			item.set_text(0, phase.description)
			item.set_icon_max_width(0,24)
			item.set_icon(0, i_waiting)
			
			item.add_button(0, i_run, 5, false, "run the full suite", "Run Suite")
			
			phase.status_updated.connect(func(status: Testiny.Constant.Status):
				item.set_icon(0, get_status_icon(status))
			)
			
			for case in phase.cases:
				var sub_item: TreeItem = item.create_child()
				sub_item.set_metadata(0, case)
				
				sub_item.set_icon_max_width(0,24)
				sub_item.set_icon(0, i_idle)
				sub_item.set_text(0, case.description)
				
				sub_item.add_button(0, i_run, 5, false, "run this test case", "Run Case")
				#sub_item.set_button_disabled(0, 0, true)
				
				case.status_updated.connect(func(status: Testiny.Constant.Status):
					sub_item.set_icon(0, get_status_icon(status))
				)

func show_details(phase: Testiny.Phase) -> void:
	$Layout/View/HSplit/Inspector/Title/PhaseNameLabel.text = phase.description
	# status
	$Layout/View/HSplit/Inspector/Title/StatusLabel.text = Testiny.Constant.status_string.get(
		phase.status,
		"?"
	)
	var icon = get_status_icon(phase.status)
	$Layout/View/HSplit/Inspector/Title/StatusIcon.texture = icon
	# logs
	var log_text: String = phase.recorder.get_snapshot()
	$Layout/View/HSplit/Inspector/Logs.text = log_text

func reset_details() -> void:
	$Layout/View/HSplit/Inspector/Title/PhaseNameLabel.text = "[no phase selected]"
	# status
	$Layout/View/HSplit/Inspector/Title/StatusLabel.text = "[ ]"
	$Layout/View/HSplit/Inspector/Title/StatusIcon.texture = i_idle
	$Layout/View/HSplit/Inspector/Logs.text = ""

func _on_reload_button_pressed() -> void:
	await _load()

func _on_tree_cell_selected() -> void:
	var item = tree.get_selected()
	if not item:
		return
	var phase: Testiny.Phase = item.get_metadata(0)
	show_details(phase)

func _on_run_all_button_pressed() -> void:
	_run()
