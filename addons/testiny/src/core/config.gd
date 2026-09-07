extends RefCounted

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
## global default for each test case's timeout
var timeout: float = 30.0
## delay (seconds) between fetching messages from sub process
var io_delay: int = 3
