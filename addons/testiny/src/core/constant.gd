@abstract
extends Object
## this "namespace" holds app's internal constants

## be carefull when adding statuses
## they need to match with StatusCategory
enum Status {
	# inverse mask (mask | code) == mask
	# mask         (mask & code) != 0
	
	# bits mean approx.: (bad news)(couldn't run)(couldn't end)(is'nt over/arbitrary)
	OK             = 0b0000,  # icon success ---
	CANCELLED      = 0b0010,  # icon stop    ---
	IGNORED        = 0b0011,  # icon stop
	INIT           = 0b0100,  # icon idle
	READY          = 0b0101,  # icon idle
	RUNNING        = 0b0111,  # icon waiting ---
	FAILED         = 0b1000,  # icon failed  ---
	EXPIRED        = 0b1010,  # icon failed
	FILE_NOT_FOUND = 0b1100,  # icon crashed ---
	CRASHED        = 0b1110,  # icon crashed
}
const status_string: Dictionary[int, String] = {
	Status.OK: "OK", Status.FAILED: "FAILED", Status.EXPIRED: "EXPIRED",
	Status.CANCELLED: "CANCELLED", Status.CRASHED: "CRASHED",
	Status.INIT: "INIT", Status.RUNNING: "RUNNING",
	Status.READY: "READY", Status.FILE_NOT_FOUND: "FILE_NOT_FOUND"
}

## !! determines the icon from the status
## using minimum value 
## (be carefull when adding statuses)
enum StatusCategory {
	CRASHED = 0b1100,
	FAILED  = 0b1000,
	WAITING = 0b0111,
	IDLE    = 0b0100,
	STOPPED = 0b0010,
	OK = 0b0000
}

const SatusCategoriesInOrder: Array[StatusCategory] = [
	StatusCategory.CRASHED, StatusCategory.FAILED, StatusCategory.WAITING,
	StatusCategory.IDLE, StatusCategory.STOPPED, StatusCategory.OK
]

## get the icon code for status
static func get_category(status: Status) -> StatusCategory:
	var result: StatusCategory = StatusCategory.IDLE # by default @TODO make "?" icon
	for category in SatusCategoriesInOrder:
		if status >= category:
			result = category
			break
	return result

static func check_is_done(status: Status) -> bool:
	return (0b0111 | status) == 0b0111

static func check_is_not_done(status: Status) -> bool:
	return (0b1000 & status) != 0
