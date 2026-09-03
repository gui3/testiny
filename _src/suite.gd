extends ___Testiny_Phase
class_name ___Testiny_Suite
## (Phase) SYmbolizes a suite in the phase tree

var suite_path: String
var suite: ___Testiny_TestSuite
var cases: Array[___Testiny_Case] = []

func _init(
	p_description: String,
	p_config: ___Testiny_Config,
	p_suite_path: String,
) -> void:
	super(p_description, p_config)
	suite_path = p_suite_path

func _load(file_path = suite_path):
	recorder.verbose("loading %s" % file_path)
	suite_path = file_path
	cases = []
	var resource: GDScript = load(ProjectSettings.globalize_path(suite_path))
	if true:# resource.can_instantiate(): # does not work on Windows
		var instance: Object = await resource.new()
		if instance is ___Testiny_TestSuite:
			suite = instance
			var all_methods: Array[Dictionary] = suite.get_method_list()
			for method in all_methods:
				if method.name.match(config.method_is_test_match):
					var case := ___Testiny_Case.new(method.name, config, suite_path, method.name)
					cases.append(case)
			recorder.info("loaded successfully %s" % suite_path)
			status = ___Testiny_Constant.Status.READY
	else:
		recorder.warning("error loading test %s" % file_path)
		status = ___Testiny_Constant.Status.FILE_NOT_FOUND

func _run() -> void:
	# @TODO check status
	recorder.verbose("running suite %s" % description)
	if config.is_all_at_once:
		for case in cases:
			await case._run()
	else:
		for case in cases:
			case._run()
