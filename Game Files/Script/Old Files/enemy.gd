extends CharacterBody2D
class_name Enemy

@onready var WallCast: RayCast2D = $WallCast
@onready var GroundCast: RayCast2D = $GroundCast
@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var HitBoxCol: CollisionShape2D = $HitBoxArea/CollisionShape2D
@onready var HitBoxArea: Area2D = $HitBoxArea
@onready var DetectArea: Area2D = $DetectArea

@export_range(50, 100) var roamSpeed: float = 80.0
@export_range(150, 230) var chaseSpeed: float = 200.0
@export var healthPoint: float = 3.0

const GRAVITY: float = 19.5


enum Directions {LEFT = -1, RIGHT = 1}
enum State {MOVE_TO, ROAM, CHASE, ATTACK, HURT, DEAD}

var hitColPosRange: Array = [12.0, 17.0]
var direction: float = -1.0
var followPlayer: bool = false

var currentState: State
var hitCollisionPos: float = 0.0
var moveToOnStart: Vector2
var strikeFrame: int = 0
var hasStrike: bool = false

func _ready() -> void:
	_setup()
	
	hitCollisionPos = roundf(randf_range(hitColPosRange[0], hitColPosRange[1]))
	
	HitBoxCol.position.x = hitCollisionPos
	HitBoxCol.shape.size.x = hitCollisionPos * 2
	
	if not moveToOnStart:
		currentState = State.ROAM
	else:
		direction = signf(moveToOnStart.x - global_position.x)
		direction_change()
	
	DetectArea.body_entered.connect(_on_detect_area_body_entered)
	DetectArea.body_exited.connect(_on_detect_area_body_exited)
	HitBoxArea.body_entered.connect(_on_hit_box_body_entered)
	HitBoxArea.body_exited.connect(_on_hit_box_body_exited)
	
	AnimSprite.play("run")


 
func _setup() -> void:
	pass


func _process(delta: float) -> void:
	if currentState == State.ROAM:
		if not GroundCast.is_colliding() or WallCast.is_colliding():
			if is_on_floor():
				direction *= -1
				direction_change()
	
	if currentState == State.ATTACK:
		if AnimSprite.animation == "attack":
			if AnimSprite.frame == strikeFrame and not hasStrike:
				hasStrike = true
				Global.Player.damage(1.0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY
	
	if currentState == State.CHASE:
		direction = signf(Global.Player.global_position.x - global_position.x)
		direction_change()
		velocity.x = chaseSpeed * direction
	elif currentState == State.ROAM:
		velocity.x = roamSpeed * direction
	elif currentState == State.MOVE_TO:
		direction = signf(moveToOnStart.x - global_position.x)
		velocity.x = direction * chaseSpeed
		
		if absf(moveToOnStart.x - global_position.x) < 5.0:
			currentState = State.ROAM
			
	
	move_and_slide()


func direction_change() -> void:
	match int(direction):
		Directions.LEFT:
			WallCast.target_position.x = -30
			GroundCast.position.x = -15
			AnimSprite.flip_h = true
			HitBoxCol.position.x = -hitCollisionPos
		Directions.RIGHT:
			WallCast.target_position.x = 30
			GroundCast.position.x = 15
			AnimSprite.flip_h = false
			HitBoxCol.position.x = hitCollisionPos
	

func _on_detect_area_body_entered(body: Node2D) -> void:
	if body == Global.Player and not currentState == State.DEAD:
		currentState = State.CHASE


func _on_detect_area_body_exited(body: Node2D) -> void:
	if body == Global.Player and not currentState == State.DEAD:
		currentState = State.ROAM



func _on_hit_box_body_entered(body: Node2D) -> void:
	if body == Global.Player and not currentState == State.DEAD:
		currentState = State.ATTACK
		velocity.x = 0.0
		hasStrike = false
		attack_player()


func _on_hit_box_body_exited(body: Node2D) -> void:
	if body == Global.Player and not currentState == State.DEAD:
		currentState = State.CHASE
		AnimSprite.play("run")


func attack_player() -> void:
	if currentState == State.ATTACK:
		AnimSprite.play("attack")
		await AnimSprite.animation_finished
		attack_player()
		


func damage(loss: float) -> void:
	healthPoint -= loss
	
	if healthPoint <= 0.0 and not currentState == State.DEAD:
		currentState = State.DEAD
		velocity.x = 0.0
		#DetectArea.body_entered.disconnect(_on_detect_area_body_entered)
		#DetectArea.body_exited.disconnect(_on_detect_area_body_exited)
		#HitBoxArea.body_entered.disconnect(_on_hit_box_body_entered)
		#HitBoxArea.body_exited.disconnect(_on_hit_box_body_exited)
		AnimSprite.play("death")
		await AnimSprite.animation_finished
		await get_tree().create_timer(2).timeout
		self.queue_free()
	elif not currentState == State.DEAD:
		currentState = State.HURT
		AnimSprite.play("hurt")
		await AnimSprite.animation_finished
		if not currentState == State.DEAD:
			currentState = State.ATTACK
			hasStrike = false
			attack_player()
		
