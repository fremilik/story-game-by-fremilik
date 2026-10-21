extends Node

enum BehaviorStates {IDLE, ALERT, CHASE, ATTACK}
enum ImpressionStates {PLAYER_NOT_FOUND, PLAYER_FOUND, ALERT_FINISHED}

var idleAreas: Array[Rect2]


func _ready() -> void:
	print(get_tree().get_nodes_in_group("Enemy"))
	
	idleAreas.append(Rect2(Vector2(-870, 103), Vector2(1180, 210)))
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.enemyIdleArea = idleAreas[0]
	
	


func enemy_call(enemy: CharacterBody2D, action: ImpressionStates) -> void:
	assert(enemy.currentBehaviorState is BehaviorStates)
	match action:
		ImpressionStates.PLAYER_NOT_FOUND:
			enemy.currentBehaviorState = BehaviorStates.IDLE
		ImpressionStates.PLAYER_FOUND:
			enemy.currentBehaviorState = BehaviorStates.CHASE
		
