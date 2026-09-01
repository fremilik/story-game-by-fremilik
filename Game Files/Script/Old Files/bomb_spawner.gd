extends Node2D

@export var spawnPositions: Array[Vector2]
@export var autoStart: bool = false
@export var frequency: float = 1.0

const plBomb = preload("res://Scene/objects/bomb.tscn")

var amountPerSpawn: int = 0
var stopSpawn: bool = false

func _ready() -> void:
	amountPerSpawn = roundi(spawnPositions.size() * 0.5)
	
	if autoStart: start()


func start() -> void:
	if not stopSpawn:
		spawnPositions.shuffle()
		
		for i in range(amountPerSpawn):
			var bomb = plBomb.instantiate()
			bomb.position = spawnPositions[i]
			get_parent().add_child.call_deferred(bomb)
		
		await get_tree().create_timer(frequency).timeout
		start()
		
