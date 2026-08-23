extends CanvasLayer

const UIScale := preload("res://scripts/ui_scale.gd")

@onready var damage_flash: ColorRect = $DamageFlash
@onready var health_bar: ProgressBar = $HealthBar
@onready var hp_text: Label = $HealthBar/HPText
@onready var zone_label: Label = $ZoneLabel
@onready var money_label: Label = $MoneyLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var message_label: Label = $MessageLabel
@onready var pause_panel: Control = $PausePanel
@onready var pause_stats_label: Label = $PausePanel/Scroll/Box/StatsLabel
@onready var pause_inventory_label: Label = $PausePanel/Scroll/Box/InventoryLabel
@onready var gameover_panel: Control = $GameOverPanel
@onready var gameover_stats_label: Label = $GameOverPanel/Scroll/Box/StatsLabel
@onready var pause_button: Button = $PauseButton
@onready var zone_complete_panel: Control = $ZoneCompletePanel
@onready var zone_complete_timer_label: Label = $ZoneCompletePanel/Panel/Box/TimerLabel
@onready var house_enter_button: Button = $HouseEnterButton
@onready var throw_type_button: Button = $ThrowTypeButton
@onready var throw_arm_button: Button = $ThrowArmButton
@onready var throw_toast_label: Label = $ThrowToastLabel
@onready var throw_type_cooldown_overlay: Control = $ThrowTypeButton/CooldownOverlay
@onready var touch_controls = $TouchControls
@onready var creator_button: Button = $PausePanel/Scroll/Box/CreatorButton
@onready var dev_tools_box: Control = $PausePanel/Scroll/Box/DevToolsBox
@onready var dev_zone_label: Label = $PausePanel/Scroll/Box/DevToolsBox/ZoneRow/ZoneValueLabel
@onready var creator_password_panel: Control = $CreatorPasswordPanel

signal go_home_chosen
signal skip_home_chosen
signal house_enter_pressed
signal throw_type_pressed
signal throw_arm_pressed

var main: Node = null
var zone_complete_active := false
var zone_complete_time_left := 0.0
const ZONE_COMPLETE_WAIT := 30.0
var dev_target_zone := 1

const HEALTH_BAR_HEIGHT_PORTRAIT := 54.0
const HEALTH_BAR_HEIGHT_LANDSCAPE := 30.0
const HEALTH_BAR_LEFT_PORTRAIT := 24.0
const HEALTH_BAR_LEFT_LANDSCAPE := 74.0
const HEALTH_BAR_WIDTH := 520.0

const HP_TEXT_FONT_PORTRAIT := 42
const HP_TEXT_FONT_LANDSCAPE := 24
const TOP_LABEL_FONT_PORTRAIT := 32
const TOP_LABEL_FONT_LANDSCAPE := 18
# Le munizioni sono l'informazione più critica durante uno scontro a fuoco:
# un font più grande delle altre etichette in alto e un colore acceso (che
# passa al rosso quando il caricatore sta per finire) la fanno risaltare
# molto di più a colpo d'occhio.
const AMMO_LABEL_FONT_BONUS := 10
const AMMO_COLOR_NORMAL := Color(1.0, 0.82, 0.1, 1)
const AMMO_COLOR_LOW := Color(1.0, 0.15, 0.1, 1)
const AMMO_LOW_MAG_RATIO := 0.25

# Bagliore rosso molto discreto su tutto lo schermo quando il player subisce
# danni: affianca la vibrazione tattile (che su iOS Safari non ha effetto
# per un limite della piattaforma) con un riscontro visivo che funziona
# sempre, indipendentemente dal dispositivo.
const DAMAGE_FLASH_COLOR := Color(1.0, 0.1, 0.08, 0.16)
const DAMAGE_FLASH_FADE_TIME := 0.35
var _damage_flash_tween: Tween = null

const ZONE_COMPLETE_BOX_LANDSCAPE := Rect2(-230.0, 150.0, 460.0, 130.0)
const ZONE_COMPLETE_BOX_PORTRAIT := Rect2(-310.0, 140.0, 620.0, 190.0)

