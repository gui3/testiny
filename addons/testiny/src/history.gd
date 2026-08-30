## class History,
## it's a logger, but Logger was no available name
extends RefCounted

enum Level {ERROR, WARNING, INFO, DEBUG}
var level_strings: Dictionary = {
	Level.ERROR: "ERROR", Level.WARNING: "WARING",
	Level.INFO: "INFO", Level.DEBUG: "DEBUG"
}

var levels: Array[Level] = []
var contents: Array[Variant] = []
var timestamps: Array[float] = []

var print_level: Level = Level.INFO

func add(
	level: Level,
	content: Variant,
	timestamp: float = Time.get_unix_time_from_system(),
) -> int:
	var index = levels.size()
	levels.append(level)
	contents.append(content)
	timestamps.append(timestamp)
	if level <= print_level:
		print(format(index))
	return index

func error(content: Variant) -> int:
	return add(Level.ERROR, content)
	
func warning(content: Variant) -> int:
	return add(Level.WARNING, content)
	
func info(content: Variant) -> int:
	return add(Level.INFO, content)

func debug(content: Variant) -> int:
	return add(Level.DEBUG, content)

func format(index: int) -> String:
	return "%s [%s] %s" % [
		Time.get_datetime_string_from_unix_time(timestamps[index]),
		level_strings[levels[index]],
		str(contents[index])
	]
