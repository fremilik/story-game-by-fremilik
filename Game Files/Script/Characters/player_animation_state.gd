extends CharacterStateMachine


func _enter_state_anim_logic(anim_state: AnimStates, state: int) -> void:
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.IDLE:
				AnimSprite.play("idle")
			MovementStates.MOVING:
				AnimSprite.play("move")
			MovementStates.ON_AIR:
				AnimSprite.play("on_air")
	elif anim_state == AnimStates.ACTION:
		match state:
			ActionStates.NULL: # MANDATORY
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			ActionStates.ATTACK:
				currentFrameStrike = 0
				AnimSprite.play("attack")
	elif anim_state == AnimStates.DISABILITY:
		match state:
			DisabilityStates.NULL: # MANDATORY
				Parent.currentDisabilityState = DisabilityStates.NULL
				enter_state(AnimStates.MOVEMENT, newState[AnimStates.MOVEMENT])
			DisabilityStates.DEAD:
				AnimSprite.play("death")




func _process_state_anim_logic(anim_state: AnimStates, state: int) -> void:
	if anim_state == AnimStates.ACTION:
		match state:
			ActionStates.ATTACK:
				if AttackStrikeFrame[ActionStates.ATTACK].has(AnimSprite.frame) and not currentFrameStrike == AnimSprite.frame:
					print("STRIKE")
					currentFrameStrike = AnimSprite.frame
					Parent.damage_bodies_in_hit_box()
					 
			ActionStates.SECOND_ATTACK:
				#print("heavy attack process")
				if not AnimSprite.is_playing() and processStepCall == 0:
					#print("INITAILIZE ATTCK")
					AnimSprite.play("heavy_attack")
					processStepCall += 1
				elif AnimSprite.frame == AttackStrikeFrame[ActionStates.SECOND_ATTACK] - 1 and processStepCall == 1:
					#print("PAUSE FRAME")
					AnimSprite.pause()
					processStepCall += 1
	
	elif anim_state == AnimStates.DISABILITY:
		match state:
			DisabilityStates.HURT:
				if processStepCall == 0:
					AnimSprite.play("hurt")
					processStepCall += 1
				elif not AnimSprite.is_playing() and processStepCall == 1:
					processStepCall += 1
					newState[AnimStates.DISABILITY] = DisabilityStates.NULL
					exit_state(AnimStates.DISABILITY)



func _exit_state_anim_logic(anim_state: AnimStates, state: int) -> bool:
	if anim_state == AnimStates.MOVEMENT:
		match state:
			MovementStates.MOVING:
				if newState[AnimStates.MOVEMENT] == MovementStates.ON_AIR: return true
				else: AnimSprite.play("stop")
			MovementStates.ON_AIR:
				AnimSprite.play_backwards("on_air")
	elif anim_state == AnimStates.ACTION:
		match state:
			ActionStates.SECOND_ATTACK:
				if AnimSprite.frame == AttackStrikeFrame[ActionStates.SECOND_ATTACK] - 1:
					#print("Player direction: %s" % Player.initDirection)
					AnimSprite.play("", 2.7)
					get_tree().create_timer(0.1).timeout.connect(func(): %PlayerAttackWave.activate(int(Parent.initDirection)))
				else: AnimSprite.stop()
	
	return false
