extends RefCounted
## Orchestrate test execution in phases

const System = preload("./system.gd")
const Config = preload("./config.gd")
const AppInfo = preload("../app_info.gd")
const Recorder = preload("./recorder.gd")
const Phase = preload("./phase.gd")
const Suite = preload("./suite.gd")

var config: Config = Config.new()
var phases: Array[Phase] = []
var recorder: Recorder = Recorder.new()
var is_done: bool = false
var self_reference

func _init() -> void:
	recorder.info("------- %s v%s -------" % [AppInfo.NAME, AppInfo.VERSION])
	recorder.verbose("session started")

func _load() -> void:
	recorder.verbose("loading files %s" % config.test_suite_match)
	var files: Array[String] = System.discover(
		config.test_suite_match,
		config.test_suite_root_path
	)
	recorder.info("%s files found" % files.size())
	for file in files:
		print("HELLO")
		var suite := Suite.new(file, config, file)
		phases.append(suite)
		suite._load()

func _run() -> void:
	is_done = false
	self_reference = self
	recorder.verbose("running Session")
	print("async", config.is_all_at_once)
	if config.is_all_at_once:
		for phase in phases:
			phase._run()
	else:
		for phase in phases:
			await phase._run()
	await waiting_finished()
	is_done = true
	self_reference = null

func waiting_finished():
	for phase in phases:
		await phase.waiting_finished()
