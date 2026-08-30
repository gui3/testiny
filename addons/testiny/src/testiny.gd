@tool
extends EditorScript
class_name Testiny

# --- NAMESPACES

#const Codes := preload("./codes.gd")
#const History := preload("./history.gd")
#const Types := preload("./types.gd")
const TestSuite := preload("./test_suite.gd")
const System := preload("./system.gd")

func _run() -> void:
	var files: Array[String] = System.discover(".test.gd", "res://")
	print_debug(files)
	for file in files:
		var script: GDScript = load(file)
		if script.can_instantiate():
			var instance := script.new()
			print("over")
		else:
			print("cannot instantiate")
