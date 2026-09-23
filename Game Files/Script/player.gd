extends CharacterBase

const ATTACK_SPAM_TIME: float = 0.4
const HEAVY_ATTACK_HOLD_TIME: float = 0.25

var attackTimeCount: Array[float] = [0.0, 0.0]


func _setup() -> void:
	AnimState = %PlayerAnimationState
	HitBoxArea = %HitBox
	AnimSprite = %AnimatedSprite2D
	OppCollisionMask = 3
	
	allowMovement = func() -> bool:
		return (currentDisabilityState == CharacterStateMachine.DisabilityStates.NULL and
		 not currentActionState == CharacterStateMachine.ActionStates.SECOND_ATTACK)
	



func _process(delta: float) -> void:
	Global.PlayerPos = global_position
	super._process(delta)
	


func _physics_process(_delta: float) -> void:
	if currentDisabilityState == CharacterStateMachine.DisabilityStates.DEAD: return
	
	if not is_on_floor():
		velocity.y += Global.GRAVITY
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -1 * JUMP_FORCE
	
	direction = Input.get_axis("left", "right")
	
	if direction and allowMovement.call():
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
	
	move_and_slide()



func action_state_check(delta: float) -> void:
	attackTimeCount[0] += delta
	
	if Input.is_action_just_pressed("action"):
		#print('ACTION')
		attackTimeCount[0] = 0.0
		currentActionState = CharacterStateMachine.ActionStates.ATTACK
	
	if Input.is_action_pressed("action"):
		attackTimeCount[1] += delta
		if attackTimeCount[1] > HEAVY_ATTACK_HOLD_TIME:
			#print("HEAVY ACTION")
			currentActionState = CharacterStateMachine.ActionStates.SECOND_ATTACK
	else: attackTimeCount[1] = 0.0
	
	if attackTimeCount[0] > ATTACK_SPAM_TIME and not Input.is_action_pressed("action"):
		#print("NO ACTION")
		currentActionState = CharacterStateMachine.ActionStates.NULL
	
