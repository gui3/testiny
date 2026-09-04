extends Testiny.TestSuite

func setup() -> void:
	is_graphics_on = false
	timeout = 15.0

func it_should_succeed():
	print("should success")
	for i in range(15000):
		print("hello")

func it_should_fail():
	print("should fail")
	push_error("Eror humanum est") # you can just push_error 
	await OS.delay_msec(1000)
	printerr("pouet")

func it_should_crash():
	print("should crash")
	var a = []
	return a[5] # if the engine crashes (godot error)

func it_works_with_expect():
	expect("siblings").to_equal("siblings")
	expect(5).NOT.to_be_less_than(5) # greater or equal
	expect(12).to_be_of_type("int")
	expect(self).to_be_of_class("HBoxContainer") # FAIL
