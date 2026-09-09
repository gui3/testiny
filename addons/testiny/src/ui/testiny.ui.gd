@tool
extends MarginContainer

const Testiny = preload("../testiny.gd")

var tree: Tree
var session: Testiny.Session

var current_phases: Array[Testiny.Suite]
var recorder := Testiny.Recorder.new()
var timer: Timer

# icons
const i_idle: Texture2D = preload("res://addons/testiny/art/Icon_IDLE_black.svg")
const i_success: Texture2D = preload("res://addons/testiny/art/Icon_SUCCESS_black.svg")
const i_waiting: Texture2D = preload("res://addons/testiny/art/Icon_WAITING_black.svg")
const i_failed: Texture2D = preload("res://addons/testiny/art/Icon_FAILED_black.svg")
const i_warning: Texture2D = preload("res://addons/testiny/art/Icon_WARNING_black.svg")
const i_crash: Texture2D = preload("res://addons/testiny/art/Icon_CRASH_black.svg")
const i_run: Texture2D = preload("res://addons/testiny/art/Icon_RUN_black.svg")
const i_stop: Texture2D = preload("res://addons/testiny/art/Icon_STOP_black.svg")
const i_expired: Texture2D = preload("res://addons/testiny/art/Icon_EXPIRED_black.svg")

