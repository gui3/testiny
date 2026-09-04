extends RefCounted
## it's a logger, but Logger was no available name

const Recorder = preload("./recorder.gd")

enum Level {IMPORTANT, ERROR, WARNING, INFO, VERBOSE, DEBUG}
const level_strings: Dictionary = {
	Level.IMPORTANT: "IMPORTANT", Level.ERROR: "ERROR", Level.WARNING: "WARNING",
	Level.INFO: "INFO", Level.VERBOSE: "VERBOSE", Level.DEBUG: "DEBUG",
}

signal recorded(level: Level, content: Variant, timestamp: float)

var print_level: Level = Level.DEBUG

var levels: Array[Level] = []
var contents: Array[Variant] = []
var timestamps: Array[float] = []

func add(
	level: Level,
	content: Variant,
	timestamp: float = Time.get_unix_time_from_system(),
) -> int:
	levels.append(level)
	contents.append(content)
	timestamps.append(timestamp)
	var index = levels.size() - 1
	recorded.emit(level, content, timestamp)
	print(format(index))
	return index

func get_log(index: int):
	return [
		levels[index],
		contents[index],
		timestamps[index],
	]

func get_snapshot():
	var result: String = ""
	for i in range(levels.size()):
		result += "%s\n" % format(i)
	return result

func filter_level(level: Level) -> Recorder:
	var result := Recorder.new()
	for i in range(levels.size()):
		if levels[i] == level:
			result.add(levels[i], contents[i], timestamps[i])
	return result

func critical(content: Variant) -> int:
	return add(Level.IMPORTANT, content)
	
func error(content: Variant) -> int:
	return add(Level.ERROR, content)
	
func warning(content: Variant) -> int:
	return add(Level.WARNING, content)
	
func info(content: Variant) -> int:
	return add(Level.INFO, content)

func verbose(content: Variant) -> int:
	return add(Level.VERBOSE, content)

func debug(content: Variant) -> int:
	return add(Level.DEBUG, content)

func show_exit_code(code: int) -> int:
	return add(Level.INFO, "[exit code] %s" % code)

func format(index: int) -> String:
	return "%s [%s]\n  %s" % [
		Time.get_datetime_string_from_unix_time(timestamps[index]),
		level_strings[levels[index]],
		str(contents[index])
	]
