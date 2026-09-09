extends "./phase.gd"
## (Phase) SYmbolizes a suite in the phase tree

const TestSuite = preload("./test_suite.gd")
const Case = preload("./case.gd")

var suite: TestSuite
var cases: Array[Case] = []
var current_case_index: int = -1
var current_case: Case
#var self_reference
var resource: Resource

func _init(
	p_description: String,
	p_config: Config,
	p_suite_path: String,
) -> void:
	super(p_description, p_config, p_suite_path)

func _load(file_path = suite_path):
	recorder.verbose("loading %s" % file_path)
	suite_path = file_path
	resource = load(suite_path)
	recorder.info("loaded successfully %s" % suite_path)

func get_cases() -> void:
	if resource.new is Callable: #.can_instantiate(): # does not work on Windows
		var instance: Object = resource.new()
		if instance is TestSuite:
			suite = instance
			var all_methods: Array[Dictionary] = suite.get_method_list()
			for method in all_methods:
				if method.name.match(config.method_is_test_match):
					var case := Case.new(method.name, config, suite_path, method.name)
					cases.append(case)
					if case.locator.match("*%s*" % config.filter):
						case._load()
					else:
						case.is_done = true
						case.set_status(Constant.Status.IGNORED)
						case.ended.emit()
			if cases.size() == 0:
				set_status(Constant.Status.IGNORED)
			else:
				set_status(Constant.Status.READY)
	else:
		#recorder.warning("error loading test %s" % file_path)
		set_status(Constant.Status.FILE_NOT_FOUND)

func _run() -> void:
	if cases.size() < 1:
		end()
		return
	is_done = false
	#self_reference = self
	recorder.verbose("running suite %s" % description)
	set_status(Constant.Status.RUNNING)
	current_case_index = 0
	set_process(true)

func _process(_delta: float) -> void:
	if status in [Constant.Status.CANCELLED, Constant.Status.IGNORED]:
		set_process(false)
		is_done = true
		pass
	if status == Constant.Status.RUNNING:
		if check_is_done():
			end()
		elif current_case_index >= 0 and current_case_index < cases.size():
			current_case = cases[current_case_index]
			if current_case.status == Constant.Status.READY:
				current_case._run()
			if config.is_all_at_once or current_case.is_done:
				current_case_index = current_case_index + 1

func check_is_done() -> bool:
	if is_done:
		return true
	var all_done: bool = true
	for case in cases:
		all_done = all_done and case.is_done
	return all_done

func end() -> void:
	set_process(false)
	is_done = true
	#self_reference = null
	update_status()
	ended.emit()

## (async)
func update_status() -> void:
	if not check_is_done():
		return
	if cases.size() < 1:
		set_status(status)
		return
	# getting max (worse) status of all tests
	var result_status: Constant.Status = Constant.Status.OK
	var all_cancelled: bool = true
	for case in cases:
		result_status = max(result_status, case.status)
		if not Constant.get_category(case.status) == Constant.StatusCategory.STOPPED:
			all_cancelled = false
	# the cancelled case
	if all_cancelled:
		set_status(Constant.Status.IGNORED)
		return
	# filter out irrelevant statuses
	if result_status >= Constant.StatusCategory.CRASHED:
		set_status(Constant.Status.CRASHED)
	elif result_status >= Constant.StatusCategory.FAILED:
		set_status(Constant.Status.FAILED)
	elif result_status == Constant.StatusCategory.IDLE:
		set_status(Constant.Status.READY)
	else:
		set_status(Constant.Status.OK)
