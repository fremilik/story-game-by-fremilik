extends CharacterBase
class_name AbstractEnemy

@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var EnemyAnimState: Node = $EnemyAnimationState
@onready var DetectArea: Area2D = $DetectArea
@onready var EscapeArea: Area2D = $EscapeArea

@export var EnemyName: StringName
@export var Ovr_behavior: bool = false
@export var Ovr_Detection: bool = false

@export var movementSpeedState: Dictionary[StringName, float] = {
	"behavior_idle" : 120,
	"movement_jump" : 240,
	"behavior_chase" : 240,
}

@export var animFpsState: Dictionary[StringName, float] = {
	"behavior_idle": 1.0,
	"behavior_chase": 1.0,
}

const ATTACK_DELAY: float = 0.3
const IDLE_STAND_TIME_RANGE: Array[float] = [1.5, 4.5]
const TARGET_POS_UPD_DELAY: float = 0.1

const MAX_PROP_ARR_CACHE_SIZE: int = 6
const DESPAWN_TIME: float = 7.0

var backupDistance: float = 80
var landingDelayTime: float = 0.3
var onLandingDelay: bool = false

var nextPathPos: Vector2
var isNavigationOngoing: bool = true
var handleLinkReached: bool = false
var navLinkDetails: Dictionary
var propertyCache: Dictionary[StringName, Array] = {
	"position": [],
	"direction": [],
}

var isPlayerDetected: bool = false
var attackPrepMoment: bool = false 

# Assigned by EnemyServer
var currentBehaviorState: EnemyServer.BehaviorStates : set = _behavior_state_update
var enemyIdleArea: Rect2
# //

var idleBehaviorMovementState: CharacterStateMachine.MovementStates
var idleMovementWaitTime: SceneTreeTimer

var processDelayCounter: Dictionary[StringName, float] = {
	"chase_player_upd_pos": 0.0,
	"attack_player_upd_pos": 0.0,
}

func _setup() -> void:
	assert(EnemyName)
	
	AnimSprite = %AnimatedSprite2D
	HitBoxArea = %HitBox
	AnimState = %EnemyAnimationState
	
	OppCollisionMask = 2
	
	healthPoint = 30
	JUMP_FORCE = 605
	SPEED = movementSpeedState["behavior_idle"]
	
	DetectArea.set_collision_mask_value(OppCollisionMask, true)
	DetectArea.body_entered.connect(_on_action_on_detect_area.bind(&"entered"))
	DetectArea.body_exited.connect(_on_action_on_detect_area.bind(&"exited"))
	
	EscapeArea.set_collision_mask_value(OppCollisionMask, true)
	EscapeArea.body_entered.connect(_on_action_on_escape_area.bind(&"entered"))
	EscapeArea.body_exited.connect(_on_action_on_escape_area.bind(&"exited"))
	
	NavAgent.target_reached.connect(_on_target_pos_reached)
	NavAgent.navigation_finished.connect(_on_navigation_finished)
	NavAgent.link_reached.connect(_on_link_reached)
	
	allowMovement = func() -> bool:
		return (currentDisabilityState == CharacterStateMachine.DisabilityStates.NULL and
		 currentActionState == CharacterStateMachine.ActionStates.NULL and not onLandingDelay) #and not attackPrepMoment)
	
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
				error[1] = true
	
	
	if error.all(func(i): return i == true):
		print("ENEMY IS STUCK")
		propertyCache["position"].clear()
		propertyCache["direction"].clear()
		_set_nav_target_pos(NavAgent.target_position)



func _physics_process(_delta: float) -> void:
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if isNavigationOngoing and allowMovement.call():
		if handleLinkReached:
			velocity.x = 0
			
			var entryPos: Vector2 = navLinkDetails["link_entry_position"]
			var exitPos: Vector2 = navLinkDetails["link_exit_position"]
			var linkDirection: Vector2 = entryPos.direction_to(exitPos)
			
			SPEED = movementSpeedState["movement_jump"]
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
	if currentMovementState == CharacterStateMachine.MovementStates.ON_AIR: return
	NavAgent.target_position = NavigationServer2D.map_get_closest_point(Global.NavMapRid, target_pos)
	isNavigationOngoing = true
	nextPathPos = NavAgent.get_next_path_position()
	#return NavAgent.get_current_navigation_path()


# Called in "enemy_animation_state", when the enemy just landed on the ground
func _on_enemy_is_on_floor() -> void:
	onLandingDelay = true
	get_tree().create_timer(landingDelayTime).timeout.connect(func(): onLandingDelay = false)
	if NavAgent.is_navigation_finished(): isNavigationOngoing = false
	
	if currentBehaviorState == EnemyServer.BehaviorStates.IDLE:
		#AnimSprite.speed_scale = 0.5
		_set_animation_fps("behavior_idle")
		SPEED = movementSpeedState["behavior_idle"]
	elif not currentBehaviorState == EnemyServer.BehaviorStates.IDLE:
		#AnimSprite.speed_scale = 1.0
		_set_animation_fps("behavior_chase")
		SPEED = movementSpeedState["behavior_chase"]
# //

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
	#else:
		#currentActionState = CharacterStateMachine.ActionStates.NULL
	



func _on_action_on_detect_area(_body: Node2D, action: StringName) -> void:
	if Ovr_Detection: return
	if action == &"entered":
		isPlayerDetected = true
		EnemyServer.enemy_call(self, EnemyServer.ImpressionStates.PLAYER_FOUND)
	elif action == &"exited": pass
		#print("DETECT EXIT")
	



func _on_action_on_escape_area(_body: Node2D, action: StringName) -> void:
	if Ovr_Detection: return
	if action == &"entered": pass
		#print("ESCAPE ENTER")
	elif action == &"exited":
		#print("ESCAPE EXIT")
		isPlayerDetected = false
		EnemyServer.enemy_call(self, EnemyServer.ImpressionStates.PLAYER_NOT_FOUND)
	