const THROW_ARM_DIAMETER := 130.0
const THROW_TYPE_DIAMETER := 110.0
const THROW_ARM_IDLE_MODULATE := Color(0.65, 0.65, 0.68, 1.0)
const THROW_ARM_ACTIVE_MODULATE := Color(1.25, 1.05, 0.55, 1.0)
const THROW_TYPE_RECHARGING_MODULATE := Color(0.55, 0.55, 0.58, 1.0)
const THROW_TYPE_READY_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
var _throw_toast_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = get_parent()
	pause_panel.visible = false
	gameover_panel.visible = false
	$PausePanel/Scroll/Box/ResumeButton.pressed.connect(_on_resume_pressed)
	$PausePanel/Scroll/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$PausePanel/Scroll/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$GameOverPanel/Scroll/Box/RestartButton.pressed.connect(_on_restart_pressed)
	$GameOverPanel/Scroll/Box/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	pause_button.pressed.connect(toggle_pause)
	get_viewport().size_changed.connect(_update_top_hud_layout)
	_update_top_hud_layout()
	zone_complete_panel.visible = false
	$ZoneCompletePanel/Panel/Box/ButtonRow/HomeButton.pressed.connect(func(): _resolve_zone_choice(true))
	$ZoneCompletePanel/Panel/Box/ButtonRow/SkipButton.pressed.connect(func(): _resolve_zone_choice(false))
	house_enter_button.visible = false
	house_enter_button.pressed.connect(func(): house_enter_pressed.emit())
	throw_type_button.visible = false
	throw_arm_button.visible = false
	throw_arm_button.modulate = THROW_ARM_IDLE_MODULATE
	throw_toast_label.visible = false
	throw_type_button.pressed.connect(func(): throw_type_pressed.emit())
	throw_arm_button.pressed.connect(func(): throw_arm_pressed.emit())

	creator_password_panel.visible = false
	creator_button.pressed.connect(_on_creator_button_pressed)
	_refresh_creator_button()

	$PausePanel/Scroll/Box/DevToolsBox/ZoneRow/MinusButton.pressed.connect(_on_dev_zone_step.bind(-1))
	$PausePanel/Scroll/Box/DevToolsBox/ZoneRow/PlusButton.pressed.connect(_on_dev_zone_step.bind(1))
	$PausePanel/Scroll/Box/DevToolsBox/ZoneRow/GoButton.pressed.connect(_on_dev_zone_go_pressed)
	$PausePanel/Scroll/Box/DevToolsBox/ClearZoneButton.pressed.connect(_on_dev_clear_zone_pressed)

func set_house_button_visible(value: bool) -> void:
	if not pause_panel.visible and not gameover_panel.visible:
		house_enter_button.visible = value

func set_throw_buttons_visible(value: bool) -> void:
	if not pause_panel.visible and not gameover_panel.visible:
		throw_type_button.visible = value
		throw_arm_button.visible = value

func flash_throw_type_toast(label: String) -> void:
	var has_throwable: bool = label != "-"
	if _throw_toast_tween != null and _throw_toast_tween.is_valid():
		_throw_toast_tween.kill()
	throw_toast_label.text = "Arma da lancio: %s" % label if has_throwable else "Nessuna arma da lancio"
	throw_toast_label.visible = true
	throw_toast_label.modulate.a = 1.0
	_throw_toast_tween = create_tween()
	_throw_toast_tween.tween_interval(1.3)
	_throw_toast_tween.tween_property(throw_toast_label, "modulate:a", 0.0, 0.5)
	_throw_toast_tween.tween_callback(func(): throw_toast_label.visible = false)

func flash_damage() -> void:
	if _damage_flash_tween != null and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	damage_flash.color = DAMAGE_FLASH_COLOR
	damage_flash.visible = true
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(damage_flash, "color:a", 0.0, DAMAGE_FLASH_FADE_TIME)
	_damage_flash_tween.tween_callback(func(): damage_flash.visible = false)

func _process(delta: float) -> void:
	if zone_complete_active:
		zone_complete_time_left -= delta
		zone_complete_timer_label.text = "Ritorno automatico a casa tra %d s" % int(ceil(zone_complete_time_left))
		if zone_complete_time_left <= 0.0:
			_resolve_zone_choice(true)
	_update_throw_button_positions()
	_update_ammo_label()
	_update_throw_type_cooldown()
	_update_throw_arm_modulate()

func _update_throw_arm_modulate() -> void:
	# Il tasto "Lancia" si illumina solo quando l'arma da lancio è
	# effettivamente in mano (armata), non solo quando è equipaggiata.
	var armed: bool = main != null and main.player != null and main.player.throw_armed
	throw_arm_button.modulate = THROW_ARM_ACTIVE_MODULATE if armed else THROW_ARM_IDLE_MODULATE

func _update_throw_type_cooldown() -> void:
	if main == null or main.player == null or main.player.throwable_id == "":
		throw_type_cooldown_overlay.frac_remaining = 0.0
		throw_type_button.modulate = THROW_TYPE_READY_MODULATE
		return
	var p = main.player
	var frac: float = clamp(p.throw_cooldown_timer / max(p.throwable_cooldown, 0.001), 0.0, 1.0)
	throw_type_cooldown_overlay.frac_remaining = frac
	throw_type_button.modulate = THROW_TYPE_RECHARGING_MODULATE if frac > 0.001 else THROW_TYPE_READY_MODULATE

