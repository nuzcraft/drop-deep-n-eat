extends CanvasLayer
class_name GdftDebug

## Reference to the GdftClient to listen to.
## If not set via Inspector, will try to find "GdftClient" as a sibling.
@export var gdft_client: Node

@onready var player_list: VBoxContainer = %PlayerList

var _player_labels: Dictionary = {}

func _ready() -> void:
	if not gdft_client:
		var parent_node = get_parent()
		if parent_node is GdftClient:
			gdft_client = parent_node
		elif parent_node:
			gdft_client = parent_node.get_node_or_null("GdftClient")
	
	if gdft_client:
		if gdft_client.has_signal("score_received"):
			gdft_client.score_received.connect(_on_score_received)
		if gdft_client.has_signal("player_poll_timeout"):
			gdft_client.player_poll_timeout.connect(_on_player_poll_timeout)
		if gdft_client.has_signal("all_players_final"):
			gdft_client.all_players_final.connect(_on_all_final)
			
		print("GdftDebug: Connected to GdftClient.")
	else:
		push_warning("GdftDebug: GdftClient node not found.")


func _on_score_received(client_id: int, score: int, is_final: bool, _itch_url: String) -> void:
	var label = _get_or_create_player_label(client_id)
	
	var name_str = "Player %d" % client_id
	if gdft_client and "local_client_id" in gdft_client and gdft_client.local_client_id == client_id:
		name_str = "YOU"
	
	var text = "%s: %s" % [name_str, str(score)]
	
	if is_final:
		text += " (FINAL)"
		label.modulate = Color.GREEN
	else:
		label.modulate = Color.WHITE
		
	label.text = text


func _on_player_poll_timeout(client_id: int) -> void:
	var label = _get_or_create_player_label(client_id)
	
	var name_str = "Player %d" % client_id
	if gdft_client and "local_client_id" in gdft_client and gdft_client.local_client_id == client_id:
		name_str = "YOU"
		
	label.text = "%s: TIMED OUT" % name_str
	label.modulate = Color.RED


func _on_all_final(_scores: Dictionary) -> void:
	var label = Label.new()
	label.text = "--- ALL FINISHED ---"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_list.add_child(label)


func _get_or_create_player_label(client_id: int) -> Label:
	if _player_labels.has(client_id):
		return _player_labels[client_id]
	
	var label = Label.new()
	
	var name_str = "Player %d" % client_id
	if gdft_client and "local_client_id" in gdft_client and gdft_client.local_client_id == client_id:
		name_str = "YOU"
	
	label.text = "%s: ..." % name_str
	player_list.add_child(label)
	_player_labels[client_id] = label
	return label
