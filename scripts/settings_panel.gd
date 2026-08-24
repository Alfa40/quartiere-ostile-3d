extends Control

signal closed
signal controls_editor_requested

@onready var aim_slider: HSlider = $Scroll/Box/AimSensitivitySlider
@onready var aim_label: Label = $Scroll/Box/AimSensitivityLabel
@onready var brightness_slider: HSlider = $Scroll/Box/BrightnessSlider
@onready var brightness_label: Label = $Scroll/Box/BrightnessLabel
@onready var contrast_slider: HSlider = $Scroll/Box/ContrastSlider
@onready var contrast_label: Label = $Scroll/Box/ContrastLabel
@onready var controls_editor_button: Button = $Scroll/Box/ControlsEditorButton
@onready var reset_button: Button = $Scroll/Box/ResetButton
@onready var close_button: Button = $Scroll/Box/CloseButton

func _ready() -> void:
	visible = false
	aim_slider.min_value = GameSettings.AIM_MAX_DRAG_MIN
	aim_slider.max_value = GameSettings.AIM_MAX_DRAG_MAX
	aim_slider.step = 1.0
	brightness_slider.min_value = GameSettings.BRIGHTNESS_MIN
	brightness_slider.max_value = GameSettings.BRIGHTNESS_MAX
	brightness_slider.step = 0.02
	contrast_slider.min_value = GameSettings.CONTRAST_MIN
	contrast_slider.max_value = GameSettings.CONTRAST_MAX
	contrast_slider.step = 0.02
	aim_slider.value_changed.connect(_on_aim_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	contrast_slider.value_changed.connect(_on_contrast_changed)
	controls_editor_button.pressed.connect(func(): controls_editor_requested.emit())
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_refresh()

func set_controls_editor_button_visible(value: bool) -> void:
	controls_editor_button.visible = value

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	aim_slider.value = GameSettings.aim_max_drag
	brightness_slider.value = GameSettings.brightness
	contrast_slider.value = GameSettings.contrast
	_update_labels()

func _update_labels() -> void:
	aim_label.text = "Sensibilità mira — più a sinistra = più sensibile (corsa: %dpx)" % int(aim_slider.value)
	brightness_label.text = "Luminosità: %d%%" % int(brightness_slider.value * 100.0)
	contrast_label.text = "Contrasto: %d%%" % int(contrast_slider.value * 100.0)

func _on_aim_changed(value: float) -> void:
	GameSettings.set_aim_max_drag(value)
	_update_labels()

func _on_brightness_changed(value: float) -> void:
	GameSettings.set_brightness(value)
	_update_labels()

func _on_contrast_changed(value: float) -> void:
	GameSettings.set_contrast(value)
	_update_labels()

func _on_reset_pressed() -> void:
	GameSettings.reset_defaults()
	_refresh()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