static func get_status_icon(status: Testiny.Constant.Status) -> Texture2D:
	var category: Testiny.Constant.StatusCategory = Testiny.Constant.get_category(status)
	match category:
		Testiny.Constant.StatusCategory.CRASHED:
			return i_crash
		Testiny.Constant.StatusCategory.EXPIRED:
			return i_expired
		Testiny.Constant.StatusCategory.FAILED:
			return i_failed
		Testiny.Constant.StatusCategory.WARNING:
			return i_warning
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
	$Layout/ToolBox/TitleButton.text = $Layout/ToolBox/TitleButton.text.replace(
		"__APP_VERSION__",
		Testiny.AppInfo.VERSION
	)
	tree = $Layout/View/HSplit/TestTree/Tree
	tree.columns = 1
	reset_details()
	_on_tab_bar_tab_changed(0)
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = false
	timer.timeout.connect(func():
		if session and not session.is_done:
			refresh_details()
	)
	timer.start(0.5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		timer.stop()

func _load() -> Testiny.Session:
	print("[Testiny] reloading suites...")
	session = await reset_session()
	session._load()
	if not session.status == Testiny.Constant.Status.READY:
		await session.loaded
	current_phases = session.suites
	_refresh_tree()
	return session

func reset_session() -> Testiny.Session:
	if session:
		await session._cancel()
		remove_child(session)
		session = null
	session = Testiny.Session.new()
	session.config.is_all_at_once = $Layout/ToolBox/IsAsyncButton.button_pressed
	session.config.is_graphics_on = $Layout/ToolBox/IsGraphicButton.button_pressed
	session.config.timeout = $Layout/ToolBox/VBoxContainer/TimeoutInput.value
	session.config.filter = $Layout/ToolBox/FilterSection/LineEdit.text
	var root_path: String = $Layout/View/HSplit/Config/ScrollContainer/VBox/RootGroup/TestRootEdit.text
	if root_path.length() < 1:
		root_path = "res://"
	session.config.test_suite_root_path = root_path
	var suite_match: String = $Layout/View/HSplit/Config/ScrollContainer/VBox/SuiteMatchGroup/SuiteMatchEdit.text
	if suite_match.length() < 1:
		suite_match = ".test.gd"
	session.config.test_suite_matches = suite_match
	var excludes: String = $Layout/View/HSplit/Config/ScrollContainer/VBox/SuiteExcludeGroup/SuiteExcludeEdit.text
	session.config.test_suite_excludes = excludes
	var case_match: String = $Layout/View/HSplit/Config/ScrollContainer/VBox/CaseMatchGroup/CaseMatchEdit.text
	if case_match.length() < 1:
		case_match = "it_*"
	session.config.method_is_test_match = case_match
	session.count_updated.connect(update_progress.call_deferred)
	add_child(session)
	return session

func update_progress(count: int, total: int, details: Dictionary[Testiny.Constant.Status, int]):
	print("progress %s / %s" % [count, total])
	if total > 0:
		$Layout/StatusBar/ProgressBar.value = (count * 100) / (total)
	for child in $Layout/StatusBar/StatusCountSection.get_children():
		$Layout/StatusBar/StatusCountSection.remove_child(child)
	
	# total runned
	var icon = TextureRect.new()
	icon.texture = i_run
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	$Layout/StatusBar/StatusCountSection.add_child(icon)
	var label = Label.new()
	label.text = "%s" % total
	$Layout/StatusBar/StatusCountSection.add_child(label)
	# each ended
	for status in details:
		icon = TextureRect.new()
		icon.texture = get_status_icon(status)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		$Layout/StatusBar/StatusCountSection.add_child(icon)
		label = Label.new()
		label.text = "%s" % details.get(status)
		$Layout/StatusBar/StatusCountSection.add_child(label)

## (async)
func _run() -> void :
	print("[Testiny UI] running all tests")
	session = await _load()
	session._run()
	if not session.is_done:
		await session.ended

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
			item.set_icon(0, get_status_icon(phase.status))
			
			# button id 0 = run
			item.add_button(0, i_run, 0, false, "run the full suite", "Run Suite")
			
			phase.status_updated.connect(func(status: Testiny.Constant.Status):
				item.set_icon(0, get_status_icon(status))
			)
			
			for case in phase.cases:
				var sub_item: TreeItem = item.create_child()
				sub_item.set_metadata(0, case)
				
				sub_item.set_icon_max_width(0,24)
				sub_item.set_icon(0, get_status_icon(phase.status))
				sub_item.set_text(0, case.description)
				
				# button id 0 = run
				sub_item.add_button(0, i_run, 0, false, "run this test case", "Run Case")
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
	var log_snapshot: Array[Array] = phase.recorder.get_snapshot()
	var log_text = ""
	for log in log_snapshot:
		var color: String
		match log.get(0):
			Testiny.Recorder.Level.ERROR:
				color = "#ee2222"
			Testiny.Recorder.Level.WARNING:
				color = "#ffaa22"
			Testiny.Recorder.Level.VERBOSE:
				color = "#999999"
			Testiny.Recorder.Level.DEBUG:
				color = "#2222ee"
		var time: String = Time.get_datetime_string_from_unix_time(log.get(2)).split("T").get(1)
		var content: String = log.get(1).trim_suffix("\n").trim_suffix("\r")
		var error: String = Testiny.Recorder.level_strings.get(log.get(0))
		var bbtext: String
		if color:
			bbtext = "[color=%s]%s %s:[/color] %s\n" % [color, time, error, content]
		else:
			bbtext = "%s %s - %s\n" % [time, error, content]
		log_text += bbtext
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
	refresh_details()

func refresh_details()  -> void:
	var item = tree.get_selected()
	if not item:
		return
	var phase: Testiny.Phase = item.get_metadata(0)
	show_details(phase)

func _on_run_all_button_pressed() -> void:
	$Layout/ToolBox/FilterSection/LineEdit.text = ""
	_run()


func _on_tab_bar_tab_changed(_tab: int) -> void:
	var tab_title = $Layout/ToolBox/TabBar.get_tab_title($Layout/ToolBox/TabBar.current_tab)
	$Layout/View/HSplit/Config.visible = tab_title == "CONFIG"
	$Layout/View/HSplit/TestTree.visible = tab_title == "TESTS"
	$Layout/View/HSplit/Inspector.visible = tab_title == "TESTS"


func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if item:
		var phase: Testiny.Phase = item.get_metadata(0)
		match id:
			0: # "run" button
				$Layout/ToolBox/FilterSection/LineEdit.text = phase.locator
				_run()
