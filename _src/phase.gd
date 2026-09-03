#!bundle:class_is_abstract
@abstract #!bundle:remove
extends RefCounted
class_name ___Testiny_Phase
## (Interface) Symbolizes a node in the test tree

var description: String
var config: ___Testiny_Config
var recorder: ___Testiny_Recorder
var status: ___Testiny_Constant.Status = ___Testiny_Constant.Status.INIT

func _init(
	p_description: String,
	p_config: ___Testiny_Config,
) -> void:
	recorder = ___Testiny_Recorder.new()
	description = p_description
	config = p_config

@abstract func _run();
@abstract func _load();
