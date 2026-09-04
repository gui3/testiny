extends Node
## class SubProcess,
## where you can listen to [signal stdio_emitted], 
## [signal stderr_emitted] and [signal exited] events.

const Config = preload("./config.gd")

var pid: int = -1
#var stdio: FileAccess
#var stderr: FileAccess
var exit_code: int = -1
var is_done: bool = false
var is_expired: bool = false
var has_errors: bool = false
var timeout: float = 35.0 # seconds
var config := Config.new()
var _self_reference 

signal stdio_emitted(data: String)
signal stderr_emitted(data: String)
signal exited(code: int)

## [b][color=orange]! Synchronous (blocking)[/color][/b]
## [br]
## runs the [param command] with [param args],
## kills the sub-process if it takes more than [param timeout]
func _running(command: String, args: PackedStringArray = [], p_config := Config.new()) -> void:
	_self_reference = self # for avoiding garbage collection
	config = p_config
	var process_info: Dictionary = OS.execute_with_pipe(command, args, false)
	if process_info.is_empty():
		push_error("Error while starting sub process")
		return
	pid = process_info.get("pid")
	var stdio: FileAccess = process_info.get("stdio")
	var stderr: FileAccess = process_info.get("stderr")
	
	# loop async (otherise it blocks everything)
	_reading_loop(stdio, stderr)

func _reading_loop(stdio: FileAccess, stderr: FileAccess):
	# https://github.com/godotengine/godot/issues/65884

	# timeout for security
	var expires_at: int = Time.get_unix_time_from_system() + config.timeout
	while not is_done and OS.is_process_running(pid) and Time.get_unix_time_from_system() < expires_at:
		read_stdio(stdio)
		read_stderr(stderr)
		#OS.delay_msec(15) # blocking for this thread
		await (Engine.get_main_loop() as SceneTree).create_timer(0.1).timeout
		if has_errors:
			break
	if OS.is_process_running(pid):
		read_stdio(stdio)
		read_stderr(stderr)
		stdio.close()
		stderr.close()
	if Time.get_unix_time_from_system() > expires_at:
		is_expired = true
	print("end exit code", OS.get_process_exit_code(pid))
	terminate()
	_self_reference = null


## internal method to read the stdio buffer
func read_stdio(stdio: FileAccess) -> void:
	if stdio and stdio.is_open() and stdio.get_length() > 0:
		#var text = stdio.get_line()
		var text = stdio.get_buffer(stdio.get_length()).get_string_from_utf8()
		#print(" [Child] " + line)
		# \r windows, don't care
		stdio_emitted.emit(text)#.replace("\r", "").replace("\n", ""))

## internal method to read the stderr buffer
func read_stderr(stderr: FileAccess) -> void:
	if stderr and stderr.is_open() and stderr.get_length() > 0:
		has_errors = true
		#var text = stderr.get_line()
		var text = stderr.get_buffer(stderr.get_length()).get_string_from_utf8()
		# \r windows, don't care
		stderr_emitted.emit(text)#.replace("\r", "").replace("\n", ""))

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
