extends CharacterBody2D
class_name Player

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D

@export var SPEED: float = 180
@export var JUMP_FORCE: float = 340
@export var GRAVITY: float = 19.5


const ATTACK_TIMER: float = 0.2
const ATTACK_HOLD_TIME: float = 0.3
const ANIM_OFFSET_POS: Dictionary = {
	["jump"] : Vector2(0, 0),
	["idle", "stop", "run", "hurt", "death"] : Vector2(0, -21),
	["attack"] : Vector2(31, -22),
	["heavy_attack"] : Vector2(28, -22),
	["jump_attack"] : Vector2(28, -5)
}


enum Directions {LEFT = -1, RIGHT = 1}

enum AnimStates {MOVEMENT, ACTION, DISABILITY}
enum MovementStates {IDLE, RUNNING, JUMP, ON_AIR, HURT, DEAD}
enum ActionStates {NULL, ATTACK, JUMP_ATTACK, HEAVY_ATTACK}


var direction: float = 0
var initDirection: float = 0.0
var initPos: Vector2
var initMovementState: MovementStates
var currentMovementState: MovementStates
var currentActionState: ActionStates

var bodiesInHitBox: Array
var damageValue: float = 1.0
var hasStrike: bool = false
var healthPoint: float = 30.0

var isOnFloorBuffer: bool = false



func _ready() -> void:
	pass




func _process(delta: float) -> void:
	direction_check()
	attack_state_checker(delta)
	movement_state_checker()
	
	
	if %FloorCast.is_colliding(): isOnFloorBuffer = true
	else: isOnFloorBuffer = false
	



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
		
		_anim_offset_check(AnimSprite.animation)



func _anim_offset_check(anim: String) -> void:
	for key in ANIM_OFFSET_POS.keys():
		print("searching")
		if key.has(anim):
			print("has key: %s" % anim)
			if AnimSprite.flip_h:
				AnimSprite.offset = Vector2(-1 * ANIM_OFFSET_POS[key].x, ANIM_OFFSET_POS[key].y)
			else: AnimSprite.offset = ANIM_OFFSET_POS[key]
		



func _update_animation_state(anim_state: AnimStates, anim_current_state: int) -> void:
	match anim_state:
		AnimStates.MOVEMENT:
			%PlayerAnimationState._player_movement_state_update(anim_current_state)
		AnimStates.ACTION:
			%PlayerAnimationState._player_action_state_update(anim_current_state)
		AnimStates.DISABILITY:
			pass



func movement_state_checker() -> void:
	if not velocity and is_on_floor() and not currentMovementState == MovementStates.IDLE:
		currentMovementState = MovementStates.IDLE
		#AnimState._player_movement_state_update(currentMovementState)
		_update_animation_state(AnimStates.MOVEMENT, currentMovementState)
	elif velocity and is_on_floor() and not currentMovementState == MovementStates.RUNNING:
		currentMovementState = MovementStates.RUNNING
		#AnimState._player_movement_state_update(currentMovementState)
		_update_animation_state(AnimStates.MOVEMENT, currentMovementState)
	elif not is_on_floor() and not currentMovementState == MovementStates.ON_AIR:
		currentMovementState = MovementStates.ON_AIR
		#AnimState._player_movement_state_update(currentMovementState)
		_update_animation_state(AnimStates.MOVEMENT, currentMovementState)



var deltaCount: Array = [0.0, 0.0]
func attack_state_checker(delta: float) -> void:
	deltaCount[0] += delta
	
	if Input.is_action_just_pressed("action"):
		#print('ACTION')
		deltaCount[0] = 0.0
		if not currentActionState == ActionStates.ATTACK:
			currentActionState = ActionStates.ATTACK
			_update_animation_state(AnimStates.ACTION, currentActionState)
	
	if Input.is_action_pressed("action"):
		deltaCount[1] += delta
		if deltaCount[1] > ATTACK_HOLD_TIME:
			#print("HEAVY ACTION")
			if not currentActionState == ActionStates.HEAVY_ATTACK:
				currentActionState = ActionStates.HEAVY_ATTACK
				_update_animation_state(AnimStates.ACTION, currentActionState)
	else: deltaCount[1] = 0.0
	
	if deltaCount[0] > ATTACK_TIMER and not Input.is_action_pressed("action"):
		#print("NO ACTION")
		if not currentActionState == ActionStates.NULL:
			currentActionState = ActionStates.NULL
			_update_animation_state(AnimStates.ACTION, currentActionState)
	
	
