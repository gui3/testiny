## class Phase
extends RefCounted

var phase_name: String
var suite_name: String
var method: Callable

func _run():
	await method.call()
