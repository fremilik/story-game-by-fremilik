extends Area2D

var bodiesInArea: Array
var damageActive: bool = false

func damage_body() -> void:
	if not bodiesInArea.is_empty():
		damageActive = true
		for body in bodiesInArea:
			body.damage(1.5)
		await get_tree().create_timer(1.0).timeout
		damage_body()
	else:
		damageActive = false
	


func _on_body_entered(body: Node2D) -> void:
	bodiesInArea.append(body)
	if not damageActive: damage_body()


func _on_body_exited(body: Node2D) -> void:
	bodiesInArea.erase(body)
