extends RefCounted
class_name Testiny
## --- Testiny v0.1.11 ---[br]
## Foresee bugs and crashes!
##
## [codeblock]
## extends Testiny.TestSuite
## [/codeblock]


@abstract class Constant:
	
	extends Object
	## this "namespace" holds app's internal constants
	
	enum Status {
		# bits mean approx.: (not done)(bad news)(couldn't end)(couldn't run)
		OK             = 0b0000,
		FILE_NOT_FOUND = 0b0001,
		CANCELLED      = 0b0010,
		IGNORED        = 0b0011,
		FAILED         = 0b0100,
		CRITICAL       = 0b0101,
		EXPIRED        = 0b0110,
		DONE           = 0b0111, # inverse mask (mask | code) == mask
		
		NOT_DONE       = 0b1000, # mask         (mask & code) != 0
		INIT           = 0b1001,
		READY          = 0b1010,
		RUNNING        = 0b1011,
	}
	const status_string: Dictionary[int, String] = {
		Status.OK: "OK", Status.FAILED: "FAILED", Status.EXPIRED: "EXPIRED",
		Status.CANCELLED: "CANCELLED", Status.CRITICAL: "CRITICAL", Status.DONE: "DONE",
		Status.NOT_DONE: "NOT_DONE", Status.INIT: "INIT", Status.RUNNING: "RUNNING",
		Status.READY: "READY", Status.FILE_NOT_FOUND: "FILE_NOT_FOUND"
	}
	
	static func check_is_done(status: Status) -> bool:
		return (Status.DONE | status) == Status.DONE
	
	static func check_is_not_done(status: Status) -> bool:
		return (Status.NOT_DONE & status) != 0
	


class Config:
	extends RefCounted
	
	## glob for test discovery
	var test_suite_match: String = "*.test.gd"
	## root path for test discovery
	var test_suite_root_path: String = "res://"
	## beginning of method names considered as tests
	var method_is_test_match: String = "it_*"
	## if true, show godot interface for each test
	var is_graphics_on: bool = false
	## if true, run all tests simultaneously (asynchronously)
	var is_all_at_once: bool = false
	


class Expectation:
	extends RefCounted
	
	## if true, does not message for success, only on errors
	var is_silent: bool = false
	
	var _actual: Variant
	var _is_negated: bool = false
	#var errors: Array[String] = []
	
	func _init(value: Variant, silent: bool = false) -> void:
		_actual = value
		is_silent = false
	
	static func expect(value: Variant) -> Testiny.Expectation:
		return Testiny.Expectation.new(value)
	
	## negates the result of following expectation
	## [codeblock]expect(1).NOT.to_equal(2)[/codeblock]
	var NOT: Testiny.Expectation:
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
		push_error("[Testiny] FAILED: " + message)
	


class TestSuite:
	extends SceneTree
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
	
	func expect(value: Variant) -> Testiny.Expectation:
		return Testiny.Expectation.expect(value)
	
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
	


class Recorder:
	extends RefCounted
	## it's a logger, but Logger was no available name
	
	enum Level {IMPORTANT, ERROR, WARNING, INFO, VERBOSE, DEBUG}
	const level_strings: Dictionary = {
		Level.IMPORTANT: "IMPORTANT", Level.ERROR: "ERROR", Level.WARNING: "WARNING",
		Level.INFO: "INFO", Level.VERBOSE: "VERBOSE", Level.DEBUG: "DEBUG",
	}
	
	signal recorded(level: Level, content: Variant, timestamp: float)
	
	var print_level: Level = Level.DEBUG
	
	var levels: Array[Level] = []
	var contents: Array[Variant] = []
	var timestamps: Array[float] = []
	
	func add(
		level: Level,
		content: Variant,
		timestamp: float = Time.get_unix_time_from_system(),
	) -> int:
		levels.append(level)
		contents.append(content)
		timestamps.append(timestamp)
		var index = levels.size() - 1
		recorded.emit(level, content, timestamp)
		print(format(index))
		return index
	
	func get_log(index: int):
		return [
			levels[index],
			contents[index],
			timestamps[index],
		]
	
	func filter_level(level: Level) -> Testiny.Recorder:
		var result := Testiny.Recorder.new()
		for i in range(levels.size()):
			if levels[i] == level:
				result.add(levels[i], contents[i], timestamps[i])
		return result
	
	func critical(content: Variant) -> int:
		return add(Level.IMPORTANT, content)
		
	func error(content: Variant) -> int:
		return add(Level.ERROR, content)
		
	func warning(content: Variant) -> int:
		return add(Level.WARNING, content)
		
	func info(content: Variant) -> int:
		return add(Level.INFO, content)
	
	func verbose(content: Variant) -> int:
		return add(Level.VERBOSE, content)
	
	func debug(content: Variant) -> int:
		return add(Level.DEBUG, content)
	
	func show_exit_code(code: int) -> int:
		return add(Level.INFO, "[exit code] %s" % code)
	
	func format(index: int) -> String:
		return "%s [%s] %s" % [
			Time.get_datetime_string_from_unix_time(timestamps[index]),
			level_strings[levels[index]],
			str(contents[index])
		]
	


