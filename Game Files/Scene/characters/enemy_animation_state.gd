extends CharacterStateMachine

const ATTACK_COOLDOWN_TIME: float = 2.0


func _enter_state_anim_logic(anim_state: AnimStates, state: int) -> void:
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.IDLE:
				AnimSprite.play("idle")
			MovementStates.MOVING:
				AnimSprite.play("move")
	elif anim_state == AnimStates.ACTION:
		match state:
			ActionStates.NULL: # MANDATORY
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
	elif anim_state == AnimStates.DISABILITY:
		match state:
			DisabilityStates.NULL: # MANDATORY
				Parent.currentDisabilityState = DisabilityStates.NULL
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			DisabilityStates.DEAD:
				AnimSprite.play("death")



func _process_state_anim_logic(anim_state: AnimStates, state: int) -> void:
	if anim_state == AnimStates.DISABILITY:
		match state:
			DisabilityStates.HURT:
				if processStepCall == 0:
					AnimSprite.play("hurt")
					processStepCall += 1
				elif not AnimSprite.is_playing() and processStepCall == 1:
					processStepCall += 1
					newState[AnimStates.DISABILITY] = DisabilityStates.NULL
					exit_state(AnimStates.DISABILITY)
	elif anim_state == AnimStates.ACTION:
		match state:
			ActionStates.ATTACK:
				if processStepCall == 0:
					AnimSprite.play("attack")
					processStepCall += 1
				elif AnimSprite.frame == AttackStrikeFrame[ActionStates.ATTACK] and processStepCall == 1:
					Parent.damage_bodies_in_hit_box()
					processStepCall += 1
				elif not AnimSprite.is_playing() and processStepCall == 2:
					processStepCall += 1
					Parent.currentActionState = ActionStates.NULL
					newState[AnimStates.ACTION] = ActionStates.NULL
					exit_state(AnimStates.ACTION)