#region Navigation Signals
func _on_target_pos_reached() -> void: pass
	#print("TARGET REACHED")


func _on_navigation_finished() -> void:
	print("NAV FINISHED")
	
	if not currentMovementState == CharacterStateMachine.MovementStates.ON_AIR: isNavigationOngoing = false
	
	#nextPathPos = NavAgent.get_next_path_position()
	#print("dist_to_next_path: %s" % nextPathPos.distance_to(global_position))
	#print("next_path_pos: %s" % str(nextPathPos))
	#print("glob_pos: %s" % global_position)
	


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



func handle_bodies_in_hit_box(body: Node2D, action: String) -> void:
	super.handle_bodies_in_hit_box(body, action)
	isNavigationOngoing = false



func damage(body: Node2D, value: float) -> void:
	super.damage(body, value)
	
	if healthPoint <= 0:
		EnemyServer.enemy_call(self, EnemyServer.ImpressionStates.AM_DEAD)
		get_tree().create_timer(DESPAWN_TIME).timeout.connect(func(): self.queue_free())



func _set_animation_fps(anim_state_key: StringName) -> void:
	assert(animFpsState.has(anim_state_key))
	var spriteFrames := AnimSprite.sprite_frames
	var anim_name: String
	
	match anim_state_key:
		"behavior_idle": anim_name = "move"
		"behavior_chase": anim_name = "move"
	
	spriteFrames.set_animation_speed(anim_name, animFpsState[anim_state_key])




func _behavior_state_update(state: EnemyServer.BehaviorStates) -> void:
	if Ovr_behavior: return
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	
	currentBehaviorState = state
	print("behavior_change: %s" % EnemyServer.BehaviorStates.find_key(state))
	
	
	if is_instance_valid(idleMovementWaitTime):
		if idleMovementWaitTime.timeout.is_connected(_update_idle_behavior_movement):
			idleMovementWaitTime.timeout.disconnect(_update_idle_behavior_movement)
	
	
	if state == EnemyServer.BehaviorStates.IDLE:
		#AnimSprite.speed_scale = 0.5
		_set_animation_fps("behavior_idle")
		SPEED = movementSpeedState["behavior_idle"]
		isNavigationOngoing = false
		idleBehaviorMovementState = CharacterStateMachine.MovementStates.IDLE
		_create_idle_movement_wait_timer()
		#get_tree().create_timer(randf_range(IDLE_STAND_TIME_RANGE[0], IDLE_STAND_TIME_RANGE[1])).timeout.connect(_update_idle_behavior_movement)
	elif state == EnemyServer.BehaviorStates.CHASE:
		#AnimSprite.speed_scale = 1.0
		_set_animation_fps("behavior_chase")
		SPEED = movementSpeedState["behavior_chase"]
	elif state == EnemyServer.BehaviorStates.ATTACK:
		_set_animation_fps("behavior_chase")
		SPEED = movementSpeedState["behavior_chase"]


func behavior_state_checker(delta: float) -> void:
	if Ovr_behavior: return
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	
	if currentBehaviorState == EnemyServer.BehaviorStates.IDLE:
		if idleBehaviorMovementState == CharacterStateMachine.MovementStates.MOVING:
			if not isNavigationOngoing:
				#get_tree().create_timer(randf_range(IDLE_STAND_TIME_RANGE[0], IDLE_STAND_TIME_RANGE[1])).timeout.connect(_update_idle_behavior_movement)
				_create_idle_movement_wait_timer()
				idleBehaviorMovementState = CharacterStateMachine.MovementStates.IDLE
	elif currentBehaviorState == EnemyServer.BehaviorStates.CHASE:
		var delayTime := 0.15
		if processDelayCounter["chase_player_upd_pos"] == 0.0:
			#print("FOLLOW PLAYER")
			var dirToPlayer := signf(global_position.x - Global.PlayerPos.x)
			var targetPos := Vector2(Global.PlayerPos.x + (dirToPlayer * backupDistance), Global.PlayerPos.y)
			if global_position.distance_to(targetPos) > NavAgent.target_desired_distance:
				_set_nav_target_pos(targetPos)
		
		processDelayCounter["chase_player_upd_pos"] += delta
		if processDelayCounter["chase_player_upd_pos"] > delayTime:
			processDelayCounter["chase_player_upd_pos"] = 0.0
	elif currentBehaviorState == EnemyServer.BehaviorStates.ATTACK:
		var delayTime := 0.15
		if processDelayCounter["attack_player_upd_pos"] == 0.0:
			#print("FOLLOW PLAYER")
			#global_position.distance_to(Global.PlayerPos) > NavAgent.target_desired_distance
			if not bodiesInHitBox.has(Global.Player):
				_set_nav_target_pos(Global.PlayerPos)
		
		processDelayCounter["attack_player_upd_pos"] += delta
		if processDelayCounter["attack_player_upd_pos"] > delayTime:
			processDelayCounter["attack_player_upd_pos"] = 0.0


func _create_idle_movement_wait_timer() -> void:
	var waitTime: float = randf_range(IDLE_STAND_TIME_RANGE[0], IDLE_STAND_TIME_RANGE[1])
	idleMovementWaitTime = get_tree().create_timer(waitTime)
	idleMovementWaitTime.timeout.connect(_update_idle_behavior_movement)



func _update_idle_behavior_movement() -> void:
	if currentBehaviorState == EnemyServer.BehaviorStates.IDLE:
		_set_nav_target_pos(_rand_pos_in_idle_area())
		idleBehaviorMovementState = CharacterStateMachine.MovementStates.MOVING
