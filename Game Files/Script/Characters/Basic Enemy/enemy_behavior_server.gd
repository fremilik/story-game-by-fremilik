extends Node
class_name EnemyBehavior


enum BehaviorStates {IDLE, ALERT, CHASE, ATTACK}

func _ready() -> void:
	print(get_tree().get_nodes_in_group("Enemy"))
	
