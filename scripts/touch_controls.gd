extends Control

const JOY_RADIUS := 140.0
const JOY_KNOB_RADIUS := 60.0
const BTN_RADIUS := 120.0
const MAX_DRAG := 140.0
# Il joystick di mira usa una corsa più lunga di quello di movimento: a
# parità di spostamento del dito, serve più corsa per raggiungere la stessa
# intensità di mira, quindi la mira risulta meno sensibile/nervosa. Regolabile
# dal player nelle Impostazioni: GameSettings.aim_max_drag (autoload).
# Area di tocco della mira più piccola della metà schermo: lascia spazio ai
# tasti di attacco e delle armi da lancio vicini senza che vengano rubati
# dal joystick di mira (lo stesso tipo di bug che c'era col movimento).
const AIM_ZONE_RADIUS := JOY_RADIUS + 20.0

var move_vector := Vector2.ZERO
var attack_held := false
var input_enabled := true
# 0.0 = appena usato (in ricarica), 1.0 = pronto per colpire di nuovo.
var attack_ready_frac := 1.0

var aim_enabled := false:
	set(value):
		aim_enabled = value
		_update_layout()
var aim_vector := Vector2.ZERO
var fire_release_pending := false

var _joy_touch_index := -2
var _joy_origin := Vector2.ZERO
var _attack_touch_index := -2
var _aim_touch_index := -2
var _aim_origin := Vector2.ZERO
var _joy_base_pos := Vector2.ZERO
var _btn_pos := Vector2.ZERO
var aim_base_pos := Vector2.ZERO

# Modalità "personalizza posizione comandi": mentre attiva, il tocco/
# trascinamento su tutto lo schermo sposta l'elemento più vicino al punto di
# partenza invece di controllare movimento/mira/attacco. draggable_buttons
# aggiunge altri Control trascinabili oltre ai tre disegnati qui (es. i tasti
# "Lancia"/"Tipo lancio" di hud.gd), passati dalla scena ospite.
var edit_mode := false
var draggable_buttons := {}
var _edit_drag_key := ""
var _edit_touch_index := -2

# Aggancio generico per una scena ospite (es. home.gd, per toccare un
# banco 3D): se impostato, ha sempre la priorità sul joystick/mira/attacco.
# external_press_test(pos) -> bool: chiamata su ogni tocco/click iniziale,
# prima di ogni altro instradamento; se ritorna true "prenota" quell'indice
# di tocco, che da quel momento non controlla più joystick/mira/attacco
# finché non viene rilasciato. external_release(pos): chiamata al rilascio
# di un tocco prenotato. Entrambe Callable() (non valide) di default,
# quindi innocue per ogni scena che non le imposta.
var external_press_test: Callable
var external_release: Callable
var _external_touch_indices := {}

func begin_edit_mode(buttons: Dictionary) -> void:
	draggable_buttons = buttons
	edit_mode = true
	_edit_drag_key = ""
	_edit_touch_index = -2
	queue_redraw()

func end_edit_mode() -> void:
	edit_mode = false
	draggable_buttons = {}
	_edit_drag_key = ""
	_edit_touch_index = -2
	_update_layout()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)

func _process(_delta: float) -> void:
	queue_redraw()

func _update_layout() -> void:
	var vp := get_viewport_rect().size
	_joy_base_pos = Vector2(170, vp.y - 220)
	if aim_enabled:
		aim_base_pos = Vector2(vp.x - 170, vp.y - 220)
		# Il tasto attacco deve restare a destra della zona di movimento (metà
		# schermo) e a sinistra del joystick di mira: lo mettiamo a metà dello
		# spazio libero tra i due, così si adatta a qualsiasi larghezza schermo.
		var aim_left_edge: float = aim_base_pos.x - JOY_RADIUS
		var zone_boundary: float = vp.x * 0.5
		var attack_x: float = (zone_boundary + aim_left_edge) / 2.0
		_btn_pos = Vector2(attack_x, vp.y - 220)
	else:
		aim_base_pos = Vector2.ZERO
		_btn_pos = Vector2(vp.x - 170, vp.y - 220)
	_apply_control_offset_overrides(vp)
	queue_redraw()

