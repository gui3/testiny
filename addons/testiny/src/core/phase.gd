@abstract
extends Node
## (Interface) Symbolizes a node in the test tree

const Config = preload("./config.gd")
const Constant = preload("./constant.gd")
const Recorder = preload("./recorder.gd")

signal status_updated(status: Constant.Status)
signal loaded()
signal ended()
signal cancelled()

var description: String
var config: Config = Config.new()
var recorder: Recorder
var status: Constant.Status = Constant.Status.INIT
var is_done: bool = false
var is_cancelled: bool = false

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

func set_status(p_status: Constant.Status) -> void:
	status  = p_status
	status_updated.emit(status)

func disconnect_all() -> void:
	for signal_dict in get_signal_list():
		for connection in get_signal_connection_list(signal_dict.get("name")):
			if signal_dict.get("callable") is Callable:
				disconnect(signal_dict.get("name"), signal_dict.get("callable"))

func _cancel() -> void:
	if is_cancelled:
		return
	is_cancelled = true
	set_status(Constant.Status.CANCELLED)
	await get_tree().process_frame
	set_process(false)
	for child in get_children():
		if child.has_method("_cancel"):
			await child._cancel()
	disconnect_all()
	cancelled.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		await _cancel()
