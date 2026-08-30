@tool extends Testiny.TestSuite

func setup() -> void:
	is_headless = true

func it_should_succeed():
	print("succeed tutut")
	var a = 1 + 1
	assert(a == 2)

func it_should_fail():
	print("fail pouet pouet")
	assert(1 == 4)

func it_should_crash():
	print("crash tut tut")
	OS.crash("coucou")
