## namespace Codes
@abstract extends Object

enum Status {
	OK        = 0b0000,
	FAILED    = 0b0001,
	EXPIRED   = 0b0010,
	CANCELLED = 0b0011,
	DONE      = 0b0111, # inverse mask (mask | code) == mask
	
	NOT_DONE  = 0b1000, # mask         (mask & code) != 0
	INIT      = 0b1001,
	RUNNING   = 0b1010,
}

static var status_string: Dictionary[int, String] = {
	Status.OK: "OK", Status.FAILED: "FAILED", Status.EXPIRED: "EXPIRED",
	Status.CANCELLED: "CANCELLED", Status.DONE: "DONE",
	Status.NOT_DONE: "NOT_DONE", Status.INIT: "INIT", Status.RUNNING: "RUNNING",
}
