extends CharacterBody2D
class_name AbstractEnemy

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var EnemyAnimState: Node = $EnemyAnimationState

@export var EnemyName: StringName

enum Directions {LEFT = -1, RIGHT = 1}

var JUMP_FORCE: float = 605

var offsetNodePos := {
	"off_platform_cast": 20
}

var initDirection: float
var direction: float

var speed: float = 240
var healthPoint: float = 100

var nextPathPos: Vector2
var isNavigationOngoing: bool = false
var handleLinkReached: bool = false
var navLinkDetails: Dictionary


var currentMovementState: EnemyStateMachine.MovementStates
var currentActionState: EnemyStateMachine.ActionStates
var currentDisabilityState: EnemyStateMachine.DisabilityStates


func _init() -> void:
	await ready
	_ready_setup()
	


func _ready_setup() -> void:
	assert(EnemyName)
	print("READY")
	NavAgent.target_reached.connect(_on_target_pos_reached)
	NavAgent.navigation_finished.connect(_on_navigation_finished)
	NavAgent.link_reached.connect(_on_link_reached)
	



func _process(_delta: float) -> void:
	if currentDisabilityState == EnemyStateMachine.DisabilityStates.DEAD: return
	
	movement_state_check()
	if not currentMovementState == EnemyStateMachine.MovementStates.IDLE:
		direction_check(direction)
	


var deltaCount: float
func _physics_process(delta: float) -> void:
	if currentDisabilityState == EnemyStateMachine.DisabilityStates.DEAD: return
	
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if isNavigationOngoing:
		if handleLinkReached:
			velocity.x = 0
			
			var entryPos: Vector2 = navLinkDetails["link_entry_position"]
			var exitPos: Vector2 = navLinkDetails["link_exit_position"]
			var linkDirection: Vector2 = entryPos.direction_to(exitPos)
			
			
			if Vector2.UP.dot(linkDirection) > 0.0:#or not %OffPlatformCast.is_colliding():
				velocity.y = -1 * JUMP_FORCE
			
			handleLinkReached = false
		else:
			deltaCount += delta
			if deltaCount > 0.1:
				deltaCount = 0.0
				
				nextPathPos = NavAgent.get_next_path_position()
				print("nextPathPos: %s" % nextPathPos)
				direction = signf(nextPathPos.x - global_position.x)
			
			velocity.x = direction * speed
	else: velocity.x = 0
	
	move_and_slide()



func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_1"):
		_set_nav_target_pos(Global.PlayerPos)
		


func _set_nav_target_pos(target_pos: Vector2) -> void:
	NavAgent.target_position = target_pos
	isNavigationOngoing = true
	
	print("target_pos: %s" % target_pos)
	print(NavAgent.get_next_path_position())
	



#region Navigation Signals
func _on_target_pos_reached() -> void:
	print("TARGET REACHED")


func _on_navigation_finished() -> void:
	print("NAV FINISHED")
	isNavigationOngoing = false


func _on_link_reached(details: Dictionary) -> void:
	print("LINKED REACHED")
	handleLinkReached = true
	navLinkDetails = details

#endregion


func movement_state_check() -> void:
	if not velocity and is_on_floor():
		currentMovementState = EnemyStateMachine.MovementStates.IDLE
	elif velocity and is_on_floor():
		currentMovementState = EnemyStateMachine.MovementStates.MOVING
	elif not is_on_floor():
		currentMovementState = EnemyStateMachine.MovementStates.ON_AIR


func direction_check(look_at_direc: float) -> void:
	if not initDirection == look_at_direc and look_at_direc:
		initDirection = look_at_direc
		
		match int(look_at_direc):
			Directions.LEFT:
				AnimSprite.flip_h = true
				%OffPlatformCast.position.x = -1 * offsetNodePos["off_platform_cast"]
				#HitBoxCol.position.x = -30
			Directions.RIGHT:
				AnimSprite.flip_h = false
				%OffPlatformCast.position.x = offsetNodePos["off_platform_cast"]
				#HitBoxCol.position.x = 30
		


func damage(body: Node2D, value: float) -> void:
	if currentDisabilityState == EnemyStateMachine.DisabilityStates.DEAD: return
	print("HURT")
	direction_check(signf(body.global_position.x - global_position.x))
	healthPoint -= value
	currentDisabilityState = EnemyStateMachine.DisabilityStates.HURT
	EnemyAnimState.apply_disable_state(EnemyStateMachine.DisabilityStates.HURT)
	
	
	if healthPoint <= 0:
		print("DEAD")
		currentDisabilityState = EnemyStateMachine.DisabilityStates.DEAD
		EnemyAnimState.apply_disable_state(EnemyStateMachine.DisabilityStates.DEAD)
	
