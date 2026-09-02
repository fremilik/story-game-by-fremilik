extends Node
class_name PlayerStateMachine

@onready var Player: CharacterBody2D = $".."
@onready var AnimSprite: AnimatedSprite2D = $"../AnimatedSprite2D"


const ATTACK_STRIKE_FRAME: Dictionary[ActionStates, int] = {
	ActionStates.HEAVY_ATTACK : 8
}

var PlayerSpriteFrame: SpriteFrames = preload("res://Resources/Sprite Frames/player_frames.tres")

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
enum MovementStates {IDLE, RUNNING, ON_AIR, HURT, DEAD}
enum ActionStates {NULL, ATTACK, ON_AIR_ATTACK, HEAVY_ATTACK}



func _process(_delta: float) -> void:
	pass
	_check_for_state_update()
	process_state()
	



func _check_for_state_update() -> void:
	if not newState[AnimStates.MOVEMENT] == Player.currentMovementState:
		print("new MOVEMENT")
		newState[AnimStates.MOVEMENT] = Player.currentMovementState
		
		if currentState[AnimStates.ACTION] == ActionStates.NULL:
			if currentState[AnimStates.MOVEMENT] == -1:
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			elif isInCurrentState[AnimStates.MOVEMENT]:
				exit_state(AnimStates.MOVEMENT)
	
	
	if not newState[AnimStates.ACTION] == Player.currentActionState:
		print("new ACTION")
		newState[AnimStates.ACTION] = Player.currentActionState
		
		if currentState[AnimStates.ACTION] == -1:
			enter_state(AnimStates.ACTION, newState[AnimStates.ACTION])
		elif isInCurrentState[AnimStates.ACTION]:
			exit_state(AnimStates.ACTION)
		



func enter_state(anim_state: AnimStates, state: int) -> void:
	AnimSprite.stop()
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.IDLE:
				AnimSprite.play("idle")
			MovementStates.RUNNING:
				AnimSprite.play("run")
			MovementStates.ON_AIR:
				AnimSprite.play("on_air")
	elif anim_state == AnimStates.ACTION:
		processState[AnimStates.MOVEMENT] = false
		match state:
			ActionStates.NULL:
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			ActionStates.ATTACK:
				AnimSprite.play("attack")
	
	currentState[anim_state] = state
	isInCurrentState[anim_state] = true
	
	processStepCall = 0
	processState[anim_state] = true
	



func process_state() -> void:
	#if processState[AnimStates.MOVEMENT]: pass
	
	if processState[AnimStates.ACTION]:
		match currentState[AnimStates.ACTION]:
			ActionStates.HEAVY_ATTACK:
				#print("heavy attack process")
				if not AnimSprite.is_playing() and processStepCall == 0:
					print("INITAILIZE ATTCK")
					AnimSprite.play("heavy_attack")
					processStepCall += 1
				elif AnimSprite.frame == ATTACK_STRIKE_FRAME[ActionStates.HEAVY_ATTACK] - 1 and processStepCall == 1:
					#print("PAUSE FRAME")
					AnimSprite.pause()
					processStepCall += 1
	



func exit_state(anim_state: AnimStates) -> void:
	processState[anim_state] = false
	
	var skipAnimation: bool
	if anim_state == AnimStates.MOVEMENT:
		isInCurrentState[AnimStates.MOVEMENT] = false
		#if currentState[AnimStates.ACTION] == ActionStates.NULL:
		match currentState[AnimStates.MOVEMENT]:
			MovementStates.RUNNING:
				if newState[AnimStates.MOVEMENT] == MovementStates.ON_AIR:
					skipAnimation = true
				else: AnimSprite.play("stop")
			MovementStates.ON_AIR:
				AnimSprite.play_backwards("on_air")
		
	elif anim_state == AnimStates.ACTION:
		isInCurrentState[AnimStates.ACTION] = false
		
		match currentState[AnimStates.ACTION]:
			ActionStates.HEAVY_ATTACK:
				if AnimSprite.frame == ATTACK_STRIKE_FRAME[ActionStates.HEAVY_ATTACK] - 1:
					print("Player direction: %s" % Player.initDirection)
					AnimSprite.play("", 2.7)
					await get_tree().create_timer(0.1).timeout
					%PlayerAttackWave.activate(int(Player.initDirection))
		
	
	if AnimSprite.is_playing() and not skipAnimation:
			if PlayerSpriteFrame.get_animation_loop_mode(AnimSprite.animation) == SpriteFrames.LoopMode.LOOP_NONE:
				await AnimSprite.animation_finished
	
	
	if anim_state == AnimStates.MOVEMENT: enter_state(anim_state, newState[AnimStates.MOVEMENT])
	elif anim_state == AnimStates.ACTION: enter_state(anim_state, newState[AnimStates.ACTION])
