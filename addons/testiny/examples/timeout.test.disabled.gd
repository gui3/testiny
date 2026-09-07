extends Testiny.TestSuite

func setup() -> void:
	timeout = 5.0

func it_should_succeed():
	print("should success")
	await create_timer(100).timeout
