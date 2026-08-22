class_name UIScale
extends RefCounted

const PORTRAIT_FONT_MULT := 1.35
const PORTRAIT_BUTTON_MULT := 1.25

static func apply_orientation_scale(root: Node, is_portrait: bool) -> void:
	_walk(root, is_portrait)

static func _walk(node: Node, is_portrait: bool) -> void:
	if node is Label or node is Button:
		_scale_font(node, is_portrait)
	if node is Button:
		_scale_button_size(node, is_portrait)
	for child in node.get_children():
		_walk(child, is_portrait)

static func _scale_font(ctrl: Control, is_portrait: bool) -> void:
	var base: int = ctrl.get_meta("base_font_size", -1)
	if base == -1:
		base = ctrl.get_theme_font_size("font_size")
		ctrl.set_meta("base_font_size", base)
	var mult := PORTRAIT_FONT_MULT if is_portrait else 1.0
	ctrl.add_theme_font_size_override("font_size", int(round(base * mult)))

static func _scale_button_size(btn: Button, is_portrait: bool) -> void:
	var base: Vector2 = btn.get_meta("base_min_size", Vector2(-1, -1))
	if base == Vector2(-1, -1):
		base = btn.custom_minimum_size
		btn.set_meta("base_min_size", base)
	var mult := PORTRAIT_BUTTON_MULT if is_portrait else 1.0
	btn.custom_minimum_size = base * mult
