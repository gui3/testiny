@tool
extends Node

@export_tool_button("Test", "Debug")
var action_test = test
func test():
	if Testiny:
		await Testiny.new().run()
	else:
		OS.alert("no bundle found, bundle first")
