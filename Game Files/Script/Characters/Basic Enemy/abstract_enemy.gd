extends CharacterBase
class_name AbstractEnemy

@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var EnemyAnimState: Node = $EnemyAnimationState
@onready var DetectArea: Area2D = $DetectArea

@export var EnemyName: StringName

const ATTACK_DELAY: float = 2.0

var nextPathPos: Vector2
var isNavigationOngoing: bool = false
var handleLinkReached: bool = false
var navLinkDetails: Dictionary

var attackStrike: bool = false

var isPlayerDetected: bool = false

var currentBehaviorState: EnemyBehavior.BehaviorStates


func _setup() -> void:
	assert(EnemyName)
	
	AnimSprite = %AnimatedSprite2D
	HitBoxArea = %HitBox
	AnimState = %EnemyAnimationState
	
	
	OppCollisionMask = 2
	
	JUMP_FORCE = 605
	SPEED = 240
	
	DetectArea.set_collision_mask_value(OppCollisionMask, true)
	DetectArea.body_entered.connect(_on_action_on_detect_area.bind(&"entered"))
	DetectArea.body_exited.connect(_on_action_on_detect_area.bind(&"exited"))
	
	NavAgent.target_reached.connect(_on_target_pos_reached)
	NavAgent.navigation_finished.connect(_on_navigation_finished)
	NavAgent.link_reached.connect(_on_link_reached)
	
	
	allowMovement = func() -> bool:
		return (currentDisabilityState == CharacterStateMachine.DisabilityStates.NULL and
		 not currentActionState == CharacterStateMachine.ActionStates.ATTACK)
	
	allowAttack = func() -> bool:
		return (currentDisabilityState == CharacterStateMachine.DisabilityStates.NULL)
	





var deltaCount: float
func _physics_process(delta: float) -> void:
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if isNavigationOngoing and allowMovement.call():
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
			
			velocity.x = direction * SPEED
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
	


var attackTimeCount: Array[float] = [0.0, 0.0]
func action_state_check(delta: float) -> void:
	if not allowAttack.call():
		currentActionState = CharacterStateMachine.ActionStates.NULL
		return
	
	
	if not bodiesInHitBox.is_empty():
		if currentActionState == CharacterStateMachine.ActionStates.NULL:
			attackTimeCount[0] += delta
			if attackTimeCount[0] > ATTACK_DELAY:
				currentActionState = CharacterStateMachine.ActionStates.ATTACK
				attackTimeCount[0] = 0.0
	else:
		currentActionState = CharacterStateMachine.ActionStates.NULL
	



func _on_action_on_detect_area(_body: Node2D, action: StringName) -> void:
	if action == &"entered":
		isPlayerDetected = true
	elif action == &"exited":
		print("DETECT EXIT")
	



func _on_action_on_escape_area(_body: Node2D, action: StringName) -> void:
	if action == &"entered":
		pass
	elif action == &"exited":
		isPlayerDetected = false
	



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
