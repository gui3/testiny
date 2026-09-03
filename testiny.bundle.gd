extends RefCounted
class_name ___TESTINY_MAIN___
## --- __APP_NAME__ v__APP_VERSION__ ---[br]
## __APP_BRIEF__
##
## [codeblock]
## extends Testiny.TestSuite
## [/codeblock]

#!bundle:import ./_src/constant.gd
#!bundle:import ./_src/config.gd
#!bundle:import ./_src/expectation.gd
#!bundle:import ./_src/test_suite.gd
#!bundle:import ./_src/recorder.gd
#!bundle:import ./_src/system.gd
#!bundle:import ./_src/sub_process.gd
#!bundle:import ./_src/phase.gd
#!bundle:import ./_src/case.gd
#!bundle:import ./_src/suite.gd
#!bundle:import ./_src/session.gd

func _run() -> void:
	await ___Testiny_Session.run_all()

static func run() -> void:
	await ___TESTINY_MAIN___.new()._run()
