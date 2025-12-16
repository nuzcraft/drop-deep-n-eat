extends Node2D
class_name HealthComponent

signal died

@export var max_health: int

var health: int
var actor: Actor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# must be a direct child of actor node
	actor = get_parent()
	health = max_health

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		died.emit()
		
func heal(amount: int) -> void:
	health += amount
	if health >= max_health:
		health = max_health
