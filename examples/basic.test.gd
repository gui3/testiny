extends ___Testiny_TestSuite

func setup() -> void:
	is_graphics_on = true

func it_should_succeed():
	var a = 1 + 1
	assert(a == 2) # you can use godot assertions

func it_should_fail():
	push_error("Eror humanum est") # you can just push_error 

func it_should_crash():
	print("crash tut tut")
	OS.crash("coucou") # if the engine crashes (godot error)

func it_works_with_expect():
	expect("siblings").to_equal("siblings")
	expect(5).NOT.to_be_less_than(5) # greater or equal
	expect(12).to_be_of_type("int")
	expect(self).to_be_of_class("HBoxContainer") # FAIL
