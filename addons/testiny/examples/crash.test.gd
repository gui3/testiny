extends Testiny.TestSuite

func it_should_crash():
	print("should crash")
	OS.crash("hello from Testinys")
