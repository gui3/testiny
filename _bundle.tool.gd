@tool
extends EditorScript

# all of this because no namespaces....
# I long for namespace feature ! +1 +1 +1

const config := preload("./bundle.config.gd")
const is_debug: bool = false

# --- common methods

func debug(text: String):
	if is_debug:
		print(text)

static func sanitize_dir_path(path: String) -> String:
	if path.ends_with("/"):
		path = path.substr(0, path.length() - 1)
	return path

static func copy_dir_recursive(
	p_from : String,
	p_to : String,
	ignore: String = "*.uid,*.import"
) -> Array[String]:
	var files_out: Array[String] = []
	var dir = DirAccess.open(p_from)
	if DirAccess.get_open_error() == OK:
		print("[bundle] copying %s\n        -> %s" % [p_from, p_to])
		if not dir.dir_exists(p_to):
			dir.make_dir_recursive(p_to)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			var is_file_ignored: bool = false
			for ignore_match in ignore.split(","):
				is_file_ignored = file_name.match(ignore_match)
			if is_file_ignored:
				print("ignore %s" % file_name)
				continue
			
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					files_out.append_array(
						copy_dir_recursive("%s/%s" %[p_from, file_name], "%s/%s" %[p_to, file_name])
					)
			else:
				print("[bundle] copying %s/%s\n        -> %s/%s" % [p_from, file_name, p_to, file_name])
				dir.copy("%s/%s" %[p_from, file_name], "%s/%s" %[p_to, file_name])
				files_out.append("%s/%s" % [p_to, file_name])
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning("[bundle] ERROR copying %s\n        X> %s" % [p_from, p_to])
	return files_out

# --- Internals

static func run():
	new()._run()

func _run():
	var bundle_dir_abs: String = rel2abs(config.bundle_dir, true)
	if DirAccess.dir_exists_absolute(bundle_dir_abs):
		print("[bundle] moving %s to trash" % bundle_dir_abs)
		OS.move_to_trash(bundle_dir_abs)
	
	print("[bundle] --- copying copy files and dirs")
	var updated_files: Array[String] = []
	for in_out in config.in_out_copy_paths:
		var files_out: Array[String] = bundle_copy(in_out)
		updated_files.append_array(files_out)
	
	print("[bundle] --- bundling script files")
	for in_out in config.in_out_script_paths:
		var files_out: Array[String] = bundle_script(in_out)
		updated_files.append_array(files_out)
	refresh_godot(updated_files)
	
	print("[bundle] --- done")
	for file in updated_files:
		print("    updated: %s" % file)
	print("  old bundle moved into trash if present")
	print("  (don't forget to empty it sometimes)")

func refresh_godot(updated_files: Array[String] = []):
	var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()
	EditorInterface.get_script_editor().reload_open_files()
	if file_system.is_scanning():
		await file_system.filesystem_changed
	if not updated_files.is_empty():
		for file in updated_files:
			file_system.update_file(file)
	if not file_system.is_scanning():
		file_system.scan()
		await file_system.filesystem_changed
	EditorInterface.get_script_editor().reload_scripts()

func bundle_script(in_out: Dictionary) -> Array[String]:
	var files_out: Array[String] =[]
	var abs_path_entrypoint = rel2abs(in_out.in)
	var result: String = parse_script(abs_path_entrypoint)
	if config.is_verbose:
		print_script(result, "result")

	var abs_path_outfile = rel2abs(in_out.out, true)
	DirAccess.make_dir_recursive_absolute(abs_path_outfile.get_base_dir())	
	var file := FileAccess.open(abs_path_outfile, FileAccess.WRITE)
	if FileAccess.get_open_error():
		push_error("[bundle] error %s while writing file %s" % [
			error_string(FileAccess.get_open_error()),
			abs_path_outfile
		])
		return files_out
	file.store_string(result)
	file.close()
	print("[bundle] bundled script saved in %s" % abs_path_outfile)
	return files_out
	
func bundle_copy(in_out: Dictionary) -> Array[String]:
	var files_out: Array[String] =[]
	var global_path_in: String = rel2abs(in_out.in, true)
	if DirAccess.dir_exists_absolute(global_path_in):
		# is a directory
		files_out.append_array(
			copy_dir_recursive(global_path_in, rel2abs(in_out.out, true))
		)
	else:
		# is a file
		var global_path_out: String = rel2abs(in_out.out, true)
		DirAccess.copy_absolute(global_path_in, global_path_out)
		files_out.append(global_path_out)
	return files_out

