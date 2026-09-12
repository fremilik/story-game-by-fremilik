extends CharacterBody2D

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED: float = 270
const JUMP_FORCE: float = 560
#@export var GRAVITY: float = 19.5


const ATTACK_SPAM_TIME: float = 0.4
const HEAVY_ATTACK_HOLD_TIME: float = 0.25


enum Directions {LEFT = -1, RIGHT = 1}

var direction: float = 0
var initDirection: float = 0.0
var initPos: Vector2
#var initMovementState: PlayerStateMachine.MovementStates

var currentMovementState: PlayerStateMachine.MovementStates
var currentActionState: PlayerStateMachine.ActionStates : set = _action_state_update

var bodiesInHitBox: Array
var damageValue: float = 1.0
var hasStrike: bool = false
var healthPoint: float = 30.0

var allowMovement: bool = true

func _ready() -> void:
	initDirection = 1.0
	




func _process(delta: float) -> void:
	direction_check()
	action_state_check(delta)
	movement_state_check()
	
	Global.PlayerPos = global_position
	



func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -1 * JUMP_FORCE
	
	direction = Input.get_axis("left", "right")
	
	if direction and allowMovement:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	move_and_slide()



func direction_check() -> void:
	if not initDirection == direction and direction:
		initDirection = direction
		
		match int(direction):
			Directions.LEFT:
				AnimSprite.flip_h = true
				#HitBoxCol.position.x = -30
			Directions.RIGHT:
				AnimSprite.flip_h = false
				#HitBoxCol.position.x = 30
		



func _action_state_update(action_state: PlayerStateMachine.ActionStates) -> void:
	if not action_state == currentActionState:
		if action_state == PlayerStateMachine.ActionStates.HEAVY_ATTACK:
			allowMovement = false
		else: allowMovement = true
	
	currentActionState = action_state
	



func movement_state_check() -> void:
	if not velocity and is_on_floor(): # and not currentMovementState == MovementStates.IDLE:
		currentMovementState = PlayerStateMachine.MovementStates.IDLE
	elif velocity and is_on_floor(): # and not currentMovementState == MovementStates.RUNNING:
		currentMovementState = PlayerStateMachine.MovementStates.RUNNING
	elif not is_on_floor(): # and not currentMovementState == MovementStates.ON_AIR:
		currentMovementState = PlayerStateMachine.MovementStates.ON_AIR



var deltaCount: Array = [0.0, 0.0]
func action_state_check(delta: float) -> void:
	deltaCount[0] += delta
	
	if Input.is_action_just_pressed("action"):
		#print('ACTION')
		deltaCount[0] = 0.0
		currentActionState = PlayerStateMachine.ActionStates.ATTACK
	
	if Input.is_action_pressed("action"):
		deltaCount[1] += delta
		if deltaCount[1] > HEAVY_ATTACK_HOLD_TIME:
			#print("HEAVY ACTION")
			currentActionState = PlayerStateMachine.ActionStates.HEAVY_ATTACK
	else: deltaCount[1] = 0.0
	
	if deltaCount[0] > ATTACK_SPAM_TIME and not Input.is_action_pressed("action"):
		#print("NO ACTION")
		currentActionState = PlayerStateMachine.ActionStates.NULL
	
