extends "./phase.gd"
## represents a test case (method it_)
## in the phase tree

const SubProcess = preload("./sub_process.gd")

var sub_process: SubProcess
var suite_path: String
var method_name: String

func _init(
	p_description: String,
	p_config: Config,
	p_suite_path: String,
	p_method_name: String
) -> void:
	super(p_description, p_config)
	suite_path = p_suite_path
	method_name = p_method_name
	set_status(Constant.Status.READY)

func _load() -> void: pass

func _run():
	is_done = false
	recorder.info("Running %s" % [method_name])
	set_status(Constant.Status.RUNNING)
	sub_process = SubProcess.new()
	#sub_process.stdio_emitted.connect(func(data): print("[stdio] %s" % data))
	#sub_process.stderr_emitted.connect(func(data): print("[stderr] %s" % data))
	#sub_process.exited.connect(func(code): print("[exited] %s" % code))
	sub_process.stdio_emitted.connect(recorder.info)
	sub_process.stderr_emitted.connect(recorder.error)
	sub_process.exited.connect(on_sub_process_exit)
	sub_process.timeout = 5.0
	
	var cli_args: Array[String] = [
		"--headless" if not config.is_graphics_on else "",
		"--script", suite_path,
		"--",
		method_name
	]
	recorder.verbose("starting sub-process")
	sub_process._running(OS.get_executable_path(), cli_args, config)

func on_sub_process_exit(code: int):
	print("exit_code: %s" % code)
	update_status()

func update_status() -> void:
	if not sub_process.is_done:
		set_status(Constant.Status.RUNNING)
		return
	is_done = true
	recorder.verbose("sub-process shoudl have exited (or garbage collection error)")
	recorder.debug("has_errors: %s" % sub_process.has_errors)
	recorder.debug("exit_code: %s" % sub_process.exit_code)
	
	if sub_process.exit_code == 0:
		if sub_process.has_errors:
			set_status(Constant.Status.FAILED)
		else:
			set_status(Constant.Status.OK)
	elif sub_process.is_expired == true:
		recorder.warning("timeout reached!")
		set_status(Constant.Status.EXPIRED)
	else:
		set_status(Constant.Status.CRASHED)
	ended.emit()
