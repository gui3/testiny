@abstract
extends Object

const PATH_DELIMITER: String = "|"

## walks through [param root_dir]
## and returns a list of file paths mathing [param extension] at the end
static func discover(
	extensions: String = ".test.gd",
	root_dir: String = "res://",
	excludes: String = "/addons/",
) -> Array[String]:
	var files: Array[String] = []
	if not root_dir.ends_with("/"): root_dir += "/"
	for file in DirAccess.get_files_at(root_dir):
		var file_path: String = "%s%s" % [root_dir, file]
		var is_kept: bool = true
		for extension in extensions.split(PATH_DELIMITER):
			if not file_path.match("*%s" % extension):
				is_kept = false
		for exclude in excludes.split(PATH_DELIMITER):
			if exclude.length() > 0 and file_path.match("*%s*" % exclude):
				is_kept = false
		if is_kept:
			files.append(file_path)
	for dir in DirAccess.get_directories_at(root_dir):
		var dir_path: String = "%s%s" % [root_dir, dir]
		var sub_files: Array[String] = discover(extensions, dir_path, excludes)
		files.append_array(sub_files)
	return files
