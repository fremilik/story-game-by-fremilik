extends Node


const GRAVITY: float = 25.0
#const JUMP_FORCE: float = 560

var PlayerPos: Vector2



func get_running_time() -> float:
	return (Time.get_ticks_msec() / 100.0)
	
