extends RefCounted
class_name ___Testiny_SubProcess
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
