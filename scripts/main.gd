extends Node3D

const VirtualJoystickScript := preload("res://scripts/virtual_joystick.gd")

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_hand: Node3D
var right_hand: Node3D
var target_mesh: MeshInstance3D
var target_material: StandardMaterial3D

var xr_interface: XRInterface
var touch_move_input: Vector2 = Vector2.ZERO
var keyboard_move_input: Vector2 = Vector2.ZERO
var move_speed: float = 2.2
var head_yaw: float = 0.0
var head_pitch: float = 0.0
var touch_look_sensitivity: float = 0.0045

var status_label: Label
var fps_label: Label
var mode_label: Label
var height_label: Label
var gyro_button: Button
var vr_button: Button
var event_label: Label

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	QuestSimulator.controller_button.connect(_on_controller_button)
	QuestSimulator.height_changed.connect(_on_height_changed)
	QuestSimulator.gyro_changed.connect(_on_gyro_changed)
	QuestSimulator.vr_mode_changed.connect(_on_vr_mode_changed)
	_on_height_changed(QuestSimulator.player_height_m)
	_set_status("Mode téléphone prêt · tourne le téléphone ou glisse l'écran")

func _process(delta: float) -> void:
	_update_keyboard_input()
	_update_movement(delta)
	_update_head_tracking(delta)
	_update_controller_poses()
	if fps_label:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()

func _unhandled_input(event: InputEvent) -> void:
	if QuestSimulator.vr_enabled:
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var viewport_width := get_viewport().get_visible_rect().size.x
		if drag.position.x > viewport_width * 0.42:
			head_yaw -= drag.relative.x * touch_look_sensitivity
			head_pitch = clampf(head_pitch - drag.relative.y * touch_look_sensitivity, -1.25, 1.25)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion := event as InputEventMouseMotion
		head_yaw -= motion.relative.x * touch_look_sensitivity
		head_pitch = clampf(head_pitch - motion.relative.y * touch_look_sensitivity, -1.25, 1.25)

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.050, 0.075)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.60, 0.72, 0.88)
	environment.ambient_light_energy = 0.55
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30.0, 30.0)
	floor.mesh = plane
	floor.material_override = _make_material(Color(0.08, 0.11, 0.15), 0.92)
	add_child(floor)

	for x in range(-6, 7):
		_make_box(self, Vector3(0.015, 0.008, 12.0), Vector3(float(x), 0.006, -3.0), Color(0.12, 0.18, 0.24))
	for z in range(-9, 4):
		_make_box(self, Vector3(12.0, 0.008, 0.015), Vector3(0.0, 0.007, float(z)), Color(0.12, 0.18, 0.24))

	_make_box(self, Vector3(0.6, 0.6, 0.6), Vector3(-1.5, 0.3, -3.0), Color(0.20, 0.55, 0.95))
	_make_box(self, Vector3(0.8, 1.2, 0.8), Vector3(1.6, 0.6, -4.1), Color(0.82, 0.30, 0.24))
	_make_box(self, Vector3(1.2, 0.25, 0.55), Vector3(0.0, 0.125, -2.2), Color(0.20, 0.75, 0.45))

	var target := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	target.mesh = sphere
	target.position = Vector3(0.0, 1.45, -2.8)
	target_material = _make_material(Color(0.98, 0.68, 0.20), 0.32)
	target.material_override = target_material
	add_child(target)
	target_mesh = target

	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 0.18
	pedestal_mesh.bottom_radius = 0.25
	pedestal_mesh.height = 1.2
	pedestal.mesh = pedestal_mesh
	pedestal.position = Vector3(0.0, 0.60, -2.8)
	pedestal.material_override = _make_material(Color(0.18, 0.22, 0.28), 0.75)
	add_child(pedestal)

