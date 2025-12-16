extends Node2D

const WALL = preload("uid://dr80n3nbw26bf")
const PIT = preload("uid://bos6ll5ssitbh")
const FLOOR = preload("uid://b3wvsopo3g3qe")
const HERO = preload("uid://s3fewhnrigr8")

@onready var timer: Timer = $Timer
@onready var time_value_label: Label = $UILayer/HBoxContainer/VBoxContainer2/HBoxContainer/TimeValueLabel
@onready var depth_value_label: Label = $UILayer/HBoxContainer/VBoxContainer/HBoxContainer2/DepthValueLabel
@onready var health_value_label: Label = $UILayer/HBoxContainer/VBoxContainer/HBoxContainer/HealthValueLabel
@onready var score_container: HBoxContainer = $UILayer/ScoreControl/ScoreContainer
@onready var score_label: RichTextLabel = $UILayer/ScoreControl/ScoreContainer/ScoreLabel
@onready var score_control: Control = $UILayer/ScoreControl

var hero: Actor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	score_control.hide()
	clear_level()
	new_level()
	Globals.depth += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#if Input.is_action_just_pressed("enter"):
		#clear_level()
		#new_level()
		#Globals.depth += 1
	#pass
	time_value_label.text = "%0.2f" % timer.time_left
	depth_value_label.text = str(Globals.depth)
	if hero:
		if hero.has_node("HealthComponent"):
			var hc: HealthComponent = hero.get_node("HealthComponent")
			var max_health: int = hc.max_health
			var health: int = hc.health
			health_value_label.text = "%d/%d" % [health, max_health]
	
func clear_level() -> void:
	for child in get_children():
		if child is Cell:
			child.queue_free()

func new_level() -> void:
	var tile_size: int = 16
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	var zoom: int = 20
	var floor_positions: Array[Vector2] = []
	for i in range(17):
		for j in range(17):
			#print(noise.get_noise_2d(j*50, i*50))
			if i == 0 or i == 16 or j == 0 or j == 16:
				var wall_cell: Cell = WALL.instantiate()
				add_child(wall_cell)
				wall_cell.position = Vector2(j * tile_size, i * tile_size)
			else:
				var noise_at_pos: float = noise.get_noise_2d(j * zoom, i * zoom) + 1
				if int(floor(noise_at_pos)) == 1:
					var floor_cell: Cell = FLOOR.instantiate()
					add_child(floor_cell)
					var pos = Vector2(j * tile_size, i * tile_size)
					floor_cell.position = pos
					floor_positions.append(pos)
				else:
					var noise_at_pos_2 = (noise.get_noise_2d((j + 5) * zoom, (i + 5) * zoom) + 1) / 2.0
					var pit_cell: Pit = PIT.instantiate()
					add_child(pit_cell)
					pit_cell.position = Vector2(j * tile_size, i * tile_size)
					var eased_noise = -(cos(PI * noise_at_pos_2) - 1) / 2.0
					var accent_color: Color = Color("#1e579c").lerp(Color("#0ce6f2"), float(Globals.depth) / 50)
					var color: Color = Color("#201533").lerp(accent_color, eased_noise)
					pit_cell.background_sprite.modulate = color
					if noise_at_pos_2 <= 0.05:
						#pit_cell.background_sprite.modulate = Color.RED
						pit_cell.depth = 10
					elif noise_at_pos_2 <= 0.1:
						#pit_cell.background_sprite.modulate = Color.ORANGE
						pit_cell.depth = 9
					elif noise_at_pos_2 <= 0.15:
						#pit_cell.background_sprite.modulate = Color.YELLOW
						pit_cell.depth = 8
					elif noise_at_pos_2 <= 0.2:
						#pit_cell.background_sprite.modulate = Color.GREEN
						pit_cell.depth = 7
					elif noise_at_pos_2 <= 0.3:
						#pit_cell.background_sprite.modulate = Color.BLUE
						pit_cell.depth = 6
					elif noise_at_pos_2 <= 0.4:
						#pit_cell.background_sprite.modulate = Color.PURPLE
						pit_cell.depth = 5
					elif noise_at_pos_2 <= 0.55:
						#pit_cell.background_sprite.modulate = Color.PINK
						pit_cell.depth = 4
					elif noise_at_pos_2 <= 0.7:
						#pit_cell.background_sprite.modulate = Color.LIGHT_GRAY
						pit_cell.depth = 3
					elif noise_at_pos_2 <= 0.85:
						#pit_cell.background_sprite.modulate = Color.DARK_GRAY
						pit_cell.depth = 2
					else:
						pit_cell.depth = 1
	if not hero:
		hero = HERO.instantiate()
		add_child(hero)
		if hero.has_node("PlayerComponent"):
			var player_component: PlayerComponent = hero.get_node("PlayerComponent")
			player_component.pit_collision.connect(_on_hero_pit_collision)
		if hero.has_node("HealthComponent"):
			var health_component: HealthComponent = hero.get_node("HealthComponent")
			health_component.died.connect(_on_hero_died)
	var new_pos = floor_positions.pick_random()
	hero.position = new_pos
	
func _on_hero_pit_collision(dep: int) -> void:
	hero.get_node("HealthComponent").take_damage(floor(dep / 2.0))
	if not Globals.game_over:
		clear_level()
		new_level()
		hero.get_node("PlayerComponent").interrupt_movement()
		Globals.depth += dep
	
func _on_hero_died() -> void:
	Globals.game_over = true
	timer.stop()
	score_control.show()
	score_container.show()
	score_label.show()
	score_label.text = "[b]Final Score[/b]
Depth + ¢
[hr]
%d + %d
[hr]
[wave][b]%d points![/b][/wave]" % [Globals.depth, Globals.money, Globals.depth + Globals.money]