func _update_ammo_label() -> void:
	if main == null or main.player == null or main.player.firearm_id == "":
		ammo_label.text = ""
		return
	var p = main.player
	var mag_size: int = p.firearm_magazine_size
	var reserve: int = main.get_firearm_reserve_ammo(p.firearm_id) if main.has_method("get_firearm_reserve_ammo") else 0
	var mags_left: int = int(reserve / max(mag_size, 1))
	ammo_label.text = "Munizioni: %d/%d · Caricatori: %d" % [p.firearm_ammo_in_mag, mag_size, mags_left]
	var mag_ratio: float = float(p.firearm_ammo_in_mag) / float(max(mag_size, 1))
	var low: bool = p.firearm_ammo_in_mag <= 0 or mag_ratio <= AMMO_LOW_MAG_RATIO
	ammo_label.add_theme_color_override("font_color", AMMO_COLOR_LOW if low else AMMO_COLOR_NORMAL)

func _update_throw_button_positions() -> void:
	if not touch_controls.aim_enabled:
		return
	var aim_pos: Vector2 = touch_controls.aim_base_pos
	var gap := 16.0
	var joy_top: float = aim_pos.y - touch_controls.JOY_RADIUS

	# I due tasti erano impilati verticalmente sopra il joystick di mira; ora
	# stanno affiancati (arma a sinistra, lancia a destra), entrambi centrati
	# sul punto medio dell'altezza che occupavano prima da impilati.
	var old_arm_bottom: float = joy_top - gap
	var old_arm_top: float = old_arm_bottom - THROW_ARM_DIAMETER
	var old_type_top: float = old_arm_top - gap - THROW_TYPE_DIAMETER
	var mid_y: float = (old_type_top + old_arm_bottom) * 0.5

	var pair_width: float = THROW_TYPE_DIAMETER + gap + THROW_ARM_DIAMETER
	var pair_left: float = aim_pos.x - pair_width * 0.5

	throw_type_button.offset_left = pair_left
	throw_type_button.offset_right = pair_left + THROW_TYPE_DIAMETER
	throw_type_button.offset_top = mid_y - THROW_TYPE_DIAMETER * 0.5
	throw_type_button.offset_bottom = mid_y + THROW_TYPE_DIAMETER * 0.5

	throw_arm_button.offset_left = throw_type_button.offset_right + gap
	throw_arm_button.offset_right = throw_arm_button.offset_left + THROW_ARM_DIAMETER
	throw_arm_button.offset_top = mid_y - THROW_ARM_DIAMETER * 0.5
	throw_arm_button.offset_bottom = mid_y + THROW_ARM_DIAMETER * 0.5

	throw_toast_label.offset_left = aim_pos.x - 160.0
	throw_toast_label.offset_right = aim_pos.x + 160.0
	throw_toast_label.offset_bottom = mid_y - THROW_ARM_DIAMETER * 0.5 - gap
	throw_toast_label.offset_top = throw_toast_label.offset_bottom - 50.0

func show_zone_complete_choice() -> void:
	zone_complete_active = true
	zone_complete_time_left = ZONE_COMPLETE_WAIT
	zone_complete_panel.visible = true

func _resolve_zone_choice(go_home: bool) -> void:
	if not zone_complete_active:
		return
	zone_complete_active = false
	zone_complete_panel.visible = false
	if go_home:
		go_home_chosen.emit()
	else:
		skip_home_chosen.emit()

