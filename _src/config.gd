extends RefCounted
class_name ___Testiny_Config

## glob for test discovery
var test_suite_match: String = "*.test.gd"
## root path for test discovery
var test_suite_root_path: String = "res://"
## beginning of method names considered as tests
var method_is_test_match: String = "it_*"
## if true, show godot interface for each test
var is_graphics_on: bool = false
## if true, run all tests simultaneously (asynchronously)
var is_all_at_once: bool = false
