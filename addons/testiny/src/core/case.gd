extends "./phase.gd"
## represents a test case (method it_)
## in the phase tree

const SubProcess = preload("./sub_process.gd")

var sub_process: SubProcess
var thread: Thread
var mutex := Mutex.new()

func _init(
	p_description: String,
	p_config: Config,
	p_suite_path: String,
	p_method_name: String
) -> void:
	super(p_description, p_config, p_suite_path, p_method_name)
	set_status(Constant.Status.INIT)

func _load() -> void:
	is_done = false
	if sub_process:
		sub_process.terminate()
		remove_child(sub_process)
	sub_process = SubProcess.new()
	sub_process.mutex = mutex
	add_child(sub_process)
	set_status(Constant.Status.READY)

func _run() -> void:
	recorder.info("Running %s" % [method_name])
	set_status(Constant.Status.RUNNING)
	set_process(true)

func set_status(p_status: Constant.Status) -> void:
	mutex.lock()
	super(p_status)
	mutex.unlock()

func get_status() -> Constant.Status:
	var result: Constant.Status
	mutex.lock()
	result = status
	mutex.unlock()
	return result

func start_sup_process() -> void:
	if sub_process.get_status() != SubProcess.Status.READY:
		return # looping guard
	sub_process.set_status(SubProcess.Status.STARTING)
	set_status(Constant.Status.INIT) # double loop guard
	var cli_args: Array[String] = [
		"--headless" if not config.is_graphics_on else "",
		"--script", suite_path,
		"--",
		method_name
	]
	if thread and thread.is_alive():
		print("aiaiai")
		thread.wait_to_finish()
	thread = Thread.new()
	recorder.verbose("starting sub-process")
	thread.start(sub_process._run.bind(
		OS.get_executable_path(),
		cli_args,
		config.timeout
	), 2)
	set_status(Constant.Status.RUNNING)

func _process(delta: float) -> void:
	if get_status() in [Constant.Status.CANCELLED, Constant.Status.IGNORED]:
		set_process(false)
		is_done = true
		set_status(get_status())
		return
	elif get_status() == Constant.Status.RUNNING:
		var sub_status: SubProcess.Status
		if sub_process:
			# thread safe get_status()
			sub_status = sub_process.get_status()
		if sub_status == SubProcess.Status.READY:
			print("start")
			start_sup_process()
			print("started")
		elif (
			sub_status == SubProcess.Status.EXPIRED
			or sub_status == SubProcess.Status.COMPLETED
			or sub_status == SubProcess.Status.CRASHED
		):
			if not is_done:
				end_sub_process()
		else:
			if int(Time.get_unix_time_from_system()) % config.io_delay == 0:
				thread_get_messages()

func thread_get_messages():
	var stdio_messages: Array[String] = []
	var stderr_messages: Array[String] = []
	mutex.lock()
	stdio_messages.append_array(sub_process.stdio_messages)
	sub_process.stdio_messages.clear()
	stderr_messages.append_array(sub_process.stderr_messages)
	sub_process.stderr_messages.clear()
	mutex.unlock()
	for message in stdio_messages:
		recorder.info(message)
	for message in stderr_messages:
		recorder.error(message)

func end_sub_process():
	set_process(false)
	is_done = true
	set_status(Constant.Status.INIT)
	thread_get_messages()
	update_status()

func update_status() -> void:
	if not is_done:
		set_status(Constant.Status.RUNNING)
		return
	recorder.info("------- end of test logs -------")
	
	var end_status: Constant.Status
	mutex.lock()
	recorder.debug("has_errors: %s" % sub_process.has_errors)
	recorder.debug("exit_code: %s" % sub_process.exit_code)
	if sub_process.exit_code == 0:
		if sub_process.has_errors:
			end_status = Constant.Status.FAILED
		elif sub_process.has_warnings:
			end_status = Constant.Status.WARNING
		else:
			end_status = Constant.Status.OK
	elif sub_process.is_expired == true:
		end_status = Constant.Status.EXPIRED
	else:
		end_status = Constant.Status.CRASHED
	mutex.unlock()
	set_status(end_status)
	ended.emit()

func _notification(what: int) -> void:
	super(what)
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		if thread and thread.is_alive():
			mutex.lock()
			sub_process.terminate()
			mutex.unlock()
			thread.wait_to_finish()
			await get_tree().process_frame
