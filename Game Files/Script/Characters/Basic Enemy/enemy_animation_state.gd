extends Node
class_name EnemyStateMachine

@export var Parent: CharacterBody2D
@export var AnimSprite: AnimatedSprite2D
@export var ObjectSpriteFrame: SpriteFrames

var currentState: Dictionary[AnimStates, int] = {
	AnimStates.MOVEMENT : -1,
	AnimStates.ACTION : -1,
	AnimStates.DISABILITY : -1
}

var newState: Dictionary[AnimStates, int] = {
	AnimStates.MOVEMENT : -1,
	AnimStates.ACTION : -1,
	AnimStates.DISABILITY : -1
}

var processState: Dictionary[AnimStates, bool] = {
	AnimStates.MOVEMENT : false,
	AnimStates.ACTION : false,
	AnimStates.DISABILITY : false
}

var isInCurrentState: Dictionary[AnimStates, bool] = {
	AnimStates.MOVEMENT : false,
	AnimStates.ACTION : false,
	AnimStates.DISABILITY : false
}

var processStepCall: int

enum AnimStates {MOVEMENT, ACTION, DISABILITY}
enum MovementStates {IDLE, MOVING, ON_AIR}
enum ActionStates {NULL, ATTACK, ON_AIR_ATTACK, HEAVY_ATTACK}
enum DisabilityStates {NULL, HURT, DEAD}


func _ready() -> void:
	assert(EnemySpriteFrame)


func _process(_delta: float) -> void:
	pass
	
	if currentState[AnimStates.DISABILITY] == DisabilityStates.DEAD: return
	_check_for_state_update()
	process_state()
	


func _check_for_state_update() -> void:
	if not newState[AnimStates.MOVEMENT] == Enemy.currentMovementState:
		#print("new MOVEMENT")
		newState[AnimStates.MOVEMENT] = Enemy.currentMovementState
		
		if (currentState[AnimStates.ACTION] == ActionStates.NULL and
		 currentState[AnimStates.DISABILITY] == DisabilityStates.NULL):
			if currentState[AnimStates.MOVEMENT] == -1:
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			elif isInCurrentState[AnimStates.MOVEMENT]:
				exit_state(AnimStates.MOVEMENT)
	
	
	if not newState[AnimStates.ACTION] == Enemy.currentActionState:
		#print("new ACTION")
		newState[AnimStates.ACTION] = Enemy.currentActionState
		
		if currentState[AnimStates.DISABILITY] == DisabilityStates.NULL:
			if currentState[AnimStates.ACTION] == -1:
				enter_state(AnimStates.ACTION, newState[AnimStates.ACTION])
			elif isInCurrentState[AnimStates.ACTION]:
				exit_state(AnimStates.ACTION)
	
	
	#if not newState[AnimStates.DISABILITY] == Enemy.currentDisabilityState:
		##print("new ACTION")
		#newState[AnimStates.DISABILITY] = Enemy.currentDisabilityState
		#
		#if currentState[AnimStates.DISABILITY] == -1:
			#enter_state(AnimStates.DISABILITY, newState[AnimStates.DISABILITY])
		#elif isInCurrentState[AnimStates.DISABILITY]:
			#exit_state(AnimStates.DISABILITY)



func apply_disable_state(anim_state: DisabilityStates) -> void:
	newState[AnimStates.DISABILITY] = anim_state
	enter_state(AnimStates.DISABILITY, anim_state)




func enter_state(anim_state: AnimStates, state: int) -> void:
	AnimSprite.stop()
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.IDLE:
				AnimSprite.play("idle")
			MovementStates.MOVING:
				AnimSprite.play("move")
	elif anim_state == AnimStates.ACTION:
		processState[AnimStates.MOVEMENT] = false
		#match state:
			#ActionStates.NULL:
				#enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			#ActionStates.ATTACK:
				#AnimSprite.play("attack")
	elif anim_state == AnimStates.DISABILITY:
		processState[AnimStates.MOVEMENT] = false
		processState[AnimStates.ACTION] = false
		
		match state:
			DisabilityStates.NULL:
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			DisabilityStates.DEAD:
				AnimSprite.play("death")
	
	currentState[anim_state] = state
	isInCurrentState[anim_state] = true
	
	processStepCall = 0
	processState[anim_state] = true
	



func process_state() -> void:
	if processState[AnimStates.DISABILITY]:
		match currentState[AnimStates.DISABILITY]:
			DisabilityStates.HURT:
				if processStepCall == 0:
					AnimSprite.play("hurt")
					processStepCall += 1
				elif not AnimSprite.is_playing() and processStepCall == 1:
					newState[AnimStates.DISABILITY] = DisabilityStates.NULL
					exit_state(AnimStates.DISABILITY)
				
	



func exit_state(anim_state: AnimStates) -> void:
	processState[anim_state] = false
	
	var skipAnimation: bool
	if anim_state == AnimStates.MOVEMENT:
		isInCurrentState[AnimStates.MOVEMENT] = false
		if currentState[AnimStates.ACTION] == ActionStates.NULL: pass
	elif anim_state == AnimStates.ACTION:
		isInCurrentState[AnimStates.ACTION] = false
	
	
	if AnimSprite.is_playing() and not skipAnimation:
			if EnemySpriteFrame.get_animation_loop_mode(AnimSprite.animation) == SpriteFrames.LoopMode.LOOP_NONE:
				await AnimSprite.animation_finished
	
	
	if anim_state == AnimStates.MOVEMENT: enter_state(anim_state, newState[AnimStates.MOVEMENT])
	elif anim_state == AnimStates.ACTION: enter_state(anim_state, newState[AnimStates.ACTION])
	elif anim_state == AnimStates.DISABILITY: enter_state(anim_state, newState[AnimStates.DISABILITY])
