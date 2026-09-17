extends CharacterBody2D

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var NodeFlipPos: Dictionary[Node2D, Vector2] = {
	%HitBox.get_node("CollisionShape2D") : %HitBox.get_node("CollisionShape2D").position
}

const SPEED: float = 270
const JUMP_FORCE: float = 560
const ATTACK_SPAM_TIME: float = 0.4
const HEAVY_ATTACK_HOLD_TIME: float = 0.25

enum Directions {LEFT = -1, RIGHT = 1}

var healthPoint: float = 100
var direction: float = 0
var initDirection: float = 0.0

var currentMovementState: CharacterStateMachine.MovementStates
var currentActionState: CharacterStateMachine.ActionStates : set = _action_state_update

var bodiesInHitBox: Array[Node2D]
var damageValue: float = 1.0
#var hasStrike: bool = false

var allowMovement: bool = true



func _ready() -> void:
	initDirection = 1.0
	
	%HitBox.body_entered.connect(handle_bodies_in_hit_box.bind("entered"))
	%HitBox.body_exited.connect(handle_bodies_in_hit_box.bind("exited"))
	
	



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



func handle_bodies_in_hit_box(body: Node2D, action: String) -> void:
	if action == "entered":
		print("BODY ENTERED")
		bodiesInHitBox.append(body)
	elif action == "exited":
		print("BODY EXITED")
		bodiesInHitBox.erase(body)
	


func damage_bodies_in_hit_box() -> void:
	for body in bodiesInHitBox:
		if body and is_instance_valid(body):
			if body.has_method("damage"):
				body.damage(self, 20)
	
	




func direction_check() -> void:
	if not initDirection == direction and direction:
		initDirection = direction
		
		var signFlip: int
		
		match int(direction):
			Directions.LEFT:
				AnimSprite.flip_h = true
				signFlip = -1
			Directions.RIGHT:
				AnimSprite.flip_h = false
				signFlip = 1
		
		for node in NodeFlipPos:
			node.position.x = signFlip * NodeFlipPos[node].x
			
		



func _action_state_update(action_state: CharacterStateMachine.ActionStates) -> void:
	if not action_state == currentActionState:
		if action_state == CharacterStateMachine.ActionStates.SECOND_ATTACK:
			allowMovement = false
		else: allowMovement = true
	
	currentActionState = action_state
	



func movement_state_check() -> void:
	if not velocity and is_on_floor(): # and not currentMovementState == MovementStates.IDLE:
		currentMovementState = CharacterStateMachine.MovementStates.IDLE
	elif velocity and is_on_floor(): # and not currentMovementState == MovementStates.RUNNING:
		currentMovementState = CharacterStateMachine.MovementStates.MOVING
	elif not is_on_floor(): # and not currentMovementState == MovementStates.ON_AIR:
		currentMovementState = CharacterStateMachine.MovementStates.ON_AIR



var deltaCount: Array = [0.0, 0.0]
func action_state_check(delta: float) -> void:
	deltaCount[0] += delta
	
	if Input.is_action_just_pressed("action"):
		#print('ACTION')
		deltaCount[0] = 0.0
		currentActionState = CharacterStateMachine.ActionStates.ATTACK
	
	if Input.is_action_pressed("action"):
		deltaCount[1] += delta
		if deltaCount[1] > HEAVY_ATTACK_HOLD_TIME:
			#print("HEAVY ACTION")
			currentActionState = CharacterStateMachine.ActionStates.SECOND_ATTACK
	else: deltaCount[1] = 0.0
	
	if deltaCount[0] > ATTACK_SPAM_TIME and not Input.is_action_pressed("action"):
		#print("NO ACTION")
		currentActionState = CharacterStateMachine.ActionStates.NULL
	
