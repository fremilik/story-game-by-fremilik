extends AnimatedSprite2D

@onready var WallCollider: CollisionShape2D = $WallCollideArea/CollisionShape2D
@onready var HitBoxCollider: CollisionPolygon2D = $HitBox/CollisionPolygon2D

const LOCAL_START_POS := Vector2(28, 2)
const FINAL_ANIM_SCALE := Vector2(1.7, 1.7)
const SCALE_ANIM_TIME := 0.4
const SPEED := 500.0

const OUT_OF_BOUNDS_DIST := 650.0

var direction: int
var initActivatePos: Vector2
var processProjection: bool


func _ready() -> void:
	visible = false
	processProjection = false
	position = LOCAL_START_POS
	
	HitBoxCollider.set_deferred("disabled", true)
	
	




func activate(dir: int) -> void:
	assert(dir == 1 or dir == -1)
	scale = Vector2.ONE
	visible = true
	direction = dir
	initActivatePos = global_position
	WallCollider.set_deferred("disabled", false)
	HitBoxCollider.set_deferred("disabled", false)
	stop()
	
	if direction == 1:
		position = LOCAL_START_POS
		flip_h = false
	else:
		position = Vector2(-1 * LOCAL_START_POS.x, LOCAL_START_POS.y)
		flip_h = true
	
	processProjection = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", FINAL_ANIM_SCALE, SCALE_ANIM_TIME)
	



func _process(delta: float) -> void:
	if processProjection:
		position.x += direction * SPEED * delta
		
		if abs(global_position.x - initActivatePos.x) > OUT_OF_BOUNDS_DIST:
			print("RESET WAVE")
			visible = false
			WallCollider.set_deferred("disabled", true)
			HitBoxCollider.set_deferred("disabled", true)
			position = LOCAL_START_POS
			processProjection = false
		




func _on_wall_collide_area_body_entered(_body: Node2D) -> void:
	print("WALL COLLIDE")
	processProjection = false
	WallCollider.set_deferred("disabled", true)
	HitBoxCollider.set_deferred("disabled", true)
	play("destroy")
	await animation_finished
	visible = false
	position = LOCAL_START_POS


func _on_hit_box_body_entered(body: Node2D) -> void:
	if body and is_instance_valid(body):
			if body.has_method("damage"):
				body.damage(self, 70)
