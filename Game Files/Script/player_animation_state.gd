extends Node

#@onready var Player: CharacterBody2D = $".."
@onready var AnimSprite: AnimatedSprite2D = $"../AnimatedSprite2D"

var PlayerSpriteFrame: SpriteFrames = preload("res://Resources/Sprite Frames/player_frames.tres")

var currentState := {
	Player.AnimStates.MOVEMENT : null,
	Player.AnimStates.ACTION : null,
	Player.AnimStates.DISABILITY : null
}

var newState := {
	Player.AnimStates.MOVEMENT : null,
	Player.AnimStates.ACTION : null,
	Player.AnimStates.DISABILITY : null
}

var processState := {
	Player.AnimStates.MOVEMENT : false,
	Player.AnimStates.ACTION : false,
	Player.AnimStates.DISABILITY : false
}

#var currentMovementState: Player.MovementStates
#var newMovementState: Player.MovementStates
#var currentActionState: Player.ActionStates
#var newActionState: Player.ActionStates

#var processActionState: bool
#var processMovementState: bool

func _process(_delta: float) -> void:
	if processState[Player.AnimStates.MOVEMENT]: _process_movement_state(_delta)
	if processState[Player.AnimStates.ACTION]: _process_action_state(_delta)



func _player_movement_state_update(state: Player.MovementStates) -> void:
	#print("Entered Movement State: %s" % Player.MovementStates.find_key(state))
	#print("Current state: %s" % Player.MovementStates.find_key(currentState))
	
	processState[Player.AnimStates.MOVEMENT] = false
	newState[Player.AnimStates.MOVEMENT] = state
	
	if currentState[Player.AnimStates.MOVEMENT] == null:
		enter_new_movement_state(state)
	elif not currentState[Player.AnimStates.MOVEMENT] == state:
		_exit_movement_state(currentState[Player.AnimStates.MOVEMENT])
	


func _player_action_state_update(state: Player.ActionStates) -> void:
	processState[Player.AnimStates.ACTION] = false
	newState[Player.AnimStates.ACTION] = state
	
	print("Update action state: %s" % Player.ActionStates.find_key(state))
	if currentState[Player.AnimStates.ACTION] == null:
		print("first action call")
		enter_new_action_state(state)
	elif not currentState[Player.AnimStates.ACTION] == state:
		print("exit from current state")
		_exit_action_state(currentState[Player.AnimStates.ACTION])
	



#region Movement State
func enter_new_movement_state(new_state: Player.MovementStates) -> void:
	currentState[Player.AnimStates.MOVEMENT] = new_state
	#print("Anim Finished, Enter new state: %s" % Player.MovementStates.find_key(new_state))
	_enter_movement_state(new_state)
	processState[Player.AnimStates.MOVEMENT] = true
	



func _enter_movement_state(state: Player.MovementStates) -> void:
	if not currentState[Player.AnimStates.ACTION] == Player.ActionStates.NULL:
		match state:
			Player.MovementStates.IDLE:
				AnimSprite.play("idle")
				#_anim_offset_check("idle")
			Player.MovementStates.RUNNING:
				AnimSprite.play("run")
				#_anim_offset_check("run")
			Player.MovementStates.ON_AIR:
				AnimSprite.play("jump")
				#_anim_offset_check("jump")
		


func _process_movement_state(_delta: float) -> void:
	if currentState[Player.AnimStates.ACTION] == Player.ActionStates.NULL: return
	
	pass



func _exit_movement_state(state: Player.MovementStates) -> void:
	#print("entered exit...")
	
	var skipAnimation: bool = false
	if not currentState[Player.AnimStates.ACTION] == Player.ActionStates.NULL:
		AnimSprite.stop()
		match state:
			Player.MovementStates.RUNNING:
				AnimSprite.play("stop")
				
				if newState[Player.AnimStates.MOVEMENT] == Player.MovementStates.ON_AIR: skipAnimation = true
			Player.MovementStates.ON_AIR:
				AnimSprite.play_backwards("jump")
		
		
		if AnimSprite.is_playing() and not skipAnimation:
			if PlayerSpriteFrame.get_animation_loop_mode(AnimSprite.animation) == SpriteFrames.LoopMode.LOOP_NONE:
				await AnimSprite.animation_finished
	
	enter_new_movement_state(newState[Player.AnimStates.MOVEMENT])
#endregion




#region Action State
func enter_new_action_state(new_state: Player.ActionStates) -> void:
	currentState[Player.AnimStates.ACTION] = new_state
	print("enter new action state: %s" % Player.ActionStates.find_key(new_state))
	
	if not new_state == Player.ActionStates.NULL:
		_enter_action_state(new_state)
		processState[Player.AnimStates.ACTION] = true
	



func _enter_action_state(state: Player.ActionStates) -> void:
	print("enter action state: %s" % Player.ActionStates.find_key(state))
	match state:
		Player.ActionStates.ATTACK:
			AnimSprite.play("attack")
			#_anim_offset_check("attack")
		Player.ActionStates.JUMP_ATTACK:
			AnimSprite.play("jump_attack")
			#_anim_offset_check("jump_attack")
		Player.ActionStates.HEAVY_ATTACK:
			AnimSprite.play("heavy_attack")
			#_anim_offset_check("heavy_attack")
		


func _process_action_state(_delta: float) -> void:
	
	
	pass



func _exit_action_state(state: Player.ActionStates) -> void:
	#print("entered exit...")
	var skipAnimation: bool = false
	print("exit action state: %s" % Player.ActionStates.find_key(state))
	AnimSprite.stop()
	match state:
		Player.ActionStates.ATTACK:
			pass
		Player.ActionStates.JUMP_ATTACK:
			pass
	
	
	if AnimSprite.is_playing() and not skipAnimation:
		if PlayerSpriteFrame.get_animation_loop_mode(AnimSprite.animation) == SpriteFrames.LoopMode.LOOP_NONE:
			await AnimSprite.animation_finished
	
	enter_new_action_state(newState[Player.AnimStates.ACTION])
#endregion
