extends "./phase.gd"
## (Phase) SYmbolizes a suite in the phase tree

const TestSuite = preload("./test_suite.gd")
const Case = preload("./case.gd")

var suite_path: String
var suite: TestSuite
var cases: Array[Case] = []
var is_done: bool = false

func _init(
	p_description: String,
	p_config: Config,
	p_suite_path: String,
) -> void:
	super(p_description, p_config)
	suite_path = p_suite_path

func _load(file_path = suite_path):
	recorder.verbose("loading %s" % file_path)
	suite_path = file_path
	cases = []
	var resource: GDScript = load(suite_path)
	if resource.new is Callable: #.can_instantiate(): # does not work on Windows
		var instance: Object = await resource.new()
		if instance is TestSuite:
			suite = instance
			var all_methods: Array[Dictionary] = suite.get_method_list()
			for method in all_methods:
				if method.name.match(config.method_is_test_match):
					var case := Case.new(method.name, config, suite_path, method.name)
					cases.append(case)
			recorder.info("loaded successfully %s" % suite_path)
			set_status(Constant.Status.READY)
	else:
		recorder.warning("error loading test %s" % file_path)
		set_status(Constant.Status.FILE_NOT_FOUND)

func _run() -> void:
	is_done = false
	# @TODO check status
	recorder.verbose("running suite %s" % description)
	set_status(Constant.Status.RUNNING)
	for case in cases:
		if config.is_all_at_once:
			case._run()
		else:
			await case._run()
	await updating_status()

## (async)
func updating_status() -> void:
	await waiting_finished()
	# getting max (worse) status of all tests
	var result_status: Constant.Status = Constant.Status.OK
	for case in cases:
		result_status = max(result_status, case.status)
	# filter out irrelevant statuses
	if result_status >= Constant.StatusCategory.CRASHED:
		set_status(Constant.Status.CRASHED)
	elif result_status >= Constant.StatusCategory.FAILED:
		set_status(Constant.Status.FAILED)
	elif result_status >= Constant.StatusCategory.WAITING:
		set_status(Constant.Status.RUNNING)
	else:
		set_status(Constant.Status.OK)

## (async)
func waiting_finished() -> void:
	for case in cases:
		await case.waiting_finished()
