extends Testiny.Test

func it_should_succeed():
	print("succeed tutut")
	var a = 1 + 1
	assert(a == 2)

func it_should_fail():
	print("fail pouet pouet")
	OS.crash("failed")
