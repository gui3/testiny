extends "./phase.gd"
## represents a test case (method it_)
## in the phase tree

const SubProcess = preload("./sub_process.gd")

var sub_process: Testiny.SubProcess
var suite_path: String
var method_name: String
var is_done: bool

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
	sub_process.exited.connect(recorder.show_exit_code)
	sub_process.timeout = 5.0
	
	var cli_args: Array[String] = [
		"--headless" if not config.is_graphics_on else "",
		"--script", suite_path,
		"--",
		#___Testiny_TestSuite.CLI_SUB_PROCESS_DETECTION_ARGUMENT,
		method_name
	]
	recorder.verbose("starting sub-process")
	await sub_process._running(OS.get_executable_path(), cli_args, config)
	recorder.verbose("sub-process shoudl have exited (or garbage collection error)")
	recorder.debug("has_errors: %s" % sub_process.has_errors)
	recorder.debug("exit_code: %s" % sub_process.exit_code)
	is_done = true
	updating_status()

## (async)
func waiting_finished() -> void:
	if not is_done:
		await sub_process.waiting_exit()
	return

## (async)
func updating_status() -> void:
	await waiting_finished()
	if sub_process.exit_code == 0:
		if sub_process.has_errors:
			set_status(Constant.Status.FAILED)
			return
		set_status(Constant.Status.OK)
		return
	if sub_process.is_expired == true:
		recorder.warning("timeout reached!")
		set_status(Constant.Status.EXPIRED)
		return
	set_status(Constant.Status.CRASHED)
	return
