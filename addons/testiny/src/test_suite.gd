extends SceneTree
## class TestSuite

const CLI_SUB_PROCESS_DETECTION_ARGUMENT: String = "_IS_TESTINY_SUB_PROCESS_"
const METHOD_PREFIX_FOR_TEST_CASES: String = "it_"
const SubProcess := preload("./sub_process.gd")

signal finished()

# OVERWRITABLE runs the test without a visible interface
var is_headless: bool = false

var _suite_path: String = get_script().get_path()
var _is_sub_process: bool = false
var _method_names: Array[String] = []

## OVERRIDE THIS to redefine overwritable properties
func setup() -> void: pass

## OVERRIDE THIS executed before each test
func before() -> void: pass

## OVERRIDE THIS executed after each test
func after() -> void: pass

func _init() -> void:
	_run()

func _run() -> void:
	setup()
	parse_cli_arguments()
	if _is_sub_process:
		_run_methods(_method_names)
		# sub process will have exit_code == 0
		# if no critical errors occured
	else:
		_execute_suite(_method_names)
		# will start a sub-process per method

## determine tested methods from cli arguments
func parse_cli_arguments() -> void:
	var cli_arguments: PackedStringArray = OS.get_cmdline_user_args()
	var all_method_names: Array[String] = []
	for method in get_method_list():
		var method_name: String = method.name
		all_method_names.append(method_name)
	for argument in cli_arguments:
		if all_method_names.has(argument) and argument.begins_with(METHOD_PREFIX_FOR_TEST_CASES):
			_method_names.append(argument)
		elif argument == CLI_SUB_PROCESS_DETECTION_ARGUMENT:
			_is_sub_process = true
		else:
			push_error("[WARNING] invalid cli argument (%s)" % argument)
	if _method_names.is_empty():
		_method_names = all_method_names.filter(
			func(m): return m.begins_with(METHOD_PREFIX_FOR_TEST_CASES)
		)

## simply run all methods
## in sync fashion
func _run_methods(methods: Array[String]) -> void:
	for method in methods:
		print("--- running %s" % method)
		before()
		await self[method].call()
		after()
	quit(0)

## Runs each method in a sub-process
func _execute_suite(methods: Array[String]):
	for method in methods:
		var sub: SubProcess = SubProcess.new()
		sub.stdio_emitted.connect(func(data): print("[stdio] %s" % data))
		sub.stderr_emitted.connect(func(data): print("[stderr] %s" % data))
		sub.exited.connect(func(code): print("[exited] %s" % code))
		sub.timeout = 5.0
		
		var cli_args: Array[String] = [
			"--headless" if is_headless else "",
			"--script", _suite_path,
			"--",
			CLI_SUB_PROCESS_DETECTION_ARGUMENT,
			method
		]		
		await sub._running(OS.get_executable_path(), cli_args)
		print("has_errors: %s" % sub.has_errors)
		print("end, code: %s" % sub.exit_code)
