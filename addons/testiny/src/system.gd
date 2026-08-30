## namespace System
@abstract extends Object

## walks through [param root_dir]
## and returns a list of file paths mathing [param extension] at the end
static func discover(extension: String = ".test.gd", root_dir: String = "res://") -> Array[String]:
	var files: Array[String] = []
	if not root_dir.ends_with("/"): root_dir += "/"
	for file in DirAccess.get_files_at(root_dir):
		if file.ends_with(extension):
			var file_path: String = "%s%s" % [root_dir, file]
			print("found %s" % file_path)
			files.append(file_path)
	for dir in DirAccess.get_directories_at(root_dir):
		var dir_path: String = "%s%s" % [root_dir, dir]
		var sub_files: Array[String] = discover(extension, dir_path)
		files.append_array(sub_files)
	return files
