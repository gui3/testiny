# Testiny
> foresee bugs and crashes!

Testiny is (another) unit testing utility for Godot.
It focuses on simplicity and comfort of use.

See images for a look at the interface and an example test suite.

## features
- captures and differentiate warnings (push_warning), failures (push_error, printerr) and engine crashes.
- features a (yet) minimal "expect" tool.
- file exploration: put your tests in a separate folder or beside your code,
  Testiny will find them!
- simple: extend Testiny.TestSuite, write methods starting with "it_" and you're up and going!
- friendly: follow your run's progression with a percentage and a count of each test-case's status.
- friendly 2: navigate your tests in a tree, and see only logs from the test-cases that you need.
- fast: if your machine follows, run all test-cases at once (adapt the timeout).
- feedback: you can turn on "graphics" mode and see the test run as a game.
- isolated tests: each test case (method) runs inside its own sub-process, with a fresh godot instance.
- threaded: loading and launching happens in threads, so your editor doesn't freeze.
- fluid: multiple state-machine patterns take advantage of the Godot processing power,
  allowing fluid navigation and ui updates
- safe: threads and sub-processes are carefully secured with mutexes and timeouts.

- @SOON_TO_COME: run fucntionnal scenarios on a full scene. 
  (in theory this should alreay work, but needs more testing)

## disclaimers
I tried GUT a long time ago, I didn't even try GdUnitTest.
I made this addon as I wish it would be, without reference,
but (I admit) a little guidelines from AI as a quick (and often wrong) documenting tool.
