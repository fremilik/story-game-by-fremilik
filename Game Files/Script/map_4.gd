extends Node2D


const ROADBLOCK_TILE_POS: Array = [Vector2i(180, -12)]

var roadBlocksNodes: Array
var roadBlocksPos: Array
var plRoadBlocks = preload("res://Scene/objects/road_block.tscn")



func _ready() -> void:
	$Area2D.body_entered.connect(_on_fight_area1_body_entered)
	$Spawner.spawn_finished.connect(_on_spawn_finished)
	
	
	roadBlocksPos = ROADBLOCK_TILE_POS.map(func(i): return $Map4.map_to_local(i))
	
	for vec in roadBlocksPos:
		var roadBlock = plRoadBlocks.instantiate()
		roadBlock.position = vec
		roadBlocksNodes.append(roadBlock)
		get_node("Objects").add_child.call_deferred(roadBlock)



func _on_fight_area1_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		$Area2D.body_entered.disconnect(_on_fight_area1_body_entered)
		$BombSpawner.stopSpawn = true
		roadBlocksNodes[0].close_road()
		await get_tree().create_timer(1).timeout
		$Spawner.start_spawn()
		$Objects/Orb.anim_start()
		await get_tree().create_timer(2.5).timeout
		$BombSpawner2.start()
		


func _on_spawn_finished(_plat_name: String) -> void:
	$BombSpawner2.stopSpawn = true
	$Objects/Orb.stop_anim()
