extends CharacterBase
class_name AbstractEnemy

@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var EnemyAnimState: Node = $EnemyAnimationState
@onready var DetectArea: Area2D = $DetectArea

@export var EnemyName: StringName
@export var Ovr_behavior: bool = false

const ATTACK_DELAY: float = 2.0
const IDLE_STAND_TIME_RANGE: Array[float] = [1.5, 4.5]
const TARGET_POS_UPD_DELAY: float = 0.1

const MAX_PROP_ARR_CACHE_SIZE: int = 6

const SPEED_STATE: Dictionary = {
	"idle_state" : 190,
	"jump_state" : 240,
	"chase_state" : 240,
}

var nextPathPos: Vector2
var isNavigationOngoing: bool = false
var handleLinkReached: bool = false
var navLinkDetails: Dictionary
var propertyCache: Dictionary[StringName, Array] = {
	"position": [],
	"direction": [],
}

var isPlayerDetected: bool = false

# Assigned by EnemyServer
var currentBehaviorState: EnemyServer.BehaviorStates : set = _behavior_state_update
var enemyIdleArea: Rect2
# //

var idleBehaviorMovementState: CharacterStateMachine.MovementStates


func _setup() -> void:
	assert(EnemyName)
	
	AnimSprite = %AnimatedSprite2D
	HitBoxArea = %HitBox
	AnimState = %EnemyAnimationState
	
	OppCollisionMask = 2
	
	JUMP_FORCE = 605
	SPEED = SPEED_STATE["chase_state"]
	
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
		return (currentDisabilityState == CharacterStateMachine.DisabilityStates.NULL and
		currentBehaviorState == EnemyServer.BehaviorStates.ATTACK)
	
	
	EnemyServer.enemy_call(self, EnemyServer.ImpressionStates.PLAYER_NOT_FOUND)



func _process(delta: float) -> void:
	super._process(delta)
	behavior_state_checker(delta)



func check_movement_flow() -> void:
	var error = [false, false]
	
	if propertyCache.has("direction"):
		if not propertyCache["direction"].size() == MAX_PROP_ARR_CACHE_SIZE:
			propertyCache["direction"].append(direction)
		else:
			propertyCache["direction"].pop_front()
			propertyCache["direction"].append(direction)
		
		var count = 0
		for i in propertyCache["direction"]: count += i
		
		if abs(count) <= 1:
			print("DIRECTION on loop")
			error[0] = true
	
	
	if propertyCache.has("position"):
		if not propertyCache["position"].size() == MAX_PROP_ARR_CACHE_SIZE:
			propertyCache["position"].append(global_position)
		else:
			propertyCache["position"].pop_front()
			propertyCache["position"].append(global_position)
			
			var movePerFrame := SPEED / 60.0
			var tolerance := 2
			
			if (propertyCache["position"][0].distance_to(propertyCache["position"][-1]) < 
			(movePerFrame * (propertyCache["position"].size() - 1)) - tolerance):
				print("POSITION not mpving")
				error[1] = true
	
	
	if error.all(func(i): return i == true):
		print("ENEMY IS STUCK")
		propertyCache["position"].clear()
		propertyCache["direction"].clear()
		_set_nav_target_pos(NavAgent.target_position)



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
			
			SPEED = SPEED_STATE["jump_state"]
			if Vector2.UP.dot(linkDirection) > 0.0:#or not %OffPlatformCast.is_colliding():
				velocity.y = -1 * JUMP_FORCE
			
			handleLinkReached = false
		else:
			#if firstNav:
				#print("\n", "NEW NAVIGATION")
				#print("targ_pos: %s" % NavAgent.target_position)
				#firstNav = false
			
			#deltaCount += delta
			#if deltaCount > 0.1:
				#deltaCount = 0.0
				#
			#print("dist_to_next_path: %s" % nextPathPos.distance_to(global_position))
			#print("next_path_pos: %s" % str(nextPathPos))
			#print("glob_pos: %s" % global_position)
			#print("\n")
			
			nextPathPos = NavAgent.get_next_path_position()
			#print("nextPathPos: %s" % nextPathPos)
			#print("at_pos: %s" % global_position)
			direction = signf(nextPathPos.x - global_position.x)
			velocity.x = direction * SPEED
		
		check_movement_flow()
	else: velocity.x = 0
	
	
	move_and_slide()



func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_1"):
		_set_nav_target_pos(Global.PlayerPos)
	


func _set_nav_target_pos(target_pos: Vector2) -> void:
	NavAgent.target_position = NavigationServer2D.map_get_closest_point(Global.NavMapRid, target_pos)
	isNavigationOngoing = true
	nextPathPos = NavAgent.get_next_path_position()
	await get_tree().create_timer(0.5).timeout
	print("Nav path: ", NavAgent.get_current_navigation_path(), "\n")


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
	
	nextPathPos = NavAgent.get_next_path_position()
	print("dist_to_next_path: %s" % nextPathPos.distance_to(global_position))
	print("next_path_pos: %s" % str(nextPathPos))
	print("glob_pos: %s" % global_position)
	


func _on_link_reached(details: Dictionary) -> void:
	print("LINKED REACHED")
	handleLinkReached = true
	navLinkDetails = details
#endregion


func _rand_pos_in_idle_area() -> Vector2:
	var globPos: Vector2 = enemyIdleArea.position
	var randX := randf_range(globPos.x, globPos.x + enemyIdleArea.size.x)
	var randY := randf_range(globPos.y, globPos.y + enemyIdleArea.size.y)
	return Vector2(randX, randY)


func _behavior_state_update(state: EnemyServer.BehaviorStates) -> void:
	if Ovr_behavior: return
	currentBehaviorState = state
	print("behavior_change: %s" % EnemyServer.BehaviorStates.find_key(state))
	
	if state == EnemyServer.BehaviorStates.IDLE:
		#AnimSprite.speed_scale = 0.5
		#SPEED = SPEED_STATE["idle_state"]
		
		idleBehaviorMovementState = CharacterStateMachine.MovementStates.IDLE
		get_tree().create_timer(randf_range(IDLE_STAND_TIME_RANGE[0], IDLE_STAND_TIME_RANGE[1])).timeout.connect(
			func():
				_set_nav_target_pos(_rand_pos_in_idle_area())
				idleBehaviorMovementState = CharacterStateMachine.MovementStates.MOVING)
	elif state == EnemyServer.BehaviorStates.CHASE:
		pass
	elif state == EnemyServer.BehaviorStates.ATTACK:
		pass


func behavior_state_checker(_delta: float) -> void:
	if Ovr_behavior: return
	if currentBehaviorState == EnemyServer.BehaviorStates.IDLE:
		if idleBehaviorMovementState == CharacterStateMachine.MovementStates.MOVING:
			if not isNavigationOngoing:
				get_tree().create_timer(randf_range(IDLE_STAND_TIME_RANGE[0], IDLE_STAND_TIME_RANGE[1])).timeout.connect(
					func():
						_set_nav_target_pos(_rand_pos_in_idle_area())
						idleBehaviorMovementState = CharacterStateMachine.MovementStates.MOVING)
				idleBehaviorMovementState = CharacterStateMachine.MovementStates.IDLE
	elif currentBehaviorState == EnemyServer.BehaviorStates.CHASE:
		pass
	elif currentBehaviorState == EnemyServer.BehaviorStates.ATTACK:
		pass
