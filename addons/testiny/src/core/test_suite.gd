extends SceneTree
## the base for your test files
##
## [codeblock]
## extends Testiny.TestSuite
## [/codeblock]
## see [code]res://addons/testiny/examples/...[/code]

const Expectation = preload("./expectation.gd")

signal finished()

## OVERWRITABLE runs the test without a visible interface
var is_graphics_on: bool = false
## OVERWRITABLE maximum delay before each test case expires
var timeout: float = 15.0
## OVERRIDE THIS to redefine overwritable properties
func setup() -> void: pass
## OVERRIDE THIS executed before each test
func before() -> void: pass
## OVERRIDE THIS executed after each test
func after() -> void: pass

var self_reference

# --- test utilities

func expect(value: Variant) -> Expectation:
	return Expectation.expect(value)

# --- internals

func _init() -> void:
	#Engine.print_error_messages = true
	#OS.add_logger(StdLogger.new())
	setup()
	var valid_methods = _parse_cli_arguments()
	await _run_methods(valid_methods)

## determine tested methods from cli arguments
func _parse_cli_arguments() -> Array[String]:
	var valid_methods: Array[String] = []
	var cli_arguments: PackedStringArray = OS.get_cmdline_user_args()
	var all_method_names: Array[String] = []
	for method in get_method_list():
		var method_name: String = method.name
		all_method_names.append(method_name)
	for argument in cli_arguments:
		if all_method_names.has(argument):
			valid_methods.append(argument)
		else:
			push_error("[WARNING] invalid cli argument (%s)" % argument)
	return valid_methods

## simply run all methods listed,
## no async here
func _run_methods(methods: Array[String]) -> void:
	self_reference = self
	for method in methods:
		print("------- logs for: %s -------" % method)
		before()
		await self[method].call()
		after()
	self_reference = null
	quit(0) 
	# if stderr -> FAILED
	# if not 0 code -> CRASH

# --- logging these freakin errors

class StdLogger:
	extends Logger
	
	func _log_error(
		function: String, file: String, line: int,
		code: String, rationale: String, editor_notify: bool,
		error_type: int, script_backtraces: Array[ScriptBacktrace]
	) -> void:
		print("[STDERR] %s\nfile %s line %s func %s" % [
			rationale, file, line, function
		])
	
	func _log_message(message: String, error: bool) -> void:
		if error:
			print("[STDERR]+ %s" % message)