func _build_player() -> void:
	xr_origin = XROrigin3D.new()
	xr_origin.name = "SimulatedXROrigin"
	add_child(xr_origin)

	xr_camera = XRCamera3D.new()
	xr_camera.name = "SimulatedHead"
	xr_camera.current = true
	xr_camera.near = 0.05
	xr_camera.far = 80.0
	xr_origin.add_child(xr_camera)

	left_hand = _create_hand(&"left", Color(0.30, 0.66, 1.0))
	right_hand = _create_hand(&"right", Color(1.0, 0.42, 0.33))
	xr_camera.add_child(left_hand)
	xr_camera.add_child(right_hand)
	left_hand.position = Vector3(-0.24, -0.28, -0.48)
	right_hand.position = Vector3(0.24, -0.28, -0.48)

func _create_hand(hand_name: StringName, color: Color) -> Node3D:
	var hand := Node3D.new()
	hand.name = String(hand_name).capitalize() + "Controller"

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.045
	capsule.height = 0.18
	body.mesh = capsule
	body.rotation_degrees.x = 18.0
	body.material_override = _make_material(color, 0.36)
	hand.add_child(body)

	var pointer := MeshInstance3D.new()
	var beam := CylinderMesh.new()
	beam.top_radius = 0.008
	beam.bottom_radius = 0.008
	beam.height = 0.32
	pointer.mesh = beam
	pointer.rotation_degrees.x = 90.0
	pointer.position = Vector3(0.0, 0.025, -0.18)
	var pointer_color := color
	pointer_color.a = 0.82
	pointer.material_override = _make_material(pointer_color, 0.18)
	hand.add_child(pointer)
	return hand

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14.0
	top.offset_top = 14.0
	top.offset_right = -14.0
	top.offset_bottom = 92.0
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.065, 0.105, 0.94), 18))
	canvas.add_child(top)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 18)
	top_margin.add_theme_constant_override("margin_right", 18)
	top_margin.add_theme_constant_override("margin_top", 10)
	top_margin.add_theme_constant_override("margin_bottom", 10)
	top.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_margin.add_child(top_row)

	var title := Label.new()
	title.text = "ÉMULATEUR QUEST 3"
	title.add_theme_font_size_override("font_size", 28)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	mode_label = Label.new()
	mode_label.text = "TÉLÉPHONE"
	mode_label.add_theme_font_size_override("font_size", 17)
	mode_label.modulate = Color(0.38, 0.78, 1.0)
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(mode_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	fps_label = Label.new()
	fps_label.text = "0 FPS"
	fps_label.custom_minimum_size.x = 90.0
	fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(fps_label)

	height_label = Label.new()
	height_label.text = "1.70 m"
	height_label.custom_minimum_size.x = 76.0
	height_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(height_label)

	var h_minus := _small_button("H−")
	h_minus.pressed.connect(func(): QuestSimulator.set_player_height(QuestSimulator.player_height_m - 0.05))
	top_row.add_child(h_minus)
	var h_plus := _small_button("H+")
	h_plus.pressed.connect(func(): QuestSimulator.set_player_height(QuestSimulator.player_height_m + 0.05))
	top_row.add_child(h_plus)

	gyro_button = _small_button("GYRO ON")
	gyro_button.toggle_mode = true
	gyro_button.button_pressed = true
	gyro_button.toggled.connect(func(enabled: bool): QuestSimulator.set_gyro_enabled(enabled))
	top_row.add_child(gyro_button)

	var recenter := _small_button("RECENTRER")
	recenter.pressed.connect(_recenter)
	top_row.add_child(recenter)

	vr_button = _small_button("MODE VR")
	vr_button.pressed.connect(_toggle_vr)
	top_row.add_child(vr_button)

	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.offset_left = -420.0
	status_label.offset_top = 108.0
	status_label.offset_right = 420.0
	status_label.offset_bottom = 154.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.03, 0.05, 0.72), 14))
	canvas.add_child(status_label)

	event_label = Label.new()
	event_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	event_label.offset_left = -320.0
	event_label.offset_top = -96.0
	event_label.offset_right = 320.0
	event_label.offset_bottom = -34.0
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_label.text = "Joystick gauche = déplacement · côté droit = regarder"
	event_label.add_theme_font_size_override("font_size", 17)
	event_label.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.045, 0.075, 0.78), 14))
	canvas.add_child(event_label)

	var joystick := VirtualJoystickScript.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 22.0
	joystick.offset_top = -250.0
	joystick.offset_right = 242.0
	joystick.offset_bottom = -30.0
	joystick.vector_changed.connect(func(v: Vector2): touch_move_input = v)
	canvas.add_child(joystick)

	_build_controller_panel(canvas, &"left", "MANETTE GAUCHE · X / Y", Vector2(262.0, -248.0), false)
	_build_controller_panel(canvas, &"right", "MANETTE DROITE · A / B", Vector2(-390.0, -248.0), true)

