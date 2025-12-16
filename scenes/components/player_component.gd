extends Node2D
class_name PlayerComponent

signal pit_collision(depth: int)

@export var speed: int = 100

var actor: Actor
var can_move: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# must be a direct child of actor node
	actor = get_parent()

func _physics_process(_delta: float) -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	actor.velocity = input_direction * speed
	if can_move and not Globals.game_over:
		actor.move_and_slide()
		for i in actor.get_slide_collision_count():
			var collision: KinematicCollision2D = actor.get_slide_collision(i)
			if collision.get_collider().get_collision_layer_value(3):
				var pit: Pit = collision.get_collider()
				pit_collision.emit(pit.depth)
			
func interrupt_movement() -> void:
	can_move = false
	await get_tree().create_timer(0.2).timeout
	can_move = true

	
