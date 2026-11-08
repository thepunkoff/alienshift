extends RefCounted
class_name State

var name: String

static var DEFAULT: State = State.create("default")

static func create(n: String) -> State:
	var ret: State = State.new()
	ret.name = n
	return ret;