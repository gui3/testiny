@abstract
extends Object
## this "namespace" holds app's internal constants

## be carefull when adding statuses
## they need to match with StatusCategory
enum Status {
	# inverse mask (mask | code) == mask
	# mask         (mask & code) != 0
	INIT           = 0b0000,  # icon idle ---
	READY          = 0b0010,  # icon idle
	LOADING        = 0b0110,  # icon waiting
	RUNNING        = 0b0111,  # icon waiting
	OK             = 0b1000,  # icon success --- !
	WARNING        = 0b1001,  # icon warning ---
	IGNORED        = 0b1010,  # icon stop ---
	CANCELLED      = 0b1011,  # icon stop
	FAILED         = 0b1100,  # icon failed  ---
	EXPIRED        = 0b1101,  # icon expired ---
	FILE_NOT_FOUND = 0b1110,  # icon crashed ---
	CRASHED        = 0b1111,  # icon crashed
}
const status_string: Dictionary[int, String] = {
	Status.OK: "OK", Status.FAILED: "FAILED", Status.EXPIRED: "EXPIRED",
	Status.CANCELLED: "CANCELLED", Status.CRASHED: "CRASHED",
	Status.INIT: "INIT", Status.LOADING: "LOADING", Status.RUNNING: "RUNNING",
	Status.READY: "READY", Status.FILE_NOT_FOUND: "FILE_NOT_FOUND",
	Status.WARNING: "WARNING",
}

## !! determines the icon from the status
## using minimum value 
## (be carefull when adding statuses)
enum StatusCategory {
	CRASHED = 0b1110,
	EXPIRED = 0b1101,
	FAILED  = 0b1100,
	STOPPED = 0b1010,
	WARNING = 0b1001,
	OK      = 0b1000,
	WAITING = 0b0100,
	IDLE    = 0b0000,
}

const SatusCategoriesInOrder: Array[StatusCategory] = [
	StatusCategory.CRASHED, StatusCategory.EXPIRED, StatusCategory.FAILED, StatusCategory.STOPPED,
	StatusCategory.WARNING, StatusCategory.OK, StatusCategory.WAITING, StatusCategory.IDLE,
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
	return (0b1000 & status) != 0

static func check_is_not_done(status: Status) -> bool:
	return (0b0111 | status) == 0b0111
