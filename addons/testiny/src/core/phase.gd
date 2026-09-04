@abstract
extends RefCounted
## (Interface) Symbolizes a node in the test tree

const Config = preload("./config.gd")
const Constant = preload("./constant.gd")
const Recorder = preload("./recorder.gd")

signal status_updated(status: Constant.Status)

var description: String
var config: Config = Config.new()
var recorder: Recorder
var status: Constant.Status = Constant.Status.INIT

func _init(
	p_description: String,
	p_config: Config,
) -> void:
	set_status(Constant.Status.INIT)
	recorder = Recorder.new()
	description = p_description
	config = p_config

@abstract func _run() -> void;
@abstract func _load() -> void;
@abstract func waiting_finished() -> void;

func set_status(p_status: Constant.Status):
	status  = p_status
	status_updated.emit(status)
