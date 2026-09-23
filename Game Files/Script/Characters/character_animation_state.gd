extends Node
class_name CharacterStateMachine

@export var Parent: CharacterBody2D
@export var AnimSprite: AnimatedSprite2D
@export var ParentSpriteFrame: SpriteFrames
@export var AttackStrikeFrame: Dictionary[ActionStates, Variant]


var stateFirstCheck: Dictionary[AnimStates, bool] = {
	AnimStates.MOVEMENT : false,
	AnimStates.ACTION : false,
	AnimStates.DISABILITY : false
}

var currentState: Dictionary[AnimStates, int] = {
	AnimStates.MOVEMENT : MovementStates.IDLE,
	AnimStates.ACTION : ActionStates.NULL,
	AnimStates.DISABILITY : DisabilityStates.NULL
}

var newState: Dictionary[AnimStates, int] = {
	AnimStates.MOVEMENT : MovementStates.IDLE,
	AnimStates.ACTION : ActionStates.NULL,
	AnimStates.DISABILITY : DisabilityStates.NULL
}

var processState: Dictionary[AnimStates, bool] = {
	AnimStates.MOVEMENT : false,
	AnimStates.ACTION : false,
	AnimStates.DISABILITY : false
}

var aboutToExitCurrentState: Dictionary[AnimStates, bool] = {
	AnimStates.MOVEMENT : false,
	AnimStates.ACTION : false,
	AnimStates.DISABILITY : false
}

var processStepCall: int
var currentFrameStrike: int
var attackCooldownTimer: Timer


enum AnimStates {MOVEMENT, ACTION, DISABILITY}
enum MovementStates {IDLE, MOVING, ON_AIR}
enum ActionStates {NULL, ATTACK, SECOND_ATTACK, PROJECTILE_ATTACK}
enum DisabilityStates {NULL, HURT, DEAD}


func _ready() -> void:
	assert(Parent)
	assert(AnimSprite)
	assert(ParentSpriteFrame)
	
	attackCooldownTimer = Timer.new()
	attackCooldownTimer.one_shot = true
	Parent.add_child.call_deferred(attackCooldownTimer)
	


func _process(_delta: float) -> void:
	pass
	
	if currentState[AnimStates.DISABILITY] == DisabilityStates.DEAD: return
	_check_for_state_update()
	process_state()
	


func _check_for_state_update() -> void:
	if not newState[AnimStates.MOVEMENT] == Parent.currentMovementState:
		#print("new MOVEMENT")
		newState[AnimStates.MOVEMENT] = Parent.currentMovementState
		
		if not stateFirstCheck[AnimStates.MOVEMENT]:
			stateFirstCheck[AnimStates.MOVEMENT] = true
			enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
		elif not aboutToExitCurrentState[AnimStates.MOVEMENT]:
			if (currentState[AnimStates.ACTION] == ActionStates.NULL and
			 currentState[AnimStates.DISABILITY] == DisabilityStates.NULL): exit_state(AnimStates.MOVEMENT)
	
	
	if not newState[AnimStates.ACTION] == Parent.currentActionState:
		#print("new ACTION")
		newState[AnimStates.ACTION] = Parent.currentActionState
		
		if not stateFirstCheck[AnimStates.ACTION]:
			stateFirstCheck[AnimStates.ACTION] = true
			enter_state(AnimStates.ACTION, newState[AnimStates.ACTION])
		elif not aboutToExitCurrentState[AnimStates.ACTION]:
			if currentState[AnimStates.DISABILITY] == DisabilityStates.NULL: exit_state(AnimStates.ACTION)


func apply_disable_state(anim_state: DisabilityStates) -> void:
	newState[AnimStates.DISABILITY] = anim_state
	enter_state(AnimStates.DISABILITY, anim_state)




func enter_state(anim_state: AnimStates, state: int) -> void:
	AnimSprite.stop()
	if anim_state == AnimStates.ACTION: processState[AnimStates.MOVEMENT] = false
	elif anim_state == AnimStates.DISABILITY: processState[AnimStates.MOVEMENT] = false; processState[AnimStates.ACTION] = false
	
	_enter_state_anim_logic(anim_state, state)
	
	currentState[anim_state] = state
	aboutToExitCurrentState[anim_state] = false
	
	currentFrameStrike = 0
	processStepCall = 0
	processState[anim_state] = true
	



func process_state() -> void:
	#if processState[AnimStates.DISABILITY]:
		#match currentState[AnimStates.DISABILITY]:
			#DisabilityStates.HURT:
				#if processStepCall == 0:
					#AnimSprite.play("hurt")
					#processStepCall += 1
				#elif not AnimSprite.is_playing() and processStepCall == 1:
					#newState[AnimStates.DISABILITY] = DisabilityStates.NULL
					#exit_state(AnimStates.DISABILITY)
	
	if processState[AnimStates.MOVEMENT]: _process_state_anim_logic(AnimStates.MOVEMENT, currentState[AnimStates.MOVEMENT])
	elif processState[AnimStates.ACTION]: _process_state_anim_logic(AnimStates.ACTION, currentState[AnimStates.ACTION])
	elif processState[AnimStates.DISABILITY]: _process_state_anim_logic(AnimStates.DISABILITY, currentState[AnimStates.DISABILITY])
	


func exit_state(anim_state: AnimStates) -> void:
	processState[anim_state] = false
	if anim_state == AnimStates.MOVEMENT: aboutToExitCurrentState[AnimStates.MOVEMENT] = true
	elif anim_state == AnimStates.ACTION: aboutToExitCurrentState[AnimStates.ACTION] = true
	elif anim_state == AnimStates.DISABILITY: aboutToExitCurrentState[AnimStates.DISABILITY] = true
	
	var skipAnimation: bool
	skipAnimation = _exit_state_anim_logic(anim_state, currentState[anim_state])
	
	if AnimSprite.is_playing() and not skipAnimation:
			if ParentSpriteFrame.get_animation_loop_mode(AnimSprite.animation) == SpriteFrames.LoopMode.LOOP_NONE:
				await AnimSprite.animation_finished
	
	
	if anim_state == AnimStates.MOVEMENT: enter_state(anim_state, newState[AnimStates.MOVEMENT])
	elif anim_state == AnimStates.ACTION: enter_state(anim_state, newState[AnimStates.ACTION])
	elif anim_state == AnimStates.DISABILITY: enter_state(anim_state, newState[AnimStates.DISABILITY])


func _enter_state_anim_logic(anim_state: AnimStates, state: int) -> void:
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
func _process_state_anim_logic(_anim_state: AnimStates, _state: int) -> void: pass
func _exit_state_anim_logic(_anim_state: AnimStates, _state: int) -> bool: return false # Return bool for animtion skip
