extends CharacterBody2D
class_name AbstractEnemy

@onready var AnimSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D

enum MovementForm {GROUND, AIR}
enum Directions {LEFT = -1, RIGHT = 1}

var JUMP_FORCE: float = 605

var EnemyName: String
var EnemyMovement: MovementForm
var offsetNodePos := {
	"off_platform_cast": 20
}

var initDirection: float
var direction: float

var nextPathPos: Vector2
var speed: float = 240
var isNavigationOngoing: bool = false
var handleLinkReached: bool = false
var navLinkDetails: Dictionary

var onAir: bool = false

func _ready() -> void:
	NavAgent.target_reached.connect(_on_target_pos_reached)
	NavAgent.navigation_finished.connect(_on_navigation_finished)
	NavAgent.link_reached.connect(_on_link_reached)




func _process(_delta: float) -> void:
	direction_check()
	movement_state_check()
	pass
	
	


var deltaCount: float
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if isNavigationOngoing:
		if handleLinkReached:
			velocity.x = 0
			
			var entryPos: Vector2 = navLinkDetails["link_entry_position"]
			var exitPos: Vector2 = navLinkDetails["link_exit_position"]
			var linkDirection: Vector2 = entryPos.direction_to(exitPos)
			
			#print("link reached; entry: %s| exit: %s| dotProd: %s" % [entryPos, exitPos, entryPos.dot(exitPos)])
			#print("link start pos: %s" % navLinkDetails["position"])
			
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
	if not velocity and is_on_floor(): # and not currentMovementState == MovementStates.IDLE:
		#currentMovementState = PlayerStateMachine.MovementStates.IDLE
		onAir = false
	elif velocity and is_on_floor(): # and not currentMovementState == MovementStates.RUNNING:
		#currentMovementState = PlayerStateMachine.MovementStates.RUNNING
		onAir = false
	elif not is_on_floor(): # and not currentMovementState == MovementStates.ON_AIR:
		#currentMovementState = PlayerStateMachine.MovementStates.ON_AIR
		onAir = true


func direction_check() -> void:
	if not initDirection == direction and direction:
		initDirection = direction
		
		match int(direction):
			Directions.LEFT:
				AnimSprite.flip_h = true
				%OffPlatformCast.position.x = -1 * offsetNodePos["off_platform_cast"]
				#HitBoxCol.position.x = -30
			Directions.RIGHT:
				AnimSprite.flip_h = false
				%OffPlatformCast.position.x = offsetNodePos["off_platform_cast"]
				#HitBoxCol.position.x = 30
		
