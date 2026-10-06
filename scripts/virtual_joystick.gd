extends Control
class_name VirtualJoystick

signal vector_changed(value: Vector2)

var value: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _mouse_active: bool = false
var _knob_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(220.0, 220.0)
	_knob_position = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _touch_id == -1 and not _mouse_active:
		_knob_position = size * 0.5
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_id == -1:
			_touch_id = touch.index
			_update_from_position(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _touch_id:
			_touch_id = -1
			_reset()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_id:
			_update_from_position(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_mouse_active = mouse_button.pressed
			if _mouse_active:
				_update_from_position(mouse_button.position)
			else:
				_reset()
			accept_event()
	elif event is InputEventMouseMotion and _mouse_active:
		_update_from_position((event as InputEventMouseMotion).position)
		accept_event()

func _update_from_position(local_position: Vector2) -> void:
	var center := size * 0.5
	var radius := maxf(32.0, minf(size.x, size.y) * 0.36)
	var delta := local_position - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_knob_position = center + delta
	value = delta / radius
	if value.length() < 0.08:
		value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()

func _reset() -> void:
	value = Vector2.ZERO
	_knob_position = size * 0.5
	vector_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(32.0, minf(size.x, size.y) * 0.36)
	draw_circle(center, radius, Color(0.08, 0.11, 0.17, 0.72))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.25, 0.65, 1.0, 0.95), 4.0, true)
	draw_circle(_knob_position, radius * 0.38, Color(0.25, 0.65, 1.0, 0.90))
