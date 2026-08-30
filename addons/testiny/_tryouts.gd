@tool
extends EditorScript

func _run():
	await check_subprocess()

# ---

const SubProcess := preload("./src/sub_process.gd")
func check_subprocess():
	var sub = SubProcess.new()
	sub.stdio_emitted.connect(func(data): print("[stdio] %s" % data))
	sub.stderr_emitted.connect(func(data): print("[stderr] %s" % data))
	sub.exited.connect(func(code): print("[exited] %s" % code))
	sub.timeout = 12.0
	print("start")
	sub._run("sleep", ["5"])
	print("has_errors: %s" % sub.has_errors)
	print("end, code: %s" % sub.exit_code)

# ---

func it_should_succeed():
	print("succeed tutut")
	var a = 1 + 1
	assert(a == 2)

func it_should_fail():
	print("fail pouet pouet")
	#assert(1 == 4, "attention un grizzly")
	var array = []
	print("array", array[3])

func it_should_accept_arguments(a1: String, a2: int):
	print("arguments %s %s" % [a1, a2])

# ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("💥 L'instance de test a été détruite par le Garbage Collector !")
