#!bundle:class_is_abstract
@abstract #!bundle:remove
extends Object
class_name ___Testiny_Constant
## this "namespace" holds app's internal constants

enum Status {
	# bits mean approx.: (not done)(bad news)(couldn't end)(couldn't run)
	OK             = 0b0000,
	FILE_NOT_FOUND = 0b0001,
	CANCELLED      = 0b0010,
	IGNORED        = 0b0011,
	FAILED         = 0b0100,
	CRITICAL       = 0b0101,
	EXPIRED        = 0b0110,
	DONE           = 0b0111, # inverse mask (mask | code) == mask
	
	NOT_DONE       = 0b1000, # mask         (mask & code) != 0
	INIT           = 0b1001,
	READY          = 0b1010,
	RUNNING        = 0b1011,
}
const status_string: Dictionary[int, String] = {
	Status.OK: "OK", Status.FAILED: "FAILED", Status.EXPIRED: "EXPIRED",
	Status.CANCELLED: "CANCELLED", Status.CRITICAL: "CRITICAL", Status.DONE: "DONE",
	Status.NOT_DONE: "NOT_DONE", Status.INIT: "INIT", Status.RUNNING: "RUNNING",
	Status.READY: "READY", Status.FILE_NOT_FOUND: "FILE_NOT_FOUND"
}

static func check_is_done(status: Status) -> bool:
	return (Status.DONE | status) == Status.DONE

static func check_is_not_done(status: Status) -> bool:
	return (Status.NOT_DONE & status) != 0