func _build_controller_panel(canvas: CanvasLayer, hand: StringName, caption: String, position_hint: Vector2, anchor_right: bool) -> void:
	var panel := PanelContainer.new()
	if anchor_right:
		panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		panel.offset_left = position_hint.x
		panel.offset_right = -20.0
	else:
		panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		panel.offset_left = position_hint.x
		panel.offset_right = position_hint.x + 360.0
	panel.offset_top = position_hint.y
	panel.offset_bottom = -28.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.065, 0.105, 0.91), 18))
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	column.add_child(title)

	var actions := GridContainer.new()
	actions.columns = 4
	actions.add_theme_constant_override("h_separation", 5)
	actions.add_theme_constant_override("v_separation", 5)
	column.add_child(actions)

	if hand == &"left":
		_add_hold_button(actions, "X", hand, &"x")
		_add_hold_button(actions, "Y", hand, &"y")
	else:
		_add_hold_button(actions, "A", hand, &"a")
		_add_hold_button(actions, "B", hand, &"b")
	_add_hold_button(actions, "TRIG", hand, &"trigger")
	_add_hold_button(actions, "GRIP", hand, &"grip")

	var nudges := GridContainer.new()
	nudges.columns = 6
	nudges.add_theme_constant_override("h_separation", 5)
	column.add_child(nudges)
	_add_nudge_button(nudges, "←", hand, Vector3(-0.04, 0.0, 0.0))
	_add_nudge_button(nudges, "→", hand, Vector3(0.04, 0.0, 0.0))
	_add_nudge_button(nudges, "↑", hand, Vector3(0.0, 0.04, 0.0))
	_add_nudge_button(nudges, "↓", hand, Vector3(0.0, -0.04, 0.0))
	_add_nudge_button(nudges, "+Z", hand, Vector3(0.0, 0.0, -0.05))
	_add_nudge_button(nudges, "−Z", hand, Vector3(0.0, 0.0, 0.05))

func _add_hold_button(container: Control, caption: String, hand: StringName, action: StringName) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(78.0, 46.0)
	button.button_down.connect(func(): QuestSimulator.set_button(hand, action, true))
	button.button_up.connect(func(): QuestSimulator.set_button(hand, action, false))
	container.add_child(button)

func _add_nudge_button(container: Control, caption: String, hand: StringName, delta: Vector3) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(50.0, 42.0)
	button.pressed.connect(func(): _nudge_hand(hand, delta))
	container.add_child(button)

func _nudge_hand(hand: StringName, delta: Vector3) -> void:
	var node := left_hand if hand == &"left" else right_hand
	node.position += delta
	node.position.x = clampf(node.position.x, -0.75, 0.75)
	node.position.y = clampf(node.position.y, -0.65, 0.45)
	node.position.z = clampf(node.position.z, -1.20, -0.18)
	_set_event("%s : position %s" % [String(hand).capitalize(), _vector_text(node.position)])

func _small_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(96.0, 48.0)
	button.add_theme_font_size_override("font_size", 15)
	return button

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.18, 0.33, 0.52, 0.78)
	return style

