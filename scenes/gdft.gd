extends Node
class_name GdftClient

signal score_received(client_id, score, is_final, itch_url)
signal player_poll_timeout(client_id)
signal all_players_final(scores: Dictionary)

@export var base_url: String = "https://gdfgscoreshare.onrender.com"

@export var poll_start_delay_seconds: float = 0.5
@export var poll_interval_seconds: float = 1.5
@export var poll_timeout_seconds: float = 180.0
@export var enable_debug_view: bool = false:
    set(value):
        enable_debug_view = value
        _update_debug_view()

var own_token: String = ""
var run_id: String = ""
var local_client_id: int = -1
var player_count: int = 0

var _has_started_polling: bool = false
var _token_ready_time: float = 0.0

var _player_final_data: Dictionary = {}
var _players_final_or_timed_out: int = 0

var _debug_view_instance: Node = null

func _ready() -> void:
    if OS.has_feature("web"):
        initialize()
    _update_debug_view()


func _process(_delta: float) -> void:
    if _has_started_polling:
        return
    if own_token.is_empty():
        return

    var now := Time.get_unix_time_from_system()
    if now - _token_ready_time < poll_start_delay_seconds:
        return

    _start_polling_all_players()
    _has_started_polling = true


# -- Initialization ----------------------------------------------------------

func initialize(url: String = "") -> void:
    var effective_url := url

    if effective_url.is_empty() and OS.has_feature("web") and Engine.has_singleton('JavaScriptBridge'):
        effective_url = JavaScriptBridge.eval("window.location.href")

    if effective_url.is_empty():
        push_warning("GdftClient: No URL provided and JavaScriptBridge not available.")
        return

    var token_param := _get_query_param(effective_url, "token")
    if token_param.is_empty():
        push_warning("GdftClient: No 'token' query parameter in URL.")
        return

    set_token(token_param)


func set_token(token: String) -> void:
    if token.is_empty():
        push_warning("GdftClient: set_token called with empty token.")
        return

    var parsed_ok := _parse_token(token)
    if not parsed_ok:
        push_warning("GdftClient: Invalid token format: '%s'" % token)
        return

    own_token = token
    _token_ready_time = Time.get_unix_time_from_system()
    _player_final_data.clear()
    _players_final_or_timed_out = 0
    _has_started_polling = false

    print("GdftClient: Own token set to: ", own_token,
        " (run_id=", run_id,
        ", local_client_id=", local_client_id,
        ", player_count=", player_count, ")")


func _parse_token(token: String) -> bool:
    # expected format: <run_id>-<client_id>-<player_count>
    # run_id itself may contain dashes, so we peel two integers from the end.
    var parts := Array(token.split("-"))
    if parts.size() < 3:
        return false

    var player_count_str: String = parts.pop_back()
    var client_id_str: String = parts.pop_back()
    var run_id_str := "-".join(parts)

    if run_id_str.is_empty():
        return false

    if not client_id_str.is_valid_int():
        return false
    if not player_count_str.is_valid_int():
        return false

    run_id = run_id_str
    local_client_id = client_id_str.to_int()
    player_count = player_count_str.to_int()

    if player_count <= 0:
        return false
    if local_client_id < 0 or local_client_id >= player_count:
        return false

    return true


func _get_query_param(url: String, key: String) -> String:
    var q_index := url.find("?")
    if q_index == -1:
        return ""
    var query := url.substr(q_index + 1)
    for part in query.split("&"):
        var kv := part.split("=")
        if kv.size() == 2 and kv[0] == key:
            return kv[1].uri_decode()
    return ""


# -- Public API -------------------------------------------------------------

func send_score(score: int, is_final: bool) -> void:
    if own_token.is_empty():
        push_warning("GdftClient: send_score called but no token is set.")
        return

    var payload := {
        "token": own_token,
        "score": score,
        "isFinal": is_final,
    }

    var url := "%s/score" % base_url
    _post_json(url, payload) # fire-and-forget


func start_polling() -> void:
    if own_token.is_empty():
        push_warning("GdftClient: start_polling called but no token is set.")
        return
    if _has_started_polling:
        return

    _start_polling_all_players()
    _has_started_polling = true


# -- Internal polling logic -------------------------------------------------

