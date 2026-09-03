@abstract extends RefCounted
## constants that will be injected in the app by the bundler

# see res://bundle.config.gd for replacements
const APP_NAME: String = "Testiny"
const APP_VERSION: String = "0.1.11"
const APP_DEV_MAIN_CLASS: String = "___TESTINY_MAIN___"
const APP_MAIN_CLASS: String = "Testiny"
const APP_DEV_CLASS_PREFIX_BUNDLED: String = "class_name ___Testiny_"
const APP_CLASS_PREFIX_BUNDLED: String = "class_name "
const APP_DEV_CLASS_PREFIX_COPIED: String = "___Testiny_"
const APP_CLASS_PREFIX_COPIED: String = "Testiny."
const APP_BRIEF: String = "Foresee bugs and crashes!"

# relative paths 
const include_scripts: Array[Dictionary] = [
	{"in":"./testiny.bundle.gd", "out": "./addons/testiny/testiny.bundle.gd"},
	{"in":"./testiny.ui.gd", "out": "./addons/testiny/testiny.ui.gd"},
	{"in":"./testiny.ui.tscn", "out": "./addons/testiny/testiny.ui.tscn"},
	{"in":"./testiny.plugin.gd", "out": "./addons/testiny/testiny.plugin.gd"},
	{"in":"./plugin.cfg", "out": "./addons/testiny/plugin.cfg"},
	{"in":"./examples/basic.test.gd", "out": "./addons/testiny/examples/basic.test.gd"},
]
const copy_files: Array[Dictionary] = [
	{"in":"./doc", "out": "./addons/testiny/doc"},
	{"in":"./art", "out": "./addons/testiny/art"},
]




static func comment(
	text: String, 
	prefix: String = "## ", 
	ignore_first: bool = true
) -> String:
	var result_lines = []
	for line in text:
		if ignore_first == true:
			result_lines.append(line)
			ignore_first = false
			continue
		result_lines.append("%s%s" %[prefix, line])
	return "\n".join(result_lines)
