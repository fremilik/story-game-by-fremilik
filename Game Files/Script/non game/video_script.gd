extends CharacterBody2D

@export var GRAVITY: float = 18.5
@export var JUMP_FORCE: float = 650.0
@export var SPEED: float = 500.0

var direction: float = 0.0


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y -= JUMP_FORCE
	
	direction = Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	move_and_slide()
	
	
	