func _start_polling_all_players() -> void:
    if player_count <= 0:
        push_warning("GdftClient: Cannot start polling, invalid player_count.")
        return

    for client_id in player_count:
        _poll_single_player(client_id) # async


func _poll_single_player(client_id: int) -> void:
    # Spawn as a detached async task
    _poll_single_player_async(client_id)


@warning_ignore("unused_parameter")
func _poll_single_player_async(client_id: int) -> void:
    var token_for_player := _make_token(run_id, client_id, player_count)
    var url := "%s/score/%s" % [
        base_url,
        token_for_player.uri_encode(),
    ]

    var start_time := Time.get_unix_time_from_system()
    var last_score: Variant = null
    var last_is_final: bool = false

    while true:
        var result := await _get_text(url)

        if result["ok"]:
            var body: String = result["body"]
            var parsed = JSON.parse_string(body)
            if typeof(parsed) == TYPE_DICTIONARY:
                var score := int(parsed.get("score", 0))
                var is_final := bool(parsed.get("isFinal", false))
                var itch_url := str(parsed.get("itchUrl", ""))

                var changed = (last_score == null
                    or score != last_score
                    or is_final != last_is_final)

                if changed:
                    last_score = score
                    last_is_final = is_final
                    emit_signal("score_received", client_id, score, is_final, itch_url)

                if is_final:
                    _mark_player_final(client_id, score, itch_url)
                    print("GdftClient: Final score for client ", client_id, " token=", token_for_player)
                    return

        var now := Time.get_unix_time_from_system()

        if now - start_time > poll_timeout_seconds:
            push_warning("GdftClient: Timed out waiting for score for token '%s'" % token_for_player)
            emit_signal("player_poll_timeout", client_id)
            _mark_player_final(client_id, null, "")
            return

        await get_tree().create_timer(poll_interval_seconds).timeout


func _make_token(run_id_value: String, client_id: int, total_players: int) -> String:
    return "%s-%d-%d" % [run_id_value, client_id, total_players]


func _mark_player_final(client_id: int, score: Variant, itch_url: String) -> void:
    if not _player_final_data.has(client_id):
        _players_final_or_timed_out += 1

    _player_final_data[client_id] = {
        "score": score,
        "is_final": true,
        "itch_url": itch_url,
    }

    if _players_final_or_timed_out >= player_count:
        emit_signal("all_players_final", _player_final_data.duplicate())


# -- HTTP helpers -----------------------------------------------------------

func _get_text(url: String) -> Dictionary:
    var request := HTTPRequest.new()

    add_child(request)

    var error := request.request(url)

    if error != OK:
        request.queue_free()

        return {
            "ok": false,
            "error": "request_error_%d" % error,
            "code": 0,
            "body": "",
        }

    var response = await request.request_completed

    request.queue_free()

    var status: int = response[1]
    var body: PackedByteArray = response[3]

    return {
        "ok": status >= 200 and status < 300,
        "code": status,
        "body": body.get_string_from_utf8(),
        "error": "",
    }


func _post_json(url: String, payload: Dictionary) -> void:
    _post_json_async(url, payload)


func _post_json_async(url: String, payload: Dictionary) -> void:
    var request := HTTPRequest.new()

    add_child(request)

    var error := request.request(
        url,
        ["Content-Type: application/json"],
        HTTPClient.METHOD_POST,
        JSON.stringify(payload)
    )

    if error != OK:
        push_warning("GdftClient: POST request error %d" % error)
        request.queue_free()
        return

    var response = await request.request_completed

    request.queue_free()

    var result_code: int = response[1]

    if result_code < 200 or result_code >= 300:
        push_warning("GdftClient: Send score failed with HTTP %d" % result_code)


func pop_back(arr: Array) -> Variant:
    var val = arr.back()
    arr.remove_at(arr.size() - 1)
    return val


func _update_debug_view() -> void:
    if enable_debug_view:
        if not _debug_view_instance:
            var scene = load("res://scenes/gdft_debug.tscn")
            if scene:
                _debug_view_instance = scene.instantiate()
                add_child(_debug_view_instance)
    else:
        if _debug_view_instance:
            _debug_view_instance.queue_free()
            _debug_view_instance = null
