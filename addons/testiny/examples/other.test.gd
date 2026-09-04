extends Testiny.TestSuite

func setup() -> void:
	is_graphics_on = false
	timeout = 15.0

func it_should_succeed():
	print("should success")
	for i in range(2):
		print("hello")
