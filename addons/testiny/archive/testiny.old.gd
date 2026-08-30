@tool
extends EditorScript
class_name TestinyOld

# --- CODES

enum Status {
	# first bit: 1 = is done, 0 = is not done
	
	# (mask | code) == mask -> inverse mask (all 0s are 0)
	OK =      0b000, # code 0 == OK
	FAILED =  0b001,
	EXPIRED = 0b010,
	DONE =    0b011, # inverse mask
	
	# (mask & code) != 0 -> mask (all 1s are 1s)
	NOT_DONE = 0b100, # mask
	INIT =     0b101,
	RUNNING =  0b110,
}
var status_string: Dictionary[Status, String] = {
	Status.INIT: "INIT",
	Status.RUNNING: "RUNNING",
	Status.OK: "OK",
	Status.FAILED: "FAILED",
	Status.EXPIRED: "EXPIRED",
	Status.DONE: "DONE",
	Status.NOT_DONE: "NOT DONE",
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
	
	var pid: int = -1
	var stdio: FileAccess
	var stderr: FileAccess
	var exit_code: int = -1
	var is_done: bool = false
	
	signal stdio_emitted(data: String)
	signal stderr_emitted(data: String)
	signal exited(code: int)
	
	func terminate() -> int:
		print("terminate")
		exit_code = OS.get_process_exit_code(pid)
		OS.kill(pid)
		is_done = true
		exited.emit(exit_code)
		return exit_code
	
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
				stderr_emitted.emit(line)
	
	func _run(command: String, args: PackedStringArray = [], timeout: float = 10.0) -> int:
		var info: Dictionary = OS.execute_with_pipe(command, args, false)
		if info.is_empty():
			push_error("❌ Error while starting sub process")
			return 1
		pid = info.get("pid")
		stdio = info.get("stdio")
		stderr = info.get("stderr")
		
		# timeout
		var expires_at: int = Time.get_unix_time_from_system() + timeout
		
		while not is_done and OS.is_process_running(pid) and Time.get_unix_time_from_system() < expires_at:
			read_stdio(stdio)
			read_stderr(stderr)
			OS.delay_msec(50)
		read_stdio(stdio)
		read_stderr(stderr)
		print("end exit code", OS.get_process_exit_code(pid))

		return terminate() # just in case

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
	print("running file %s" % file_path)
	if FileAccess.file_exists(file_path):
		var script: Resource = load(file_path)
		var instance = script.new(true) as Test
		
		if instance and instance is Test:
			instance.__is_main = true
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
	var logs: String = ""
	var errors: String = ""
	
	func log(text) -> void:
		logs += text
	
	func fail(text) -> void:
		status = Status.FAILED
		errors += text
		if process is SubProcess:
			process.terminate()

## -- main test file type

@abstract class Test:
	extends SceneTree
	
	signal __phase_ended(phase: Phase)
	signal __suite_ended(phases: Array[Phase])
	
	## DO NOT OVERWRITE
	var __is_main: bool = false
	## DO NOT OVERWRITE
	var __phases: Array[Phase] = []
	## DO NOT OVERWRITE
	var __exit_code: int = -1
	## DO NOT OVERWRITE path to the test file
	var __test_path: String = ""
	## DO NOT OVERWRITE path to godot executable
	static var __godot_path: String = OS.get_executable_path()

	func __phase_done(phase: Phase) -> void:
		print("phase ended: %s" % phase.description)
		if __is_main and __check_suite_done():
			__suite_done()

	func __check_suite_done() -> bool:
		return __phases.all(func(phase: Phase): return phase.process.is_done)
	
	func __suite_done() -> void:
		# get the global code
		var code = Status.OK
		for phase in __phases:
			if phase.status != Status.OK:
				code = phase.status
		__exit_code = code
		__suite_ended.emit(__phases)
		if not __is_main:
			print("quitting")
			quit(__exit_code)
	
	## --- OVERRIDABLES
	
	## OVERWRITE miliseconds before closing each test
	var timeout: int = 10.0
	## OVERWRITE if true, all tests are executed simultaneously
	var is_asynchronous: bool = false
	## OVERWRITE if true, executed with a hidden interface
	var is_headless: bool = false
	
	## OVERRIDE hook for positionning execution config
	func setup() -> void: pass
	## OVERRIDE hook executed before each "it" phase.
	func before() -> void: pass
	## OVERRIDE hook executed after each "it" phase.
	func after() -> void: pass
	
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
		print("starting phase %s" % phase.description)
		var phase_args: Array[String] = [
			"--headless" if is_headless else "",
			"--script", __test_path,
			"--",
			phase.description,
		]
		phase.process = SubProcess.new()
		phase.process.stdio_emitted.connect(phase.log)
		phase.process.stderr_emitted.connect(phase.fail)
		
		phase.exit_code = await phase.process._run(__godot_path, phase_args, timeout)
		print("🔚 Process exited with code: %d" % phase.exit_code)
		__phase_ended.emit(phase)
	
	## async
	func __execute_suite(filter: Array[String] = []) -> void:
		var is_all: bool = filter.size() == 0
		var nb_found: int = 0
		__exit_code = -1
		var phases: Array[Phase] = __get_phases()
		for phase in phases:
			if is_all or filter.has(phase.description):
				nb_found += 1
				if not __is_main:
					__run_test(phase.description)
					__phase_ended.emit(phase)
				else:
					if is_asynchronous:
						__run_phase(phase)
					else:
						await __run_phase(phase)
		if not is_all and nb_found != filter.size():
			push_error("wrong number of phases")
		if not __is_main:
			__suite_ended.emit()
	
	func __run_test(test_name: String) -> void:
		before()
		self[test_name].call()
		after()
	
	## !DO NOT OVERRIDE this function,
	## call from godot's script launcher
	func _init(is_main: bool = false) -> void:
		print("running %s" % __test_path)
		__test_path = get_script().get_path()
		__phase_ended.connect(__phase_done)
		__is_main = is_main
		if not __is_main:
			_run()
	
	func _run() -> int:
		setup()
		var cli_arguments: PackedStringArray = OS.get_cmdline_user_args()
		if cli_arguments.size() > 0:
			print("Running tests %s" % cli_arguments)
		else:
			print("running full suite")
		
		__execute_suite(cli_arguments) # async -> signal __suite_ended
		await __suite_ended
		return __exit_code