func _make_material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _make_box(parent: Node, box_size: Vector3, box_position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	mesh_instance.mesh = box
	mesh_instance.position = box_position
	mesh_instance.material_override = _make_material(color, 0.78)
	parent.add_child(mesh_instance)
	return mesh_instance

func _update_keyboard_input() -> void:
	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0
	keyboard_move_input = keyboard.normalized() if keyboard != Vector2.ZERO else Vector2.ZERO

func _update_movement(delta: float) -> void:
	var move_input := keyboard_move_input if keyboard_move_input != Vector2.ZERO else touch_move_input
	if move_input.length() < 0.02:
		return
	var forward := -xr_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var right := xr_camera.global_transform.basis.x
	right.y = 0.0
	if right.length() < 0.001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var direction := right * move_input.x + forward * -move_input.y
	if direction.length() > 1.0:
		direction = direction.normalized()
	xr_origin.global_position += direction * move_speed * delta

func _update_head_tracking(delta: float) -> void:
	if QuestSimulator.vr_enabled:
		return
	if QuestSimulator.gyro_enabled:
		var gyro := Input.get_gyroscope()
		if gyro.length() > 0.0005:
			head_yaw -= gyro.y * delta
			head_pitch = clampf(head_pitch - gyro.x * delta, -1.25, 1.25)
	xr_origin.rotation.y = head_yaw
	xr_camera.rotation.x = head_pitch

func _update_controller_poses() -> void:
	var base_height := QuestSimulator.player_height_m
	if QuestSimulator.vr_enabled:
		xr_origin.position.y = base_height
	else:
		xr_origin.position.y = 0.0
		xr_camera.position.y = base_height
	left_hand.position.y = clampf(left_hand.position.y, -0.65, 0.45)
	right_hand.position.y = clampf(right_hand.position.y, -0.65, 0.45)

func _toggle_vr() -> void:
	if QuestSimulator.vr_enabled:
		get_viewport().use_xr = false
		if xr_interface and xr_interface.has_method("uninitialize"):
			xr_interface.uninitialize()
		QuestSimulator.set_vr_enabled(false)
		_set_status("Retour en mode téléphone")
		return

	xr_interface = XRServer.find_interface("Native mobile")
	if xr_interface and xr_interface.initialize():
		get_viewport().use_xr = true
		QuestSimulator.set_vr_enabled(true)
		_set_status("MobileVR actif · image stéréo + capteurs du téléphone")
	else:
		get_viewport().use_xr = false
		QuestSimulator.set_vr_enabled(false)
		_set_status("MobileVR indisponible sur cet appareil · mode téléphone conservé")

func _recenter() -> void:
	xr_origin.global_position = Vector3.ZERO
	xr_origin.rotation = Vector3.ZERO
	head_yaw = 0.0
	head_pitch = 0.0
	xr_camera.rotation = Vector3.ZERO
	left_hand.position = Vector3(-0.24, -0.28, -0.48)
	right_hand.position = Vector3(0.24, -0.28, -0.48)
	_set_status("Position, tête et manettes recentrées")

func _on_height_changed(value: float) -> void:
	if height_label:
		height_label.text = "%.2f m" % value

func _on_gyro_changed(enabled: bool) -> void:
	if gyro_button:
		gyro_button.text = "GYRO ON" if enabled else "GYRO OFF"
	if enabled:
		_set_status("Gyroscope actif")
	else:
		_set_status("Gyroscope coupé · glisse le côté droit pour regarder")

func _on_vr_mode_changed(enabled: bool) -> void:
	if mode_label:
		mode_label.text = "VR STÉRÉO" if enabled else "TÉLÉPHONE"
		mode_label.modulate = Color(0.45, 1.0, 0.62) if enabled else Color(0.38, 0.78, 1.0)
	if vr_button:
		vr_button.text = "QUITTER VR" if enabled else "MODE VR"

func _on_controller_button(hand: StringName, action: StringName, pressed: bool) -> void:
	var verb := "ON" if pressed else "OFF"
	_set_event("%s · %s · %s" % [String(hand).to_upper(), String(action).to_upper(), verb])
	if hand == &"right" and action == &"trigger":
		if pressed:
			target_material.albedo_color = Color(0.35, 1.0, 0.52)
			target_mesh.scale = Vector3.ONE * 1.18
		else:
			target_material.albedo_color = Color(0.98, 0.68, 0.20)
			target_mesh.scale = Vector3.ONE

func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message

func _set_event(message: String) -> void:
	if event_label:
		event_label.text = message

func _vector_text(value: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z]
