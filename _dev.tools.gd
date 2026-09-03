@tool
extends Node

const Bundle := preload("./_bundle.tool.gd")
var TestinyBundle: Resource

func _init() -> void:
	var bundle_path = ProjectSettings.globalize_path(
		"res://addons/testiny/testiny.bundle.gd"
	)
	if DirAccess.dir_exists_absolute(bundle_path):
		TestinyBundle = load(bundle_path)

@export_tool_button("Bundle", "BoxMesh")
var action_bundle = bundle
func bundle():
	Bundle.new()._run()

@export_tool_button("Test", "Debug")
var action_test = test
func test():
	if TestinyBundle:
		await TestinyBundle.run()
	else:
		OS.alert("no bundle found, bundle first")
