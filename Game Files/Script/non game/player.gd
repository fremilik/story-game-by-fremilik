extends CharacterBody3D

const SPEED = 9.0
const JUMP_VELOCITY = 5.7

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var movement: bool = true
var direction


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		#movement
	var hRot = $Camera3D.transform.basis.get_euler().y
	direction = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0, Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	direction = direction.rotated(Vector3.UP, hRot).normalized()
	
	
	if direction and movement:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()
