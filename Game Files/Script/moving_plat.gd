extends AnimatableBody2D

@export var tileDistance: int = 15
@export var direction: Vector2i = Vector2i(1, 0)
@export var duration: float = 13
@export var platSize: int = 1
@export var autoStart: bool = true
@export var oneStop: bool = false

const TILE_SIZE: float = 32
const PlatImg = preload("res://Assets/platform.png")

var AtlasText: AtlasTexture = AtlasTexture.new()
var ColRect: RectangleShape2D = RectangleShape2D.new()

func _ready() -> void:
	AtlasText.atlas = PlatImg
	AtlasText.region.position = Vector2.ZERO
	AtlasText.region.size = Vector2(TILE_SIZE * platSize, TILE_SIZE)
	
	ColRect.size = Vector2(TILE_SIZE * platSize, 8.0)
	
	$Sprite2D.texture = AtlasText
	$CollisionShape2D.shape = ColRect
	
	
	if autoStart: move()


func move() -> void:
	var distance: float = tileDistance * TILE_SIZE
	var pos: Vector2 = position
	
	pos += (distance * direction)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", pos, duration)
	await tween.finished
	direction *= -1
	if not oneStop: move()
	
