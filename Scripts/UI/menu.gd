class_name Menu extends Control

# Superclass used to perform basic open and close of menus consistently.

@export var _default_focus_item : Control
var is_open
var _breadcrumb : Menu

func open(breadcrumb : Menu = null):
	if breadcrumb:
		_breadcrumb = breadcrumb
		breadcrumb.close()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _default_focus_item:
		_default_focus_item.grab_focus()
	is_open = true

func close():
	is_open = false
	visible = false
	if _breadcrumb:
		_breadcrumb.open()
		_breadcrumb = null
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
