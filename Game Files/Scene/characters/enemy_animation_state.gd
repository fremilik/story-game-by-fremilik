extends CharacterStateMachine


func _enter_state_anim_logic(anim_state: AnimStates, state: int) -> void:
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.IDLE:
				AnimSprite.play("idle")
			MovementStates.MOVING:
				AnimSprite.play("move")
	elif anim_state == AnimStates.ACTION: pass
		#match state:
			#ActionStates.NULL: # MANDATORY
				#enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			#ActionStates.ATTACK:
				#AnimSprite.play("attack")
	elif anim_state == AnimStates.DISABILITY:
		match state:
			DisabilityStates.NULL: # MANDATORY
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			DisabilityStates.DEAD:
				AnimSprite.play("death")



func _process_state_anim_logic(_anim_state: AnimStates, _state: int) -> void:
	if _anim_state == AnimStates.DISABILITY:
		match currentState[AnimStates.DISABILITY]:
			DisabilityStates.HURT:
				if processStepCall == 0:
					AnimSprite.play("hurt")
					processStepCall += 1
				elif not AnimSprite.is_playing() and processStepCall == 1:
					newState[AnimStates.DISABILITY] = DisabilityStates.NULL
					exit_state(AnimStates.DISABILITY)