func rel2abs(relative_path: String, system_absolute: bool = false) -> String:
	if relative_path.begins_with("./"):
		relative_path = relative_path.substr(2)
	if system_absolute:
		var global_path: String = ProjectSettings.globalize_path(rel2abs(relative_path, false))
		print(global_path)
		return global_path
	else:
		var local_path: String = ProjectSettings.localize_path(relative_path)
		print(local_path)
		return local_path

func load_string_as_instance(code: String) -> Object:
	var script = GDScript.new()
	script.source_code = code
	var err = script.reload()
	if err != OK:
		push_error("[bundle] error Malformed script: %s" % error_string(err))
		return null
	return script

func print_script(content: String, title: String = "?????")-> void:
	print("-------- %s" % title)
	print(content)
	print("----------------------------------")

func parse_script(abs_path: String, already_included: Array[String] = []) -> String:
	if config.is_verbose:
		print("[parsing] %s" % abs_path)
	if already_included.has(abs_path):
		var err_text: String = "ignored circular reference to %s" % abs_path
		push_warning("[warning] %s" % err_text)
		return "#!bundle:error %s" % err_text
	already_included.append(abs_path)
	var script_text: String = read_script(abs_path)
	if config.is_verbose:
		print_script(script_text, "BEFORE bundling %s" % abs_path)
	# WARNING calls include_script recursively
	script_text = do_commands(script_text, already_included)
	script_text = do_hard_replacements(script_text)
	if config.is_verbose:
		print_script(script_text, "AFTER bundling %s" % abs_path)
	return script_text

func read_script(absolute_path: String) -> String:
	if config.is_verbose:
		print("[reading] %s" % absolute_path)
	var script_text = FileAccess.get_file_as_string(absolute_path)
	var err = FileAccess.get_open_error()
	if config.is_verbose:
		print("[read file exit code] %s" % error_string(err))
	return script_text

func do_hard_replacements(origin_text: String) -> String:
	var result_text: String = origin_text
	for key in config.hard_replacements:
		if config.is_verbose:
			print("[replacing] \"%s\" by \"%s\"" % [key, config.hard_replacements[key]])
		result_text = result_text.replace(key, config.hard_replacements[key])
	return result_text

func do_commands(origin_text: String, already_included: Array[String] = []) -> String:
	var result_lines: Array[String] = []
	for line in origin_text.split("\n"):
		if line.contains("#!bundle:"):
			if config.is_verbose:
				print("[bundle command] %s" % line)
			if line.contains("#!bundle:remove"):
				continue # don't keep
			if line.contains("#!bundle:add "):
				# add the rest of the line to the line
				result_lines.append(line.replace("#!bundle:add ", ""))
			if line.contains("#!bundle:import "):
				var indent: String = line.split("#!bundle:import ")[0]
				var subpath: String = rel2abs(line.split("#!bundle:import ")[1])
				if not FileAccess.file_exists(subpath):
					printerr("file %s does not exist" % subpath)
					return "[Bundle error] #!bundle:include %s" % subpath
				var subscript: String = parse_script(subpath, already_included)
				subscript = script2class(subscript, indent)
				for sub_line in subscript.split("\n"):
					result_lines.append(sub_line)
			else:
				result_lines.append(line)
		else:
			result_lines.append(line)
	return "\n".join(result_lines)

func script2class(script: String, indent: String) -> String:
	if config.is_verbose:
		print("[bundling script into class]")
	var result_lines: Array[String] = []
	var classname: String
	var is_abstract: bool = false
	for line in script.split("\n"):
		if line.contains("#!bundle:class_is_abstract"):
			is_abstract = true
			line = line.replace("#!bundle:class_is_abstract", "")
		if line.replace("\t", "").begins_with("class_name") and not classname:
			var class_words = line.replace("\t", "").replace("class_name", "").split(" ", false)
			classname = class_words[0]
		else:
			line = "\t%s%s" % [indent, line]
			result_lines.append(line)
	if not classname:
		var err_text = "ignored file without class_name!!!"
		printerr("[error] %s" % err_text)
		return "#!bundle:error %s" % err_text
	var inner_script: String = "\n".join(result_lines)
	var abstract_symbol = "@abstract " if is_abstract else ""
	return """
%sclass %s:
%s
""" % [abstract_symbol, classname, inner_script]