# Posizioni scelte liberamente dal player nelle Impostazioni (M5), salvate
# come frazione 0..1 della viewport: sovrascrivono la posizione calcolata di
# default sopra, solo per gli elementi che il player ha effettivamente
# spostato (chiave assente = resta la posizione di default).
func _apply_control_offset_overrides(vp: Vector2) -> void:
	var is_landscape := vp.x > vp.y
	if GameSettings.has_control_offset("move_joystick", is_landscape):
		_joy_base_pos = GameSettings.get_control_offset("move_joystick", is_landscape) * vp
	if aim_enabled and GameSettings.has_control_offset("aim_joystick", is_landscape):
		aim_base_pos = GameSettings.get_control_offset("aim_joystick", is_landscape) * vp
	if GameSettings.has_control_offset("attack_button", is_landscape):
		_btn_pos = GameSettings.get_control_offset("attack_button", is_landscape) * vp

func _input(event: InputEvent) -> void:
	if (get_tree().paused and not edit_mode) or not input_enabled:
		return
	if edit_mode:
		_handle_edit_mode_input(event)
		return
	if event is InputEventScreenTouch:
		_handle_pointer_down_up(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_pointer_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer_down_up(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_handle_pointer_drag(-1, event.position)

func _handle_edit_mode_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_edit_pointer_down_up(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_edit_pointer_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_edit_pointer_down_up(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_handle_edit_pointer_drag(-1, event.position)

# Posizione "centro" di ogni elemento trascinabile in questo momento: i tre
# disegnati qui (joystick movimento/mira, tasto attacco) più gli eventuali
# Button esterni passati a begin_edit_mode.
func _edit_draggable_positions() -> Dictionary:
	var positions := {"move_joystick": _joy_base_pos, "attack_button": _btn_pos}
	if aim_enabled:
		positions["aim_joystick"] = aim_base_pos
	for key in draggable_buttons.keys():
		var btn: Button = draggable_buttons[key]
		if btn != null and is_instance_valid(btn) and btn.visible:
			positions[key] = btn.position + btn.size * 0.5
	return positions

func _handle_edit_pointer_down_up(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _edit_touch_index != -2:
			return
		var positions := _edit_draggable_positions()
		var best_key := ""
		var best_dist := INF
		for key in positions.keys():
			var d: float = pos.distance_to(positions[key])
			if d < best_dist:
				best_dist = d
				best_key = key
		if best_key == "":
			return
		_edit_drag_key = best_key
		_edit_touch_index = index
		queue_redraw()
	elif index == _edit_touch_index:
		if _edit_drag_key != "":
			var vp := get_viewport_rect().size
			var final_pos: Vector2 = _edit_draggable_positions().get(_edit_drag_key, Vector2.ZERO)
			GameSettings.set_control_offset(_edit_drag_key, Vector2(final_pos.x / vp.x, final_pos.y / vp.y), vp.x > vp.y)
		_edit_drag_key = ""
		_edit_touch_index = -2
		queue_redraw()

func _handle_edit_pointer_drag(index: int, pos: Vector2) -> void:
	if index != _edit_touch_index or _edit_drag_key == "":
		return
	match _edit_drag_key:
		"move_joystick":
			_joy_base_pos = pos
		"aim_joystick":
			aim_base_pos = pos
		"attack_button":
			_btn_pos = pos
		_:
			if draggable_buttons.has(_edit_drag_key):
				var btn: Button = draggable_buttons[_edit_drag_key]
				btn.position = pos - btn.size * 0.5
	queue_redraw()

func _handle_pointer_down_up(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if external_press_test.is_valid() and bool(external_press_test.call(pos)):
			_external_touch_indices[index] = true
			return
		if _in_joystick_zone(pos) and _joy_touch_index == -2:
			_joy_touch_index = index
			_joy_origin = pos
			move_vector = Vector2.ZERO
			queue_redraw()
		elif pos.distance_to(_btn_pos) <= BTN_RADIUS * 1.6 and _attack_touch_index == -2:
			_attack_touch_index = index
			attack_held = true
			queue_redraw()
		elif _in_aim_zone(pos) and _aim_touch_index == -2:
			_aim_touch_index = index
			_aim_origin = pos
			aim_vector = Vector2.ZERO
			queue_redraw()
	else:
		if _external_touch_indices.has(index):
			_external_touch_indices.erase(index)
			if external_release.is_valid():
				external_release.call(pos)
		elif index == _joy_touch_index:
			_joy_touch_index = -2
			move_vector = Vector2.ZERO
			queue_redraw()
		elif index == _attack_touch_index:
			_attack_touch_index = -2
			attack_held = false
			queue_redraw()
		elif index == _aim_touch_index:
			_aim_touch_index = -2
			if aim_vector.length() > 0.15:
				fire_release_pending = true
			aim_vector = Vector2.ZERO
			queue_redraw()

func _handle_pointer_drag(index: int, pos: Vector2) -> void:
	if _external_touch_indices.has(index):
		return
	if index == _joy_touch_index:
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
	elif index == _aim_touch_index:
		if _in_joystick_zone(pos):
			return
		var delta := pos - _aim_origin
		var aim_max_drag: float = GameSettings.aim_max_drag
		if delta.length() > aim_max_drag:
			delta = delta.normalized() * aim_max_drag
		aim_vector = delta / aim_max_drag
		queue_redraw()

func _in_joystick_zone(pos: Vector2) -> bool:
	return pos.x < get_viewport_rect().size.x * 0.5

func _in_aim_zone(pos: Vector2) -> bool:
	return aim_enabled and pos.distance_to(aim_base_pos) <= AIM_ZONE_RADIUS

func _draw() -> void:
	draw_circle(_joy_base_pos, JOY_RADIUS, Color(1, 1, 1, 0.15))
	var knob_pos := _joy_base_pos
	if _joy_touch_index != -2:
		knob_pos += move_vector * MAX_DRAG
	draw_circle(knob_pos, JOY_KNOB_RADIUS, Color(1, 1, 1, 0.45))

	var ready: bool = attack_ready_frac >= 0.999
	var btn_color: Color
	if _attack_touch_index != -2:
		btn_color = Color(1, 0.35, 0.3, 0.85)
	elif ready:
		btn_color = Color(1, 0.32, 0.27, 0.55)
	else:
		btn_color = Color(1, 0.3, 0.25, 0.3)
	draw_circle(_btn_pos, BTN_RADIUS, btn_color)
	if not ready:
		_draw_cooldown_pie(_btn_pos, BTN_RADIUS, 1.0 - attack_ready_frac, Color(0.05, 0.03, 0.03, 0.55))

	if aim_enabled:
		draw_circle(aim_base_pos, JOY_RADIUS, Color(0.4, 0.7, 1, 0.15))
		var aim_knob_pos := aim_base_pos
		if _aim_touch_index != -2:
			aim_knob_pos += aim_vector * MAX_DRAG
		draw_circle(aim_knob_pos, JOY_KNOB_RADIUS, Color(0.4, 0.7, 1, 0.45))

	if edit_mode:
		var positions := _edit_draggable_positions()
		for key in positions.keys():
			var p: Vector2 = positions[key]
			var highlight: Color = Color(1, 0.9, 0.2, 0.95) if key == _edit_drag_key else Color(1, 1, 1, 0.7)
			draw_arc(p, 90.0, 0.0, TAU, 48, highlight, 5.0)

func _draw_cooldown_pie(center: Vector2, radius: float, frac_remaining: float, color: Color) -> void:
	# Spicchio scuro che copre la parte di ricarica ancora mancante, si
	# restringe in senso orario finché non sparisce quando il tasto è pronto.
	if frac_remaining <= 0.001:
		return
	var start_angle := -PI / 2.0
	var sweep: float = TAU * clamp(frac_remaining, 0.0, 1.0)
	var segments := 32
	var points := PackedVector2Array()
	points.append(center)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var a: float = start_angle + sweep * t
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_polygon(points, PackedColorArray([color]))
