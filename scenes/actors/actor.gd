extends CharacterBody2D
class_name Actor

@export var actor_name: String = "Actor"
@export var background_color: Color = Color.WHITE
@export var foreground_color: Color = Color.BLACK
@export var collision_disabled: bool = true

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var foreground_sprite: Sprite2D = $ForegroundSprite
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_sprite.modulate = background_color
	foreground_sprite.modulate = foreground_color
	collision_shape_2d.disabled = collision_disabled

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
