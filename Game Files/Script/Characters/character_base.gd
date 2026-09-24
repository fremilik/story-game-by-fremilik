extends CharacterBody2D
class_name CharacterBase

@export var DevOvr_Health: bool

enum Directions {LEFT = -1, RIGHT = 1}

var AnimSprite: AnimatedSprite2D
var AnimState: Node
var HitBoxArea: Area2D
var OppCollisionMask: int

var SPEED: float = 270
var JUMP_FORCE: float = 560

var healthPoint: float = 100
var direction: float = 0
var initDirection: float = 0.0


var currentMovementState: CharacterStateMachine.MovementStates
var currentActionState: CharacterStateMachine.ActionStates
var currentDisabilityState: CharacterStateMachine.DisabilityStates

var bodiesInHitBox: Array[Node2D]

var allowMovement: Callable = func() -> bool: return true
var allowAttack: Callable = func() -> bool: return true

func _ready() -> void:
	_setup()
	
	assert(AnimState and OppCollisionMask)
	
	initDirection = 1.0
	
	HitBoxArea = %HitBox
	AnimSprite = %AnimatedSprite2D
	
	HitBoxArea.set_collision_mask_value(OppCollisionMask, true)
	HitBoxArea.body_entered.connect(handle_bodies_in_hit_box.bind("entered"))
	HitBoxArea.body_exited.connect(handle_bodies_in_hit_box.bind("exited"))
	


func _setup() -> void:
	pass


func _process(delta: float) -> void:
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	if not currentMovementState == CharacterStateMachine.MovementStates.IDLE:
		direction_check(direction)
	
	action_state_check(delta)
	movement_state_check()



func damage_bodies_in_hit_box() -> void:
	for body in bodiesInHitBox:
		if body and is_instance_valid(body):
			if body.has_method("damage"):
				body.damage(self, 10)
	


func handle_bodies_in_hit_box(body: Node2D, action: String) -> void:
	if action == "entered":
		print("BODY ENTERED")
		bodiesInHitBox.append(body)
	elif action == "exited":
		print("BODY EXITED")
		bodiesInHitBox.erase(body)
	



func damage(body: Node2D, value: float) -> void:
	print("devovr_health: %s" % DevOvr_Health)
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD or DevOvr_Health: return
	print("HURT")
	direction_check(signf(body.global_position.x - global_position.x))
	healthPoint -= value
	currentDisabilityState = CharacterStateMachine.DisabilityStates.HURT
	AnimState.apply_disable_state(CharacterStateMachine.DisabilityStates.HURT)
	
	
	if healthPoint <= 0:
		print("DEAD")
		
		currentDisabilityState = CharacterStateMachine.DisabilityStates.DEAD
		AnimState.apply_disable_state(CharacterStateMachine.DisabilityStates.DEAD)



func action_state_check(_delta: float) -> void:
	pass



func movement_state_check() -> void:
	if not velocity and is_on_floor():
		currentMovementState = CharacterStateMachine.MovementStates.IDLE
	elif velocity and is_on_floor():
		currentMovementState = CharacterStateMachine.MovementStates.MOVING
	elif not is_on_floor():
		currentMovementState = CharacterStateMachine.MovementStates.ON_AIR



func direction_check(look_at_direc: float) -> void:
	if not initDirection == look_at_direc and look_at_direc:
		initDirection = look_at_direc
		
		var signFlip: int
		match int(look_at_direc):
			Directions.LEFT:
				AnimSprite.flip_h = true
				signFlip = -1
			Directions.RIGHT:
				AnimSprite.flip_h = false
				signFlip = 1
		
		for node in get_tree().get_nodes_in_group("Flippable Nodes"):
			if self.is_ancestor_of(node):
				node.position.x = abs(node.position.x) * signFlip
				
			
		
	
