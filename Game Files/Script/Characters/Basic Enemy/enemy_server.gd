extends Node

const ENEMY_TYPES: Array[String] =  ["Goblin"]

const ENEMY_SCENE: Dictionary[String, PackedScene] = {
	"Goblin": preload("res://Scene/characters/goblin_enemy.tscn"),
}

const MAX_ACTIVE_ENEMIES: int = 12
const MAX_ENEMIES_ON_PLAYER: int = 3
const SPAWN_COOLDOWN_TIME: float = 30

enum BehaviorStates {IDLE, ALERT, CHASE, ATTACK}
enum ImpressionStates {PLAYER_NOT_FOUND, PLAYER_FOUND, ALERT_FINISHED, PLAYER_IN_ATTACK_RANGE, AM_DEAD}

var idleAreas: Array[Rect2]
var spawnAreas: PackedVector2Array = [Vector2(-774, 120), Vector2(243, 126), Vector2(-234, -136), Vector2(262, -147),
Vector2(-828, -120), Vector2(-530, -270)]

var activeEnemies: Dictionary[StringName, Array]
var hasCooldownElasped: bool = true

var enemiesChasingPlayer: Array[AbstractEnemy]
var enemiesAttackingPlayer: Array[AbstractEnemy]


func _ready() -> void:
	print(get_tree().get_nodes_in_group("Enemy"))
	
	idleAreas.append(Rect2(Vector2(-870, 103), Vector2(1180, 210)))
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.enemyIdleArea = idleAreas[0]
	
	for type in ENEMY_TYPES:
		activeEnemies[type] = []


func enemy_call(enemy: AbstractEnemy, action: ImpressionStates) -> void:
	assert(enemy.currentBehaviorState is BehaviorStates)
	match action:
		ImpressionStates.PLAYER_NOT_FOUND:
			enemy.currentBehaviorState = BehaviorStates.IDLE
			if enemiesAttackingPlayer.has(enemy): enemiesAttackingPlayer.erase(enemy)
			if enemiesChasingPlayer.has(enemy): enemiesChasingPlayer.erase(enemy)
		ImpressionStates.PLAYER_FOUND:
			if enemiesAttackingPlayer.size() < MAX_ENEMIES_ON_PLAYER:
				enemy.currentBehaviorState = BehaviorStates.ATTACK
				enemiesAttackingPlayer.append(enemy)
			else:
				enemy.currentBehaviorState = BehaviorStates.CHASE
				enemiesChasingPlayer.append(enemy)
		ImpressionStates.PLAYER_IN_ATTACK_RANGE:
			enemy.currentBehaviorState = BehaviorStates.ATTACK
			enemiesAttackingPlayer.append(enemy)
		ImpressionStates.AM_DEAD:
			activeEnemies[enemy.EnemyName].erase(enemy)
			if enemiesAttackingPlayer.has(enemy): enemiesAttackingPlayer.erase(enemy)
			if enemiesChasingPlayer.has(enemy): enemiesChasingPlayer.erase(enemy)


#var count: float
func _process(_delta: float) -> void:
	#count += _delta
	#if count >= 1.0:
		#print(activeEnemies)
		#count = 0.0
	
	if hasCooldownElasped:
		var totalEnemies: int = 0
		for arr in activeEnemies.values(): totalEnemies += arr.size()
		spawn_enemy("Goblin", MAX_ACTIVE_ENEMIES - totalEnemies)
		get_tree().create_timer(SPAWN_COOLDOWN_TIME).timeout.connect(func(): hasCooldownElasped = true)
		hasCooldownElasped = false
	

func spawn_enemy(type: StringName, amount: int) -> void:
	for i in range(amount):
		var enemyType = ENEMY_SCENE[type].instantiate()
		enemyType.position = spawnAreas[randi() % spawnAreas.size()] + Vector2([-1, 1].pick_random() * 10, 0)
		enemyType.enemyIdleArea = idleAreas[0]
		activeEnemies[type].append(enemyType)
		get_tree().current_scene.add_child.call_deferred(enemyType)
		
