extends SceneTree
class_name ___Testiny_TestSuite
## the base for your test files
##
## [codeblock]
## extends Testiny.TestSuite
## [/codeblock]
## see [code]res://addons/testiny/examples/...[/code]

signal finished()

## OVERWRITABLE runs the test without a visible interface
var is_graphics_on: bool = false
## OVERRIDE THIS to redefine overwritable properties
func setup() -> void: pass
## OVERRIDE THIS executed before each test
func before() -> void: pass
## OVERRIDE THIS executed after each test
func after() -> void: pass

var _method_names: Array[String] = []

# --- test utilities

func expect(value: Variant) -> ___Testiny_Expectation:
	return ___Testiny_Expectation.expect(value)

# --- internals

func _init() -> void:
	setup()
	var valid_methods = _parse_cli_arguments()
	if not valid_methods.is_empty():
		_run_methods(_method_names)

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
	for method in methods:
		print("--- running %s" % method)
		before()
		await self[method].call()
		after()
	quit(0)
