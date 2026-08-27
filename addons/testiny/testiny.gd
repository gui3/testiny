@tool
extends EditorScript
class_name Testiny

# --- UTILITIES

## async
static func sleep(seconds) -> void:
	await Engine.get_main_loop().create_timer(seconds).timeout

# --- GLOBAL MANAGER

static func discover(extension: String = ".test.gd", root_dir: String = "res://") -> PackedStringArray:
	var files: Array[String] = []
	if not root_dir.ends_with("/"): root_dir += "/"
	for file in DirAccess.get_files_at(root_dir):
		if file.ends_with(extension):
			var file_path: String = "%s%s" % [root_dir, file]
			print("found %s" % file_path)
			files.append(file_path)
	for dir in DirAccess.get_directories_at(root_dir):
		var dir_path: String = "%s%s" % [root_dir, dir]
		var sub_files: PackedStringArray = discover(extension, dir_path)
		files.append_array(sub_files)
	return files

static func run_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var script: Resource = load(file_path)
		var instance = script.new()
		
		if instance is Testiny.Test:
			await instance._run()
			if instance is Node: instance.free()
		else: 
			OS.alert("Not a Testiny.Test\n(%s)" % instance.test_path)
	else: 
		OS.alert("File doesn't exis\n(%s)" % file_path)
	

func _run() -> void:
	print("--- running Testiny ---")
	var files: PackedStringArray = discover()
	for file in files:
		run_file(file)
	

# --- TYPES

class Report:
	extends RefCounted

class Phase:
	extends RefCounted
	var description: String
	var content: Callable
	var is_test_case: bool # "it" phases
	var children: Array[Phase] = []
	var parent: Phase = null

## -- main test file type
@abstract class Test:
	extends SceneTree
	
	signal phase_ended(phase_name: String)
	
	var is_run_alone: bool = false
	var __test_path: String = get_script().get_path()
	static var __godot_path: String = OS.get_executable_path()
	
	## --- OVERRIDABLES
	
	## OVERRIDE hook executed before each "it" phase.
	func _before() -> void: pass
	## OVERRIDE hook executed after each "it" phase.
	func _after() -> void: pass
	
	## --- CORE FUNCTIONS
	
	func __get_phases() -> Array[Phase]:
		var phases: Array[Phase] = []
		for method in get_method_list():
			var phase_name: String = method.name
			if phase_name.begins_with("it_"):
				var phase: Phase = Phase.new()
				phase.description = phase_name
				phase.content = self[phase_name]
				phase.is_test_case = true
				phases.append(phase)
		return phases
	
	func __execute_suite(filter: Array[String] = []) -> void:
		var is_all: bool = filter.size() == 0
		var nb_found: int = 0
		var phases: Array[Phase] = __get_phases()
		for phase in phases:
			print(phase)
			print(phase.description)
			if is_all or filter.has(phase.description):
				nb_found += 1
				await __run_phase(phase)
		if not is_all and nb_found != filter.size():
			push_error("wrong number of phases")
	
	## async
	func __run_phase(phase: Phase) -> void:
		var phase_args: Array[String] = [
			#"--headless",
			"--script", __test_path,
			"--",
			phase.description,
		]
		var ended = false
		var process = OS.execute_with_pipe(__godot_path, phase_args, false)
		while not ended:
			print("new loop")
			var stdio = process.get("stdio", null) as FileAccess
			var stderr = process.get("stderr", null) as FileAccess

			if stdio:
				var line = stdio.get_line()
				if stdio.get_error() == OK:
					print("STDIO: %s" % line)
				else:
					ended = true
			if stderr:
				var line = stderr.get_line()
				if stderr.get_error() == OK:
					print("STDERR: %s" % line)
				else:
					ended = true
			Engine.get_main_loop().create_timer(4).timeout.connect(func():
				ended = true
			)
			await Testiny.sleep(0.2)
		OS.kill(process.get("pid", null))
	
	## !DO NOT OVERRIDE this function,
	## call from godot's script launcher
	func _run() -> void:
		var cli_arguments: PackedStringArray = OS.get_cmdline_user_args()
		if cli_arguments.size() > 0:
			print(cli_arguments)
			print("Running testq %s" % cli_arguments)
			await __execute_suite(cli_arguments)
			print("end of suite " + __test_path)
		else:
			print("running full suite %s" % __test_path)
			await __execute_suite()
