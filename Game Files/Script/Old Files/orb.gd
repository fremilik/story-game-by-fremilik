extends Node2D

@export var tileDistance: int = 1.0
@export var duration: float = 1.0

const TILE_SIZE: int = 32
const SPEED: float = 300

var freeFall: bool = false
var tween: Tween
var timeOut: bool = true


func anim_start() -> void:
	var pos: Vector2 = Vector2(position.x, position.y - (TILE_SIZE * tileDistance))
	timeOut = false
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", pos, duration)
	await tween.finished
	timeOut = true
	print("TIME OUT")
	pos = Vector2(position.x, position.y - 500)
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", pos, 0.75)
	


func stop_anim() -> void:
	if not timeOut:
		tween.stop()
		await get_tree().create_timer(1).timeout
		freeFall = true
		


func _physics_process(delta: float) -> void:
	if freeFall:
		$Orb.position.y += SPEED * delta




func _on_orb_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		Global.orbCollected += 1
		freeFall = false
		$Orb.visible = false
		$Orb.body_entered.disconnect(_on_orb_body_entered)
		await get_tree().create_timer(2).timeout
		self.queue_free()
	else:
		freeFall = false