@abstract class System:
	extends Object
	
	
	## walks through [param root_dir]
	## and returns a list of file paths mathing [param extension] at the end
	static func discover(extension: String = ".test.gd", root_dir: String = "res://") -> Array[String]:
		var files: Array[String] = []
		if not root_dir.ends_with("/"): root_dir += "/"
		for file in DirAccess.get_files_at(root_dir):
			if file.match(extension):
				var file_path: String = "%s%s" % [root_dir, file]
				print("found %s" % file_path)
				files.append(file_path)
		for dir in DirAccess.get_directories_at(root_dir):
			var dir_path: String = "%s%s" % [root_dir, dir]
			var sub_files: Array[String] = discover(extension, dir_path)
			files.append_array(sub_files)
		return files
	


class SubProcess:
	extends RefCounted
	## class SubProcess,
	## where you can listen to [signal stdio_emitted], 
	## [signal stderr_emitted] and [signal exited] events.
	
	var pid: int = -1
	var stdio: FileAccess
	var stderr: FileAccess
	var exit_code: int = -1
	var is_done: bool = false
	var has_errors: bool = false
	var timeout: float = 10.0 # seconds
	var _self_reference: RefCounted = null
	
	signal stdio_emitted(data: String)
	signal stderr_emitted(data: String)
	signal started
	signal exited(code: int)
	
	## terminate the sub-process
	func terminate() -> void:
		print("terminate")
		exit_code = OS.get_process_exit_code(pid)
		OS.kill(pid)
		is_done = true
		exited.emit(exit_code)
	
	## (async)
	func waiting_exit() -> void:
		if not is_done:
			await exited
		return
	
	## OVERRIDE ensures that [method terminate] is called
	## before freeing this [class Object]
	func free() -> void:
		terminate()
		super()
	
	## internal method to read the stdio buffer
	func read_stdio(stdio: FileAccess) -> void:
		if stdio and stdio.is_open():
			while stdio.get_position() < stdio.get_length():
				#var line = stdio.get_line()
				var text = stdio.get_buffer(stdio.get_length()).get_string_from_utf8()
				#print(" [Child] " + line)
				# \r windows, don't care
				stdio_emitted.emit(text.replace("\r", "").replace("\n", ""))
	
	## internal method to read the stderr buffer
	func read_stderr(stderr: FileAccess) -> void:
		if stderr and stderr.is_open():
			while stderr.get_position() < stderr.get_length():
				#var line = stderr.get_line()
				var text = stderr.get_buffer(stderr.get_length()).get_string_from_utf8()
				has_errors = true
				# \r windows, don't care
				stderr_emitted.emit(text.replace("\r", "").replace("\n", ""))
	
	## [b][color=orange]! Synchronous (blocking)[/color][/b]
	## [br]
	## runs the [param command] with [param args],
	## kills the sub-process if it takes more than [param timeout]
	func _running(command: String, args: PackedStringArray = []) -> void:
		var process_info: Dictionary = OS.execute_with_pipe(command, args, false)
		if process_info.is_empty():
			push_error("❌ Error while starting sub process")
			return
		pid = process_info.get("pid")
		stdio = process_info.get("stdio")
		stderr = process_info.get("stderr")
		
		# loop async (otherise it blocks everything)
		_reading_loop()
		await waiting_exit()
	
	func _reading_loop():
		_self_reference = self # for avoiding garbage collection
		# https://github.com/godotengine/godot/issues/65884
	
		# timeout for security
		var expires_at: int = Time.get_unix_time_from_system() + timeout
		while not is_done and OS.is_process_running(pid) and Time.get_unix_time_from_system() < expires_at:
			read_stdio(stdio)
			read_stderr(stderr)
			#OS.delay_msec(15) # blocking for this thread
			await (Engine.get_main_loop() as SceneTree).create_timer(0.1).timeout
		if OS.is_process_running(pid):
			read_stdio(stdio)
			read_stderr(stderr)
			#stdio.close()
			#stderr.close()
		#print("end exit code", OS.get_process_exit_code(pid))
		terminate()
		_self_reference = null # ok for garbage collection
	


