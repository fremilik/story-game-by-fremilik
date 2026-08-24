extends StaticBody2D

const TILE_SIZE: int = 32


func open_road() -> void:
	var pos: Vector2 = position + Vector2(0, TILE_SIZE * 2)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", pos, 0.75)



func close_road() -> void:
	var pos: Vector2 = position - Vector2(0, TILE_SIZE * 2)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", pos, 0.75)
