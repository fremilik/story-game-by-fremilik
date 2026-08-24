extends Node2D


const ROADBLOCK_TILE_POS: Array = [Vector2i(0, 16), Vector2i(64, -54), Vector2i(86, -54)]

var roadBlocksNodes: Array
var roadBlocksPos: Array
var plRoadBlocks = preload("res://Scene/objects/road_block.tscn")


func _ready() -> void:
	$Area2D.body_entered.connect(_on_fight_area1_body_entered)
	$Area2D2.body_entered.connect(_on_fight_area2_body_entered)
	$Spawner2.spawn_finished.connect(_on_spawn_finished)
	
	
	roadBlocksPos = ROADBLOCK_TILE_POS.map(func(i): return $Map3.map_to_local(i))
	
	for vec in roadBlocksPos:
		var roadBlock = plRoadBlocks.instantiate()
		roadBlock.position = vec
		roadBlocksNodes.append(roadBlock)
		get_node("Objects").add_child.call_deferred(roadBlock)




func _on_fight_area1_body_entered(body: Node2D) -> void:
	$Area2D.body_entered.disconnect(_on_fight_area1_body_entered)
	if body == Global.Player:
		roadBlocksNodes[0].close_road()
		await get_tree().create_timer(1).timeout
		$Objects/MovingPlat.move()
		await get_tree().create_timer(3).timeout
		
		$Spawner.start_spawn()
		


func _on_fight_area2_body_entered(body: Node2D) -> void:
	$Area2D2.body_entered.disconnect(_on_fight_area2_body_entered)
	if body == Global.Player:
		roadBlocksNodes[1].close_road()
		roadBlocksNodes[2].close_road()
		await get_tree().create_timer(1).timeout
		
		$Spawner2.start_spawn()
		


func _on_spawn_finished(_plat_name: String) -> void:
	await get_tree().create_timer(1.5).timeout
	roadBlocksNodes[1].open_road()
	roadBlocksNodes[2].open_road()
