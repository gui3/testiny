@tool
extends EditorScript
class_name Testiny

# --- CODES

enum Status {
	# first bit: 1 = is done, 0 = is not done
	
	# (mask | code) == mask -> inverse mask (all 0s are 0)
	OK =      0b000, # code 0 == OK
	FAILED =  0b001,
	DONE =    0b011, # inverse mask
	
	# mask & code != 0 -> mask (all 1s are 1s)
	NOT_DONE = 0b100, # mask
	INIT =     0b101,
	RUNNING =  0b110,
}
var status_string: Dictionary[Status, String] = {
	Status.INIT: "INIT",
	Status.RUNNING: "RUNNING",
	Status.OK: "OK",
	Status.FAILED: "FAILED",
}

# --- UTILITIES

## async
static func sleep(miliseconds: int) -> void:
	await Engine.get_main_loop().create_timer(miliseconds / 1000).timeout

static func plan(miliseconds: int, callback: Callable) -> void:
	await sleep(miliseconds)
	callback.call()

## utility for starting a sub-process,
## and connecting stdio, stderr and exit events.
class SubProcess:
	extends RefCounted
	
	var status: Status = Status.INIT
	var pid: int = -1
	var stdio: FileAccess
	var stderr: FileAccess
	var is_expired: bool = false
	var exit_code: int = -1
	
	signal stdio_emitted(data: String)
	signal stderr_emitted(data: String)
	signal exited(code: int)
	
	func expire():
		is_expired = true
		terminate()
	
	func terminate():
		OS.kill(pid)
	
	func free() -> void:
		terminate()
		super()
	
	func read_stdio(stdio: FileAccess) -> void:
		if stdio and stdio.is_open():
			while stdio.get_position() < stdio.get_length():
				var line = stdio.get_line()
				#output_text += line + "\n"
				print(" [Child] " + line)
				stdio_emitted.emit(line)
	
	func read_stderr(stderr: FileAccess) -> void:
		if stderr and stderr.is_open():
			while stderr.get_position() < stderr.get_length():
				var line = stderr.get_line()
				#output_text += line + "\n"
				printerr(" [Child error] " + line)
	
	func _run(command: String, args: PackedStringArray = [], timeout: int = 10000):
		var info: Dictionary = OS.execute_with_pipe(command, args, false)
		if info.is_empty():
			push_error("❌ Error while starting sub process")
			return
		pid = info.get("pid")
		stdio = info.get("stdio")
		stderr = info.get("stderr")
		status = Status.RUNNING
		
		# timeout
		is_expired = false
		Testiny.plan(timeout, expire)
		
		while not is_expired and OS.is_process_running(pid):
			read_stdio(stdio)
			read_stderr(stderr)
			OS.delay_msec(10)
		read_stdio(stdio)
		read_stderr(stderr)

		# Récupération du code de sortie final
		exit_code = OS.get_process_exit_code(pid)
		exited.emit(exit_code)
		if exit_code == 0:
			status = Status.OK
		else:
			status = Status.FAILED
		terminate() # just in case

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
			instance.__is_sub = true
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
		await run_file(file)
	print("--- tests have ran ---")
	

# --- TYPES

class Report:
	extends RefCounted

class Phase:
	extends RefCounted
	var description: String
	var content: Callable
	var process: SubProcess = null
	var exit_code: int = -1 # sub-process exit code
	var status: int = Status.INIT
	var children: Array[Phase] = []
	var parent: Phase = null

## -- main test file type

@abstract class Test:
	extends SceneTree
	
	signal __phase_ended(phase: Phase)
	signal __suite_ended()
	
	## OVERWRITE miliseconds before closing each test
	var timeout: int = 10000
	## OVERWRITE if true, all tests are executed simultaneously
	var is_asynchronous: bool = false
	## OVERWRITE if true, executed with a hidden interface
	var is_headless: bool = false
	
	## DO NOT OVERWRITE
	var __is_sub: bool = false
	## DO NOT OVERWRITE
	var __phases: Array[Phase] = []
	## DO NOT OVERWRITE
	var __exit_code: int = -1
	## DO NOT OVERWRITE path to the test file
	var __test_path: String = ""
	## DO NOT OVERWRITE path to godot executable
	static var __godot_path: String = OS.get_executable_path()

	func __phase_done() -> void:
		#__nb_phases_done += 1
		if __check_suite_done():
			__suite_ended.emit()

	func __check_suite_done() -> bool:
		return __phases.all(func(phase): return not OS.is_process_running(phase.pid))
	
	func __suite_done() -> void:
		# get the global code
		var code = Status.OK
		for phase in __phases:
			if phase.status != Status.OK:
				code = phase.status
		__exit_code = code
		if __is_sub:
			print("quitting")
			quit(__exit_code)

	
	func _init() -> void:
		__test_path = get_script().get_path()
		__phase_ended.connect(__phase_done)
		__suite_ended.connect(__suite_done)
	
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
				phases.append(phase)
		return phases
	
	## async
	func __run_phase(phase: Phase) -> void:
		var phase_args: Array[String] = [
			"--headless" if is_headless else "",
			"--script", __test_path,
			"--",
			phase.description,
		]
		phase.process = SubProcess.new()
		phase.process.stdio_emitted.connect(print)
		phase.process.stderr_emitted.connect(printerr)
		phase.process._run(__godot_path, phase_args, timeout)
		var exit_code = await phase.process.exited
		print("🔚 Process exited with code: %d" % exit_code)
		__phase_ended.emit(phase)
	
	## async
	func __execute_suite(filter: Array[String] = []) -> void:
		var is_all: bool = filter.size() == 0
		var nb_found: int = 0
		var phases: Array[Phase] = __get_phases()
		for phase in phases:
			print(phase)
			print(phase.description)
			if is_all or filter.has(phase.description):
				nb_found += 1
				if is_asynchronous:
					__run_phase(phase)
				else:
					await __run_phase(phase)
		if not is_all and nb_found != filter.size():
			push_error("wrong number of phases")
	
	## !DO NOT OVERRIDE this function,
	## call from godot's script launcher
	func _run() -> void:
		var cli_arguments: PackedStringArray = OS.get_cmdline_user_args()
		#print(cli_arguments)
		if cli_arguments.size() > 0:
			print("Running tests %s" % cli_arguments)
		else:
			print("running full suite %s" % __test_path)
		var exit_code = 0
		__execute_suite(cli_arguments) # async -> signal __suite_ended
