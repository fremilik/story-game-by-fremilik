extends Node2D

const MAX_JUMP_AXIS_DISTANCE: Vector2i = Vector2i(5, 3)
const MAX_JUMP_LENGHT: float = 5.4

var NavTestMap: Node2D
var PlatformNavMap: TileMapLayer

func _ready() -> void:
	if has_node("Nav Test Map"):
		NavTestMap = get_node("Nav Test Map")
		
		NavTestMap.z_index = -1
		NavTestMap.position = Vector2(-37, -225)
		
		if NavTestMap.has_node("PlatformNavLayer"):
			PlatformNavMap = NavTestMap.get_node("PlatformNavLayer")
			PlatformNavMap.tile_set = load("res://Resources/test_map_tileset.tres")
			
			_set_nav_links_at_proximity(PlatformNavMap.get_used_cells_by_id(1, Vector2i(0, 1)))
		else: print("COULD NOT FIND NODE")
		
	
	


func _set_nav_links_at_proximity(cells_pos: Array[Vector2i]) -> void:
	print("START SETUP at: %s" % Global.get_running_time())
	var cellIndex: int = 0
	var cellDist: Vector2i
	
	while cellIndex <= cells_pos.size() - 1:
		for cell in cells_pos:
			if not cell == cells_pos[cellIndex]:
				cellDist = abs(cell - cells_pos[cellIndex])
				if (cellDist.x <= MAX_JUMP_AXIS_DISTANCE.x and cellDist.y <= MAX_JUMP_AXIS_DISTANCE.y) and cellDist.length() <= MAX_JUMP_LENGHT:
					print("cells are close; pos_a: %s| pos_b: %s| dist: %s" % [cells_pos[cellIndex], cell, cellDist])
					_create_nav_link_at_cells(cells_pos[cellIndex], cell)
					
		
		cellIndex += 1
	
	print("FINISHED SETUP at: %s" % Global.get_running_time())
	


func _create_nav_link_at_cells(pos_a: Vector2i, pos_b: Vector2i) -> void:
	var NavLink := NavigationLink2D.new()
	NavLink.start_position = PlatformNavMap.map_to_local(pos_a) + Vector2(-37, -225)
	NavLink.end_position = PlatformNavMap.map_to_local(pos_b) + Vector2(-37, -225)
	
	get_node("MapNavLinks").add_child.call_deferred(NavLink)
	
