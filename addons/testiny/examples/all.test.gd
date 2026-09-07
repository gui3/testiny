extends Testiny.TestSuite

func it_should_succeed():
	var a = 1 + 1
	assert(a == 2) # you can use godot assertions

func it_should_be_warning():
	push_warning("Eror humanum est") # you can push_warning

func it_should_fail():
	push_error("hello from crash test")

func it_should_crash():
	OS.crash("hello from Testinys") # if your test crashes the engine

func it_works_with_expect():
	expect("siblings").to_equal("siblings")
	expect(5).NOT.to_be_less_than(5) # greater or equal
	expect(12).to_be_of_type("int")
	expect(self).to_be_of_class("HBoxContainer") # FAIL
