extends Node
## class SubProcess,
## where you can listen to [signal stdio_emitted], 
## [signal stderr_emitted] and [signal exited] events.

enum Status {
	READY,
	STARTING,
	RUNNING,
	EXPIRED,
	COMPLETED,
	CRASHED,
	CANCELLED,
}

var pid: int = -1
var stdio: FileAccess
var stderr: FileAccess
var stdio_messages: Array[String] = []
var stderr_messages: Array[String] = []
var exit_code: int = -1
var is_done: bool = false
var is_expired: bool = false
var has_errors: bool = false
var has_warnings: bool = false
var timeout: float = 35.0 # seconds
# var _self_reference 
var status: Status
## copy for thread safe without mutex every frame
var _status_internal: Status
var expires_at: int = 0
## you can pass an external mutex
var mutex := Mutex.new()

## do not connect in another thread
signal stdio_emitted(data: String)
## do not connect in another thread
signal stderr_emitted(data: String)
## do not connect in another thread
signal exited(code: int)

func _init() -> void:
	status = Status.READY
	is_done = false

func set_status(p_status: Status):
	mutex.lock()
	status = p_status
	mutex.unlock()
	_status_internal = p_status

func get_status() -> Status:
	var status_copy: Status
	mutex.lock()
	status_copy = status
	mutex.unlock()
	return status_copy

## runs the [param command] with [param args],
## kills the sub-process if it takes more than [param timeout]
func _run(command: String, args: PackedStringArray = [], p_timeout: float = 35.0) -> void:
	#_self_reference = self # for avoiding garbage collection
	timeout = p_timeout
	expires_at = Time.get_unix_time_from_system() + timeout

	var process_info: Dictionary = OS.execute_with_pipe(command, args, false)
	# could be freed during execute launch...
	#if _self_reference == null:
	#	return
	if process_info.is_empty():
		set_status(Status.CRASHED)
		return
	mutex.lock()
	pid = process_info.get("pid")
	stdio = process_info.get("stdio")
	stderr = process_info.get("stderr")
	set_process.call_deferred(true)
	mutex.unlock()
	set_status(Status.RUNNING)

func _process(delta: float) -> void:
	if _status_internal == Status.CANCELLED:
		set_process(false)
		return
	if _status_internal == Status.RUNNING:
		if OS.is_process_running(pid) and Time.get_unix_time_from_system() < expires_at:
			read_stdio(stdio)
			read_stderr(stderr)
		else:
			# done
			if OS.is_process_running(pid):
				# is over but still running
				read_stdio(stdio)
				read_stderr(stderr)
				stdio.close()
				stderr.close()
			if Time.get_unix_time_from_system() >= expires_at:
				is_expired = true
				set_status(Status.EXPIRED)
			else:
				set_status(Status.COMPLETED)
			terminate()

## internal method to read the stdio buffer
func read_stdio(stdio: FileAccess) -> void:
	if stdio and stdio.is_open() and stdio.get_length() > 0:
		#var text = stdio.get_line()
		var text = stdio.get_buffer(stdio.get_length()).get_string_from_utf8()
		#stdio_emitted.emit(text)#.replace("\r", "").replace("\n", ""))
		stdio_messages.append(text)

## internal method to read the stderr buffer
func read_stderr(stderr: FileAccess) -> void:
	if stderr and stderr.is_open() and stderr.get_length() > 0:
		#var text = stderr.get_line()
		var text = stderr.get_buffer(stderr.get_length()).get_string_from_utf8()
		#stderr_emitted.emit(text)#.replace("\r", "").replace("\n", ""))
		if (
			text.begins_with("WARNING:")
			or text.contains("push_warning")
			or (has_warnings and text.contains("GDScript backtrace"))
		):
			has_warnings = true
		else:
			has_errors = true
		stderr_messages.append(text)

## terminate the sub-process
func terminate() -> void:
	mutex.lock()
	set_process(false)
	is_done = true
	exit_code = OS.get_process_exit_code(pid)
	#_self_reference = null
	mutex.unlock()
	OS.kill(pid)
	exited.emit.call_deferred(exit_code)

## OVERRIDE ensures that [method terminate] is called
## before freeing this [class Object]
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		set_status(Status.CANCELLED)
		terminate()
		if OS.is_process_running(pid):
			await exited