func _update_top_hud_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var is_landscape := vp.x > vp.y
	var is_portrait := not is_landscape
	var height := HEALTH_BAR_HEIGHT_LANDSCAPE if is_landscape else HEALTH_BAR_HEIGHT_PORTRAIT
	health_bar.offset_bottom = health_bar.offset_top + height
	var left := HEALTH_BAR_LEFT_LANDSCAPE if is_landscape else HEALTH_BAR_LEFT_PORTRAIT
	health_bar.offset_left = left
	health_bar.offset_right = left + HEALTH_BAR_WIDTH

	hp_text.add_theme_font_size_override("font_size", HP_TEXT_FONT_PORTRAIT if is_portrait else HP_TEXT_FONT_LANDSCAPE)
	var top_label_font := TOP_LABEL_FONT_PORTRAIT if is_portrait else TOP_LABEL_FONT_LANDSCAPE
	zone_label.add_theme_font_size_override("font_size", top_label_font)
	money_label.add_theme_font_size_override("font_size", top_label_font)
	ammo_label.add_theme_font_size_override("font_size", top_label_font + AMMO_LABEL_FONT_BONUS)
	message_label.add_theme_font_size_override("font_size", top_label_font)

	UIScale.apply_orientation_scale(pause_panel, is_portrait)
	UIScale.apply_orientation_scale(gameover_panel, is_portrait)
	UIScale.apply_orientation_scale(creator_password_panel, is_portrait)
	UIScale.apply_orientation_scale(house_enter_button, is_portrait)
	UIScale.apply_orientation_scale(zone_complete_panel, is_portrait)

	var zc_box := ZONE_COMPLETE_BOX_PORTRAIT if is_portrait else ZONE_COMPLETE_BOX_LANDSCAPE
	zone_complete_panel.offset_left = zc_box.position.x
	zone_complete_panel.offset_top = zc_box.position.y
	zone_complete_panel.offset_right = zc_box.position.x + zc_box.size.x
	zone_complete_panel.offset_bottom = zc_box.position.y + zc_box.size.y

	if is_landscape:
		var bar_right: float = health_bar.offset_right
		zone_label.offset_left = bar_right + 20.0
		zone_label.offset_right = bar_right + 340.0
		zone_label.offset_top = health_bar.offset_top
		zone_label.offset_bottom = health_bar.offset_bottom
		zone_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		money_label.offset_left = bar_right + 350.0
		money_label.offset_right = bar_right + 560.0
		money_label.offset_top = health_bar.offset_top
		money_label.offset_bottom = health_bar.offset_bottom
		money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		ammo_label.offset_left = bar_right + 570.0
		ammo_label.offset_right = bar_right + 960.0
		ammo_label.offset_top = health_bar.offset_top - 6.0
		ammo_label.offset_bottom = health_bar.offset_bottom + 6.0
		ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		message_label.offset_top = health_bar.offset_bottom + 6.0
		message_label.offset_bottom = message_label.offset_top + 34.0
	else:
		zone_label.offset_left = 24.0
		zone_label.offset_right = 460.0
		zone_label.offset_top = 80.0
		zone_label.offset_bottom = 124.0
		zone_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

		money_label.offset_left = 24.0
		money_label.offset_right = 360.0
		money_label.offset_top = 128.0
		money_label.offset_bottom = 172.0
		money_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

		ammo_label.offset_left = 24.0
		ammo_label.offset_right = 500.0
		ammo_label.offset_top = 176.0
		ammo_label.offset_bottom = 230.0
		ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

		message_label.offset_top = 234.0
		message_label.offset_bottom = 274.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if gameover_panel.visible:
				return
			toggle_pause()

func toggle_pause() -> void:
	if gameover_panel.visible:
		return
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_panel.visible = value
	pause_button.visible = not value
	if value:
		pause_stats_label.text = main.get_stats_text()
		pause_inventory_label.text = main.get_inventory_text()
		_refresh_creator_button()

func _refresh_creator_button() -> void:
	# La Modalità Creator è disponibile solo nel suo slot isolato: nelle
	# partite normali il tasto resta nascosto e non è più possibile attivarla.
	var in_creator_slot: bool = CheckpointData.current_slot == CheckpointData.CREATOR_SLOT
	creator_button.visible = in_creator_slot
	if not in_creator_slot:
		dev_tools_box.visible = false
		return
	creator_button.text = "Modalità Creator: ON" if DevMode.enabled else "Modalità Creator: OFF"
	dev_tools_box.visible = DevMode.enabled
	if DevMode.enabled:
		dev_target_zone = main.zone
		_refresh_dev_zone_label()

func _refresh_dev_zone_label() -> void:
	dev_zone_label.text = "Zona %d" % dev_target_zone

func _on_dev_zone_step(delta: int) -> void:
	dev_target_zone = max(1, dev_target_zone + delta)
	_refresh_dev_zone_label()

func _on_dev_zone_go_pressed() -> void:
	main.dev_jump_to_zone(dev_target_zone)
	set_paused(false)

func _on_dev_clear_zone_pressed() -> void:
	main.dev_clear_zone()
	set_paused(false)

func _on_creator_button_pressed() -> void:
	# Dentro allo slot Creator si può uscire/entrare in modalità creator a
	# piacimento senza reinserire la password: quella è già stata verificata
	# al menu principale per accedere a questo slot isolato.
	if CheckpointData.current_slot != CheckpointData.CREATOR_SLOT:
		return
	main.set_creator_mode(not DevMode.enabled)
	_refresh_creator_button()

func show_game_over() -> void:
	get_tree().paused = true
	gameover_stats_label.text = main.get_stats_text()
	gameover_panel.visible = true
	pause_button.visible = false

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_restart_pressed() -> void:
	if not DevMode.enabled:
		CheckpointData.load_checkpoint()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	if not DevMode.enabled:
		SaveData.report_run(main.zone, int(main.money))
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func on_player_hp_changed(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	hp_text.text = "%d / %d" % [int(current), int(max_hp)]

func show_message(text: String) -> void:
	message_label.text = text

func update_zone(zone: int, zone_name: String) -> void:
	zone_label.text = "Zona %d — %s" % [zone, zone_name]

func update_money(amount: float) -> void:
	if DevMode.enabled:
		money_label.text = "Soldi: ∞"
	else:
		money_label.text = "Soldi: %d€" % int(amount)
