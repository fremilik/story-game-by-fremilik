extends Node2D


#const plBomb = preload("res://Scene/objects/bomb.tscn")
#const plGoblin = preload("res://Scene/goblin.tscn")
#
#const Map: Dictionary = {
	#1: preload("res://Scene/Level/map_1.tscn"),
	#2: preload("res://Scene/Level/map_2.tscn"),
	#3: preload("res://Scene/Level/map_3.tscn"),
	#4: preload("res://Scene/Level/map_4.tscn")
#}

#const NEXT_MAP_TILE_POS: Array[Vector2i] = [Vector2i(160, -8)]


func _ready() -> void:
	pass



func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_2") and OS.is_debug_build():
		#var bomb = plBomb.instantiate()
		#bomb.position = Vector2(0, -200)
		#get_tree().current_scene.add_child.call_deferred(bomb)
		#
		#var goblin = plGoblin.instantiate()
		#goblin.position = Vector2(630, -270)
		#get_tree().current_scene.add_child.call_deferred(goblin)
		
		get_tree().reload_current_scene()
		
		
