extends Node2D

const ROADBLOCK_TILE_POS: Array = [Vector2i(38, 8), Vector2i(60, 8), Vector2i(120, 21),
Vector2i(135, 3)]

var roadBlocksNodes: Array
var roadBlocksPos: Array
var plRoadBlocks = preload("res://Scene/objects/road_block.tscn")


func _ready() -> void:
	$Area2D.body_entered.connect(_on_fight_area1_body_entered)
	$Area2D2.body_entered.connect(_on_fight_area2_body_entered)
	$Spawner.spawn_finished.connect(_on_spawn_finished)
	$Spawner2.spawn_finished.connect(_on_spawn_finished)
	
	
	roadBlocksPos = ROADBLOCK_TILE_POS.map(func(i): return $Map1.map_to_local(i))
	
	for vec in roadBlocksPos:
		var roadBlock = plRoadBlocks.instantiate()
		roadBlock.position = vec
		roadBlocksNodes.append(roadBlock)
		get_node("Objects").add_child.call_deferred(roadBlock)
	
	await get_tree().create_timer(1).timeout
	roadBlocksNodes[3].close_road()
	

func _on_fight_area1_body_entered(body: Node2D) -> void:
	print("AREA ENTERED")
	if body == Global.Player:
		$Area2D.body_entered.disconnect(_on_fight_area1_body_entered)
		roadBlocksNodes[0].close_road()
		roadBlocksNodes[1].close_road()
		await get_tree().create_timer(1).timeout
		
		$Spawner.start_spawn()
		
		


func _on_fight_area2_body_entered(body: Node2D) -> void:
	print("AREA ENTERED")
	
	if body == Global.Player:
		$Area2D2.body_entered.disconnect(_on_fight_area2_body_entered)
		roadBlocksNodes[2].close_road()
		await get_tree().create_timer(1).timeout
		
		$Spawner2.start_spawn()
		$Area2D2.body_entered.disconnect(_on_fight_area2_body_entered)
		
		



func _on_spawn_finished(spawner_name: String) -> void:
	print("spawn finisehd")
	if spawner_name == "Spawner":
		roadBlocksNodes[0].open_road()
		roadBlocksNodes[1].open_road()
	elif spawner_name == "Spawner2":
		roadBlocksNodes[2].open_road()
		roadBlocksNodes[3].open_road()
		
