extends "./phase.gd"
## Orchestrate test execution in phases

#const Phase = preload("./phase.gd") # self

const System = preload("./system.gd")
const AppInfo = preload("../app_info.gd")
const Suite = preload("./suite.gd")

signal count_updated(ended_count: int, total_count: int, details: Constant.Status, int)

var suites: Array[Suite] = []
#var self_reference
var thread: Thread
var mutex := Mutex.new()
var thread_list: Array[String] = []
var current_suite_index: int = -1
var current_suite: Suite
var case_count: int = 0

func _init(
	p_description: String = "Anonymous session",
	p_config: Config = Config.new(),
) -> void:
	super(p_description, p_config)
	recorder.info("------- %s v%s -------" % [AppInfo.NAME, AppInfo.VERSION])
	set_status(Constant.Status.INIT)
	recorder.verbose("session started")

func _load() -> void:
	recorder.verbose("loading files %s" % config.test_suite_matches)
	if thread and thread.is_alive():
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(func():
		var thread_files = System.discover(
			config.test_suite_matches,
			config.test_suite_root_path,
			config.test_suite_excludes
		)
		# loading suites and phases
		var thread_suites: Array[Suite] = []
		for file in thread_files:
			var suite := Suite.new(file, config, file)
			thread_suites.append(suite)
			#add_child(suite)
			#suite.ended.connect(update_status)
			suite._load()
		return thread_suites
	)
	set_status(Constant.Status.LOADING)

func set_status(p_status: Constant.Status) -> void:
	mutex.lock()
	super(p_status)
	mutex.unlock()

func get_status() -> Constant.Status:
	var result: Constant.Status
	mutex.lock()
	result = status
	mutex.unlock()
	return status

func _process(delta: float) -> void:
	if get_status() == Constant.Status.CANCELLED:
		set_process(false)
		pass
	elif get_status() == Constant.Status.LOADING:
		if thread and not thread.is_alive():
			suites = thread.wait_to_finish()
			thread = null
			case_count = 0
			for suite in suites:
				suite.get_cases() # cannot instantiate in thread
				for case in suite.cases:
					suite.add_child(case)
					case_count += 1
					# for async
					case.ended.connect(update_case_count.call_deferred)
				add_child(suite)
			set_status(Constant.Status.READY)
			update_case_count()
			loaded.emit()
	elif get_status() == Constant.Status.RUNNING:
		if check_is_done():
			end()
			update_case_count()
		elif current_suite_index >= 0 and current_suite_index < suites.size():
			current_suite = suites[current_suite_index]
			if current_suite.status == Constant.Status.READY:
				current_suite._run()
				update_case_count.call_deferred()
			if config.is_all_at_once or current_suite.is_done:
				current_suite_index = current_suite_index + 1
				update_case_count.call_deferred()

func check_is_done() -> bool:
	if is_done:
		return true
	var all_done: bool = true
	for suite in suites:
		all_done = all_done and suite.is_done
	return all_done

func end() -> void:
	if thread and thread.is_alive():
		thread.wait_to_finish()
	set_process(false)
	is_done = true
	#self_reference = null
	update_status()
	ended.emit()
	

func _run() -> void:
	is_done = false
	#self_reference = self
	recorder.verbose("running Session")
	current_suite_index = 0
	status = Constant.Status.RUNNING
	set_process(true)

func update_case_count() -> void:
	var ended_count: int = 0
	var details: Dictionary[Constant.Status, int] = {}
	for suite in suites:
		for case in suite.cases:
			if case.is_done:
				ended_count +=1
			var case_status = case.get_status()
			details[case_status] = 1 if not details.get(case_status) else details[case_status] + 1
	count_updated.emit(ended_count, case_count, details)

func update_status() -> void:
	var check: bool = true
	for suite in suites:
		check = check and suite.is_done
	if check:
		is_done = true
		#self_reference = null
		for suite in suites:
			status = max(status, suite.status)
		set_status(status)
		ended.emit()

func _notification(what: int) -> void:
	super(what)
	if what == NOTIFICATION_EXIT_TREE:
		if thread and thread.is_alive():
			thread.wait_to_finish()
			await get_tree().process_frame
