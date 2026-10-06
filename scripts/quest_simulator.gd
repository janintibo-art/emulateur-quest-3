extends Node

signal controller_button(hand: StringName, action: StringName, pressed: bool)
signal vr_mode_changed(enabled: bool)
signal gyro_changed(enabled: bool)
signal height_changed(height_m: float)

var vr_enabled: bool = false
var gyro_enabled: bool = true
var player_height_m: float = 1.70

var left_buttons: Dictionary = {}
var right_buttons: Dictionary = {}

func set_vr_enabled(enabled: bool) -> void:
	if vr_enabled == enabled:
		return
	vr_enabled = enabled
	vr_mode_changed.emit(vr_enabled)

func set_gyro_enabled(enabled: bool) -> void:
	if gyro_enabled == enabled:
		return
	gyro_enabled = enabled
	gyro_changed.emit(gyro_enabled)

func set_player_height(value: float) -> void:
	player_height_m = clampf(value, 0.60, 2.20)
	height_changed.emit(player_height_m)

func set_button(hand: StringName, action: StringName, pressed: bool) -> void:
	if hand == &"left":
		left_buttons[action] = pressed
	else:
		right_buttons[action] = pressed
	controller_button.emit(hand, action, pressed)

func is_pressed(hand: StringName, action: StringName) -> bool:
	if hand == &"left":
		return bool(left_buttons.get(action, false))
	return bool(right_buttons.get(action, false))
