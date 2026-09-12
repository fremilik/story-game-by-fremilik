@tool extends EditorScript

var a_text: String = "Hello"
var a_text2: String = " World"
var a_number: int
var a_float: float
var a_bool: bool

var an_array: Array = [20, 40, 50]
var a_dictionary: Dictionary = {1: "fahad", 2: "usman", 3: "john"}


func _run() -> void:
	pass
	
	#print(Vector2i(5, 6) > Vector2i(5, 3))
	#print(Vector2i(3, 2).length())
	
	print((Vector2(-309.0, 111.0).dot(Vector2(-437.0, 207.0))))
	print(Vector2(-437.0, 207.0).dot(Vector2(-309.0, 111.0)))
	print(Vector2(-309.0, 111.0).normalized())
	print(Vector2(-437.0, 207.0).normalized())
	print("\n")
	
	var a := Vector2(-309.0, 111.0).direction_to(Vector2(-437.0, 207.0))
	var b := Vector2(-437.0, 207.0).direction_to(Vector2(-309.0, 111.0))
	
	print(a)
	print(b)
	
	print(Vector2.UP.dot(a))
	print(Vector2.UP.dot(b))
	
	
	
