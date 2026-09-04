extends RefCounted
## "assertions" in expect style

const Expectation = preload("./expectation.gd") # self class

## if true, does not message for success, only on errors
var is_silent: bool = false

var _actual: Variant
var _is_negated: bool = false
#var errors: Array[String] = []

func _init(value: Variant, silent: bool = false) -> void:
	_actual = value
	is_silent = false

static func expect(value: Variant) -> Expectation:
	return Expectation.new(value)

## negates the result of following expectation
## [codeblock]expect(1).NOT.to_equal(2)[/codeblock]
var NOT: Expectation:
	get:
		_is_negated = not _is_negated
		return self

# --- MATCHERS ---

## basic equality
## [codeblock]expect(1).to_equal(1)[/codeblock]
func to_equal(expected: Variant) -> bool:
	var result = (_actual == expected)
	return _conclude(result, expected, "to equal")

# pointer reference identity check
#func to_be(expected: Variant) -> bool:
#	var result = (_actual == expected) # @TODO pointer equality
#	return _conclude(result, expected, "to equal")

## null check
## [codeblock]expect(null).to_be_null()[/codeblock]
func to_be_null() -> bool:
	var result = (_actual == null)
	return _conclude(result, "", "to be null")

## evaluates as a boolean (not not)
## [codeblock]
## expect("hello").to_be_truthy()
## expect(0).NOT.to_be_truthy() # falsy
## [/codeblock]
func to_be_truthy() -> bool:
	var result = not not _actual
	return _conclude(result, "", "to be truthy")

## primary types (int...) ([param expected] is the name of type)
## [codeblock]
## expect(15).to_be_of_type("int")
## [/codeblock]
func to_be_of_type(expected: String) -> bool:
	var result = type_string(typeof(_actual)) == expected
	return _conclude(result, expected, "to be of type")

## Checks inheritance of [param expected] (class name as String)
## [codeblock]
## expect(Node.new()).to_be_of_class("Object")
## [/codeblock]
func to_be_of_class(expected: String) -> bool:
	var result = _actual.is_class(expected)
	return _conclude(result, expected, "to be of class")

## check if instance is valid
## [codeblock]
## expect(Node.new()).to_be_valid()
## [/codeblock]
func to_be_valid() -> bool:
	var result = _actual.is_instance_valid()
	return _conclude(result, "", "to be valid")

## checks Array contains value,
## or Dictionary has key.
## [codeblock]
## expect([1,2,3]).to_contain(2)
## expect({"id":1, name: "tutut"}).to_contain("id")
## [/codeblock]
func to_contain(expected: Variant) -> bool:
	var result = _actual.has(expected)
	return _conclude(result, expected, "to be of class")

## checks emptyness or Array or Dictionary
## [codeblock]
## expect([]).to_be_empty()
## [/codeblock]
func to_be_empty() -> bool:
	var result = _actual.is_empty()
	return _conclude(result, "", "to be empty")

## use NOT for less or equal
## [codeblock]
## expect(Node.new()).to_be_valid()
## [/codeblock]
func to_be_greater_than(expected: float) -> bool:
	var result = _actual > expected
	return _conclude(result, expected, "to be greater than")

## use NOT for greater or equal
func to_be_less_than(expected: float) -> bool:
	var result = _actual < expected
	return _conclude(result, expected, "to be lower than")

## checks if a number is close to another
func to_be_close_to(expected: float, tolerance: float = 0.00001) -> bool:
	var diff = abs(float(_actual) - expected)
	var result = diff <= tolerance
	return _conclude(result, expected, "to be close to", "(tolerance %s)" % tolerance)

# --- Internal

func _conclude(
	condition: bool,
	expected: Variant,
	comparison_string: String, 
	details: String = ""
) -> bool:
	if _is_negated:
		condition = not condition
	if not condition:
		var msg = "Expected \"%s\" %s%s \"%s\" %s" % [
			str(_actual), 
			"NOT " if _is_negated else "",
			comparison_string,
			str(expected),
			details,
		]
		_fail(msg)
		return false
	elif not is_silent:
		print("[Testiny] OK: Confirmed \"%s\" %s%s \"%s\" %s" % [
			str(_actual), 
			"NOT " if _is_negated else "",
			comparison_string,
			str(expected),
			details,
		])
	return true

func _fail(message: String) -> void:
	#errors.append(message)
	printerr("[Testiny] FAILED: " + message)
