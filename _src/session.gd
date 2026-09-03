extends RefCounted
class_name ___Testiny_Session
## Orchestrate test execution in phases

var config: ___Testiny_Config = ___Testiny_Config.new()
var phases: Array[___Testiny_Phase] = []
var recorder: ___Testiny_Recorder = ___Testiny_Recorder.new()

func _init() -> void:
	recorder.info("------- __APP_NAME__ v__APP_VERSION__ -------")
	recorder.verbose("session started")
	_load()

func _load() -> void:
	recorder.verbose("loading files %s" % config.test_suite_match)
	var files: Array[String] =  ___Testiny_System.discover(
		config.test_suite_match,
		config.test_suite_root_path
	)
	recorder.info("%s files found" % files.size())
	for file in files:
		var suite := ___Testiny_Suite.new(file, config, file)
		phases.append(suite)
		suite._load()

func _run() -> void:
	recorder.verbose("running Session")
	if config.is_all_at_once:
		for phase in phases:
			phase._run()
	else:
		for phase in phases:
			await phase._run()

## run all test files in the project
static func run_all() -> void:
	await ___Testiny_Session.new()._run()
