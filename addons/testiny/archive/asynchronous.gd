extends RefCounted
## namespace Asynchronous

## class Promise,
## takes a sync or async function
## and runs it in async fashion.
## Emits [signal ended] when over,
## you can also chain with [method then]
## [br][br]
##
## use it with the [class Outcome] parameter
## [codeblock]
## var promise: Promise = Promise.new(func(outcome: Outcome):
##     # your logic here
##     outcome.succeed(some_data)
##     # or outcome.fail(message, code)
## )
## promise.ended.connect(func(err_code: Error, data: Variant):
##     # handling the end
## )
## promise.start()
## [/codeblock]
## 
## !! if you call [method succeed] or [method fail] multiple times,
## the promise will resolve multiple times
class Promise:
	extends RefCounted
	
	signal _started()
	signal _succeeded(data: Variant)
	signal _failed(code: Error, data: Variant)
	signal _finished(code: Error, data: Variant)

	## If set to true, will not push_errors on [method fail]
	var silent_errors: bool = false
	var error_code: Error = -1
	
	var _action: Callable
	var _chain_before: Promise
	var _is_running: bool = false
	var _is_finished: bool = false
	var _is_failed: bool = false
	var _result: Variant
	var _self_reference: RefCounted
	var _outcome: Outcome
	#var _action_then: Callable

	func _init() -> void:
		_started.connect(_run)
	
	func set_action(action: Callable) -> Promise:
		if action.get_argument_count() != 1:
			_end(FAILED, "Promise action should take an [outcome] argument")
			return
		_action = action
		return self
	
	## Creates a promise and sets its action in one go.
	static func create(action: Callable) -> Promise:
		return Promise.new().set_action(action)
	
	## Creates a Promise that runs immediately
	static func autostart(action: Callable) -> Promise:
		var promise: Promise = Promise.new()
		promise.set_action(action)
		promise.start()
		return promise
		
	func start() -> Promise:
		if _is_running:
			push_error("trying to start Promise that is already running'")
			return self
		_self_reference = self # needed for stopping garbage collection
		# https://github.com/godotengine/godot/issues/65884
		_is_running = true
		_outcome = Outcome.new()
		_outcome._finished.connect(_end)
		_started.emit()
		return self
	
	## (async) returns the result
	func obtaining() -> Variant:
		# result
		if not _is_finished:
			await _finished
		if _is_failed:
			return null
		return _result
	
	func then(action: Callable) -> Promise:
		if action.get_argument_count() != 1:
			_end(FAILED, "Promise chaining action should take a [data] argument")
			return
		
		var promise_then: Promise = Promise.new()
		_succeeded.connect(func(data):
			promise_then.set_action(func(outcome):
				var data_then: Variant = await action.call(data)
				outcome.succeed(data_then)
			).start()
		)
		return promise_then

	func _end(code: Error, data: Variant) -> void:
		error_code = code
		if code != OK:
			_is_failed = true
			if not silent_errors:
				push_error(data)
			_failed.emit(code, data)
		else:
			_result = data
			_succeeded.emit(data)
		_finished.emit(code, data)
		_is_finished = true
		_is_running = false
		_self_reference = null
		_outcome = null

	func _run() -> void:
		await _action.call(_outcome)
		if not _is_finished:
			_outcome.fail("no call to outcome.suceed() or outcome.fail() in Promise")

class Outcome:
	extends RefCounted
	
	signal _finished(code: Error, data: Variant)
	
	func succeed(data: Variant) -> void:
		_finished.emit(OK, data)
	
	func fail(message: String, code: Error = FAILED) -> void:
		_finished.emit(code, message)
