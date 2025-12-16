# GdUnit generated TestSuite
class_name ActorTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/actors/actor.gd'


func test__ready() -> void:
	var actor: Actor = preload("res://scenes/actors/actor.tscn").instantiate()
	add_child(actor)
	assert_object(actor.background_color).is_equal(actor.background_sprite.modulate)
	assert_object(actor.foreground_color).is_equal(actor.foreground_sprite.modulate)
	assert_bool(actor.collision_disabled).is_equal(actor.collision_shape_2d.disabled)
