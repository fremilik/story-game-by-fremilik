extends Node2D

@export var EnemyType: String
@export var SpawnPositions: Array[Vector2]
@export var amount: int
@export var moveToOnStart: Vector2

enum SpawnRange {MIN = 3, MAX = 7}

var intervalRange: Array = [1.7, 3.2]
var plEnemy
var currentAmount: int

signal spawn_finished(sp_name: String)

func _ready() -> void:
	if not EnemyType.is_empty():
		var path = "res://Scene/" + EnemyType + ".tscn"
		plEnemy = load(path)
	
	currentAmount = amount
	if SpawnPositions.is_empty(): printerr("NO SPAWN POSITIONS ASSIGNED")


func start_spawn() -> void:
	if currentAmount != 0:
		var spawnAmt: int = randi_range(SpawnRange.MIN, SpawnRange.MAX)
		if spawnAmt > currentAmount: spawnAmt = currentAmount
		currentAmount = max(0, currentAmount - spawnAmt)
		for i in range(spawnAmt):
			var enemy = plEnemy.instantiate()
			enemy.position = SpawnPositions[randi() % SpawnPositions.size()]
			enemy.moveToOnStart = moveToOnStart
			get_parent().add_child.call_deferred(enemy)
			await get_tree().create_timer(0.3)
		
		await get_tree().create_timer(randf_range(intervalRange[0], intervalRange[1])).timeout
		start_spawn()
	else:
		await get_tree().create_timer(3).timeout
		spawn_finished.emit(name)
	
