extends Testiny.TestSuite

func success_1():
	print("should succeed")
	var a = 1 + 1
	assert(a == 2) # you can use godot assertions

func it_success_2_greater_than_5():
	expect(2).to_be_greater_than(-5)
	
func it_success_hello_contains_he():
	expect("hello").to_contain("he")
	
