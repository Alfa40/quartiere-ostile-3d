extends Control

const JOY_RADIUS := 140.0
const JOY_KNOB_RADIUS := 60.0
const BTN_RADIUS := 120.0
const MAX_DRAG := 140.0

var move_vector := Vector2.ZERO
var attack_held := false

var _joy_touch_index := -2
var _joy_origin := Vector2.ZERO
var _attack_touch_index := -2
var _joy_base_pos := Vector2.ZERO
var _btn_pos := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)

func _update_layout() -> void:
	var vp := get_viewport_rect().size
	_joy_base_pos = Vector2(170, vp.y - 220)
	_btn_pos = Vector2(vp.x - 170, vp.y - 220)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		_handle_pointer_down_up(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_pointer_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer_down_up(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_handle_pointer_drag(-1, event.position)

func _handle_pointer_down_up(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _in_joystick_zone(pos) and _joy_touch_index == -2:
			_joy_touch_index = index
			_joy_origin = pos
			move_vector = Vector2.ZERO
			queue_redraw()
		elif pos.distance_to(_btn_pos) <= BTN_RADIUS * 1.6 and _attack_touch_index == -2:
			_attack_touch_index = index
			attack_held = true
			queue_redraw()
	else:
		if index == _joy_touch_index:
			_joy_touch_index = -2
			move_vector = Vector2.ZERO
			queue_redraw()
		elif index == _attack_touch_index:
			_attack_touch_index = -2
			attack_held = false
			queue_redraw()

func _handle_pointer_drag(index: int, pos: Vector2) -> void:
	if index != _joy_touch_index:
		return
	if not _in_joystick_zone(pos):
		# A drag that jumps outside the joystick's own half of the screen can
		# only be a misrouted/phantom event (e.g. the attack button on some
		# devices) — ignore it instead of letting it corrupt move_vector.
		return
	var delta := pos - _joy_origin
	if delta.length() > MAX_DRAG:
		delta = delta.normalized() * MAX_DRAG
	move_vector = delta / MAX_DRAG
	queue_redraw()

func _in_joystick_zone(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x * 0.5

func _draw() -> void:
	draw_circle(_joy_base_pos, JOY_RADIUS, Color(1, 1, 1, 0.15))
	var knob_pos := _joy_base_pos
	if _joy_touch_index != -2:
		knob_pos += move_vector * MAX_DRAG
	draw_circle(knob_pos, JOY_KNOB_RADIUS, Color(1, 1, 1, 0.45))

	var btn_color := Color(1, 0.3, 0.25, 0.35)
	if _attack_touch_index != -2:
		btn_color = Color(1, 0.3, 0.25, 0.65)
	draw_circle(_btn_pos, BTN_RADIUS, btn_color)
