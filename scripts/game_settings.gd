extends Node

# Impostazioni del dispositivo (non della partita: a differenza di
# CheckpointData non è per-slot, vale per l'intera installazione).
const SAVE_PATH := "user://settings.json"

signal changed

const AIM_MAX_DRAG_MIN := 120.0
const AIM_MAX_DRAG_MAX := 300.0
const AIM_MAX_DRAG_DEFAULT := 220.0

const BRIGHTNESS_MIN := 0.5
const BRIGHTNESS_MAX := 1.5
const CONTRAST_MIN := 0.5
const CONTRAST_MAX := 1.5

var aim_max_drag := AIM_MAX_DRAG_DEFAULT
var brightness := 1.0
var contrast := 1.0

# Posizioni normalizzate (frazione 0..1 della viewport) per i comandi touch
# spostati liberamente dal player; chiave assente = posizione di default
# calcolata a runtime. Chiavi: "move_joystick", "aim_joystick",
# "attack_button", "throw_type_button", "throw_arm_button".
var control_offsets := {}

func _ready() -> void:
	_load()

func set_aim_max_drag(value: float) -> void:
	aim_max_drag = clampf(value, AIM_MAX_DRAG_MIN, AIM_MAX_DRAG_MAX)
	_save()
	changed.emit()

func set_brightness(value: float) -> void:
	brightness = clampf(value, BRIGHTNESS_MIN, BRIGHTNESS_MAX)
	_save()
	changed.emit()

func set_contrast(value: float) -> void:
	contrast = clampf(value, CONTRAST_MIN, CONTRAST_MAX)
	_save()
	changed.emit()

func set_control_offset(key: String, normalized_pos: Vector2) -> void:
	control_offsets[key] = normalized_pos
	_save()
	changed.emit()

func reset_defaults() -> void:
	aim_max_drag = AIM_MAX_DRAG_DEFAULT
	brightness = 1.0
	contrast = 1.0
	control_offsets = {}
	_save()
	changed.emit()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	aim_max_drag = float(data.get("aim_max_drag", AIM_MAX_DRAG_DEFAULT))
	brightness = float(data.get("brightness", 1.0))
	contrast = float(data.get("contrast", 1.0))
	var offsets = data.get("control_offsets", {})
	control_offsets = {}
	if typeof(offsets) == TYPE_DICTIONARY:
		for key in offsets.keys():
			var v = offsets[key]
			if typeof(v) == TYPE_DICTIONARY and v.has("x") and v.has("y"):
				control_offsets[key] = Vector2(float(v.x), float(v.y))

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	var offsets_out := {}
	for key in control_offsets.keys():
		var v: Vector2 = control_offsets[key]
		offsets_out[key] = {"x": v.x, "y": v.y}
	f.store_string(JSON.stringify({
		"aim_max_drag": aim_max_drag,
		"brightness": brightness,
		"contrast": contrast,
		"control_offsets": offsets_out,
	}))
	f.close()
