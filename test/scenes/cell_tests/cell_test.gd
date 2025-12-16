# GdUnit generated TestSuite
class_name CellTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://scenes/cells/cell.gd'

func test__ready() -> void:
	var cell: Cell = preload("res://scenes/cells/cell.tscn").instantiate()
	add_child(cell)
	assert_object(cell.background_color).is_equal(cell.background_sprite.modulate)
	assert_object(cell.foreground_color).is_equal(cell.foreground_sprite.modulate)
	assert_bool(cell.collision_disabled).is_equal(cell.collision_shape_2d.disabled)
