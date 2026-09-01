extends Area2D

@onready var Particle: CPUParticles2D = $CPUParticles2D

const SPEED: float = 200

var isDestroyed: bool = false
var playerInArea: bool = false


func _physics_process(delta: float) -> void:
	if not isDestroyed:
		position.y += SPEED * delta


func _on_detect_area_body_entered(body: Node2D) -> void:
	isDestroyed = true
	$Sprite2D.visible = false
	Particle.emitting = true
	if playerInArea: Global.Player.damage(2.0)
	await get_tree().create_timer(Particle.lifetime).timeout
	self.queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		playerInArea = true


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player:
		playerInArea = false
