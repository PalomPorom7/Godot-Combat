extends Control

@onready var _fill : ColorRect = $Fill
@onready var _max_size_x : float = _fill.size.x

func set_value(percentage : float):
	_fill.size.x = _max_size_x * percentage
