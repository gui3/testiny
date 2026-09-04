extends Node
class_name Testiny # doesn't work well with Autoload 
## --- Testiny ---
## [br]
## (see app_info.gd for current version)
##
## [codeblock]
## extends Testiny.TestSuite
## [/codeblock]

const AppInfo = preload("./app_info.gd")
const Constant = preload("./core/constant.gd")
const Expectation = preload("./core/expectation.gd")
const TestSuite = preload("./core/test_suite.gd")
const Recorder = preload("./core/recorder.gd")
const System = preload("./core/system.gd")
const SubProcess = preload("./core/sub_process.gd")
const Phase = preload("./core/phase.gd")
const Case = preload("./core/case.gd")
const Suite = preload("./core/suite.gd")
const Session = preload("./core/session.gd")

func _run() -> void:
	var session := Session.new()
	await session._load()
	await session._run()
