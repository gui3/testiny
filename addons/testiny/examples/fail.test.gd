extends Testiny.TestSuite

func it_should_succeed():
	print("should success")
	var a = 1 + 1
	assert(a == 2) # you can use godot assertions

func it_should_fail():
	print("should fail")
	push_error("hello from crash test") # if the engine crashes (godot error)