@abstract class Phase:
	
	extends RefCounted
	## (Interface) Symbolizes a node in the test tree
	
	var description: String
	var config: Testiny.Config
	var recorder: Testiny.Recorder
	var status: Testiny.Constant.Status = Testiny.Constant.Status.INIT
	
	func _init(
		p_description: String,
		p_config: Testiny.Config,
	) -> void:
		recorder = Testiny.Recorder.new()
		description = p_description
		config = p_config
	
	@abstract func _run();
	@abstract func _load();
	


class Case:
	extends Testiny.Phase
	## represents a test case (method it_)
	## in the phase tree
	
	var sub_process: Testiny.SubProcess
	var suite_path: String
	var method_name: String
	
	func _init(
		p_description: String,
		p_config: Testiny.Config,
		p_suite_path: String,
		p_method_name: String
	) -> void:
		super(p_description, p_config)
		suite_path = p_suite_path
		method_name = p_method_name
	
	func _load() -> void: pass
	
	func _run():
		recorder.info("Running %s" % [method_name])
		sub_process = Testiny.SubProcess.new()
		#sub_process.stdio_emitted.connect(func(data): print("[stdio] %s" % data))
		#sub_process.stderr_emitted.connect(func(data): print("[stderr] %s" % data))
		#sub_process.exited.connect(func(code): print("[exited] %s" % code))
		sub_process.stdio_emitted.connect(recorder.info)
		sub_process.stderr_emitted.connect(recorder.error)
		sub_process.exited.connect(recorder.show_exit_code)
		sub_process.timeout = 5.0
		
		var cli_args: Array[String] = [
			"--headless" if not config.is_graphics_on else "",
			"--script", suite_path,
			"--",
			#Testiny.TestSuite.CLI_SUB_PROCESS_DETECTION_ARGUMENT,
			method_name
		]
		recorder.verbose("starting sub-process")
		await sub_process._running(OS.get_executable_path(), cli_args)
		recorder.verbose("sub-process shoudl have exited (or garbage collection error)")
		recorder.debug("has_errors: %s" % sub_process.has_errors)
		recorder.debug("exit_code: %s" % sub_process.exit_code)
	


class Suite:
	extends Testiny.Phase
	## (Phase) SYmbolizes a suite in the phase tree
	
	var suite_path: String
	var suite: Testiny.TestSuite
	var cases: Array[Testiny.Case] = []
	
	func _init(
		p_description: String,
		p_config: Testiny.Config,
		p_suite_path: String,
	) -> void:
		super(p_description, p_config)
		suite_path = p_suite_path
	
	func _load(file_path = suite_path):
		recorder.verbose("loading %s" % file_path)
		suite_path = file_path
		cases = []
		var resource: GDScript = load(ProjectSettings.globalize_path(suite_path))
		if true:# resource.can_instantiate(): # does not work on Windows
			var instance: Object = await resource.new()
			if instance is Testiny.TestSuite:
				suite = instance
				var all_methods: Array[Dictionary] = suite.get_method_list()
				for method in all_methods:
					if method.name.match(config.method_is_test_match):
						var case := Testiny.Case.new(method.name, config, suite_path, method.name)
						cases.append(case)
				recorder.info("loaded successfully %s" % suite_path)
				status = Testiny.Constant.Status.READY
		else:
			recorder.warning("error loading test %s" % file_path)
			status = Testiny.Constant.Status.FILE_NOT_FOUND
	
	func _run() -> void:
		# @TODO check status
		recorder.verbose("running suite %s" % description)
		if config.is_all_at_once:
			for case in cases:
				await case._run()
		else:
			for case in cases:
				case._run()
	


class Session:
	extends RefCounted
	## Orchestrate test execution in phases
	
	var config: Testiny.Config = Testiny.Config.new()
	var phases: Array[Testiny.Phase] = []
	var recorder: Testiny.Recorder = Testiny.Recorder.new()
	
	func _init() -> void:
		recorder.info("------- Testiny v0.1.11 -------")
		recorder.verbose("session started")
		_load()
	
	func _load() -> void:
		recorder.verbose("loading files %s" % config.test_suite_match)
		var files: Array[String] =  Testiny.System.discover(
			config.test_suite_match,
			config.test_suite_root_path
		)
		recorder.info("%s files found" % files.size())
		for file in files:
			var suite := Testiny.Suite.new(file, config, file)
			phases.append(suite)
			suite._load()
	
	func _run() -> void:
		recorder.verbose("running Session")
		if config.is_all_at_once:
			for phase in phases:
				phase._run()
		else:
			for phase in phases:
				await phase._run()
	
	## run all test files in the project
	static func run_all() -> void:
		await Testiny.Session.new()._run()
	


func _run() -> void:
	await Testiny.Session.run_all()

static func run() -> void:
	await Testiny.new()._run()
