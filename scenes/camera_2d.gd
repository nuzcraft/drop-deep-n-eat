extends Camera2D

var shake: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shake:
		shake = max(shake - 2.0 * delta, 0)
		screenshake()
	
func add_screenshake(amount: float) -> void:
	shake = min(shake + amount, 1.0)
	
func screenshake() -> void:
	var max_offset := Vector2(20, 20)
	var power := 2
	var amount = pow(shake, power)
	#position.x = max_offset.x * amount * randi_range(-1, 1)
	position.y = max_offset.y * amount * randi_range(-1, 1)
