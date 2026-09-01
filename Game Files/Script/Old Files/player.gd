extends CharacterBody2D

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var HitBoxArea: Area2D = $HitBoxArea
@onready var HitBoxCol: CollisionShape2D = $HitBoxArea/CollisionShape2D

@export var SPEED: float = 270
@export var JUMP_FORCE: float = 390
@export var GRAVITY: float = 19.5

enum Directions {LEFT = -1, RIGHT = 1}
enum States {IDLE, RUNNING, ON_AIR, ATTACK, HURT, DEAD}

const STRIKE_FRAME: int = 3

var direction: float = 0.0
var initDirection: float = 0.0
var currentState: States
var bodiesInHitBox: Array
var damageValue: float = 1.0
var hasStrike: bool = false
var healthPoint: float = 30.0

func _ready() -> void:
	Global.Player = self
	
	HitBoxArea.body_entered.connect(_on_hit_box_body_entered)
	HitBoxArea.body_exited.connect(_on_hit_box_body_exited)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_1") and OS.is_debug_build():
		global_position = Vector2.ZERO



func _process(_delta: float) -> void:
	direction_check()
	state_machine()
	
	if currentState == States.ATTACK:
		if AnimSprite.animation == "attack":
			if AnimSprite.frame == STRIKE_FRAME and not hasStrike:
				hasStrike = true
				for body in bodiesInHitBox:
					body.damage(damageValue)


func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -JUMP_FORCE
	
	direction = Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	move_and_slide()
	


func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.has_method("damage"):
		bodiesInHitBox.append(body)


func _on_hit_box_body_exited(body: Node2D) -> void:
	if body.has_method("damage"):
		bodiesInHitBox.erase(body)


func damage(loss: float) -> void:
	healthPoint -= loss
	print("DAMAGED")
	
	if healthPoint <= 0.0 and not currentState == States.DEAD:
		print("DEAD")
		currentState = States.DEAD
		
	elif not currentState == States.DEAD:
		currentState = States.HURT
		AnimSprite.play("hurt")
		await AnimSprite.animation_finished
		if not currentState == States.DEAD: currentState = States.IDLE
		
	
	



func direction_check() -> void:
	if not initDirection == direction and direction:
		initDirection = direction
		
		match int(direction):
			Directions.LEFT:
				AnimSprite.flip_h = true
				HitBoxCol.position.x = -30
			Directions.RIGHT:
				AnimSprite.flip_h = false
				HitBoxCol.position.x = 30
	
	


func state_machine() -> void:
	if currentState == States.HURT or currentState == States.DEAD: return
	if Input.is_action_just_pressed("action") and not AnimSprite.animation == "attack":
		if not currentState == States.ATTACK:
			currentState = States.ATTACK
			hasStrike = false
			AnimSprite.play("attack")
		return
	elif currentState == States.ATTACK and AnimSprite.is_playing():
			return
	
	if not velocity and is_on_floor() and not currentState == States.IDLE:
		currentState = States.IDLE
		AnimSprite.play("idle_norm")
	elif velocity and is_on_floor() and not currentState == States.RUNNING:
		currentState = States.RUNNING
		AnimSprite.play("run")
	elif not is_on_floor() and not currentState == States.ON_AIR:
		currentState = States.ON_AIR
		AnimSprite.play("jump")
