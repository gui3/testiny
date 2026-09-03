extends RefCounted

# --- Parameters

const Appinfo := preload("./appinfo.gd")

const is_verbose: bool = false
const bundle_dir: String = "res://addons/testiny" # will be moved to trash
# and recreated by in_out operations

# relative paths 
const in_out_script_paths: Array[Dictionary] = Appinfo.include_scripts
const in_out_copy_paths: Array[Dictionary] = Appinfo.copy_files

## see res://appinfo.gd for constants
const hard_replacements: Dictionary[String, String] = {
	"__APP_NAME__": Appinfo.APP_NAME,
	"__APP_VERSION__": Appinfo.APP_VERSION,
	"__APP_CLASS_NAME__": Appinfo.APP_MAIN_CLASS,
	"__APP_BRIEF__": Appinfo.APP_BRIEF,
	# trick for dev classes ___Testiny_Phase and ___Testiny___
	# without godot compiler error everywhere
	Appinfo.APP_DEV_MAIN_CLASS: Appinfo.APP_MAIN_CLASS,
	Appinfo.APP_DEV_CLASS_PREFIX_BUNDLED: Appinfo.APP_CLASS_PREFIX_BUNDLED,
	Appinfo.APP_DEV_CLASS_PREFIX_COPIED: Appinfo.APP_CLASS_PREFIX_COPIED,
}
