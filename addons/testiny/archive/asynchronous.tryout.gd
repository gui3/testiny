@tool
extends EditorScript

const Asynchronous := preload("./asynchronous.gd")

## runs all other methods
func _run():
	for method: Callable in [
		check_timer,
		check_promise_async,
	]:
		print("--- %s" % method.get_method())
		await method.call()

func check_timer():
	return await (Engine.get_main_loop() as SceneTree).create_timer(2.0).timeout

func check_promise_async():
	print("before promise")
	var promise: Asynchronous.Promise = Asynchronous.Promise.autostart(func(outcome):
		print("before timeout")
		await (Engine.get_main_loop() as SceneTree).create_timer(2.0).timeout
		outcome.succeed("after timeout")
	)
	print("after promise : %s" % await promise.obtaining())
