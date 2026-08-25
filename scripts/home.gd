extends Node3D

const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")
const UIScale := preload("res://scripts/ui_scale.gd")
const HouseTiers := preload("res://scripts/house_tiers.gd")

const EQUIPPED_BUTTON_MODULATE := Color(1.2, 1.12, 0.7, 1.0)
const OWNED_BUTTON_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

const MENU_SCROLL_LEFT_PORTRAIT := 60.0
const MENU_SCROLL_RIGHT_PORTRAIT := -60.0
const MENU_SCROLL_LEFT_LANDSCAPE := 110.0
const MENU_SCROLL_RIGHT_LANDSCAPE := -10.0

const INTERACT_RANGE := 2.2
const MATERIAL_LABELS := {"legno": "Legno", "metallo": "Metallo", "cablaggi": "Cablaggi"}

const DOOR_GAP := 1.4
var col_values: Array = [-1.0, 1.0]
var row_values: Array = [-2.0, 0.0, 2.0]
var current_floor := 0
var moving_bench_from_index := -1
var moving_house_bench := false
var stairs_cooldown_timer := 0.0
var _floor_mesh_instances := {}

const CATEGORY_BOXES := {
	"coltelli": "KnivesBox",
	"spade": "SpadeBox",
	"mazze": "MazzeBox",
	"martelli": "MartelliBox",
	"lance": "LanceBox",
}

const FIREARM_CATEGORY_BOXES := {
	"pistole": "PistoleBox",
	"mitragliette": "MitragliettaBox",
	"mitra": "MitraBox",
	"fucile_a_pompa": "PompaBox",
	"cecchino": "CecchinoBox",
}

const THROWABLE_CATEGORY_BOXES := {
	"armi_bianche_lancio": "ArmiBiancheLancioBox",
	"granate_esplosive": "GranateEsplosiveBox",
	"granate_speciali": "GranateSpecialiBox",
}

const EXPLOSIVE_CATEGORY_BOXES := {
	"lanciagranate": "LanciagranateBox",
	"lanciarazzi": "LanciarazziBox",
	"armi_speciali": "ArmiSpecialiBox",
}

const BENCH_SCENES := {
	"armi_bianche": preload("res://scenes/WorkbenchArmiBianche.tscn"),
	"armi_da_fuoco": preload("res://scenes/WorkbenchArmiDaFuoco.tscn"),
	"armi_da_lancio": preload("res://scenes/WorkbenchArmiDaLancio.tscn"),
	"armi_esplosive": preload("res://scenes/WorkbenchArmiEsplosive.tscn"),
	"armadio": preload("res://scenes/WorkbenchArmadio.tscn"),
	# Usato solo per l'anteprima "fantasma" durante lo spostamento: il banco
	# della casa vero e proprio resta sempre il nodo $Workbench già presente
	# in scena, mai duplicato.
	"casa": preload("res://scenes/WorkbenchCasa.tscn"),
}
const BENCH_COSTS := {
	"armi_bianche": {"money": 250, "material": "metallo", "amount": 20},
	"armi_da_fuoco": {"money": 550, "material": "metallo", "amount": 40},
	"armi_da_lancio": {"money": 900, "material": "metallo", "amount": 60},
	"armi_esplosive": {"money": 1400, "material": "metallo", "amount": 90},
	"armadio": {"money": 200, "material": "legno", "amount": 15},
}
const BENCH_LABELS := {
	"armi_bianche": "Banco delle armi bianche",
	"armi_da_fuoco": "Banco delle armi da fuoco",
	"armi_da_lancio": "Banco delle armi da lancio",
	"armi_esplosive": "Banco delle armi esplosive e speciali",
	"armadio": "Armadio",
	"casa": "Banco della casa",
}
const BENCH_UNLOCK_DESC := {
	"armi_bianche": "Sblocca coltelli, spade, mazze, martelli e lance",
	"armi_da_fuoco": "Sblocca pistole, mitragliette, mitra, fucili a pompa e da tiratore",
	"armi_da_lancio": "Sblocca armi bianche da lancio, granate esplosive e granate speciali",
	"armi_esplosive": "Sblocca lanciagranate, lanciarazzi e armi speciali",
	"armadio": "Personalizza il colore del tuo corpo e i colori della casa",
}

@onready var player: Node3D = $Player
@onready var interact_indicator: MeshInstance3D = $InteractIndicator
@onready var workbench_menu: Control = $HUD/WorkbenchMenu
@onready var money_materials_label: Label = $HUD/WorkbenchMenu/Scroll/Box/MoneyMaterialsLabel
@onready var upgrades_tab: Control = $HUD/WorkbenchMenu/Scroll/Box/UpgradesTab
@onready var benches_tab: Control = $HUD/WorkbenchMenu/Scroll/Box/BenchesTab
@onready var casa_tab: Control = $HUD/WorkbenchMenu/Scroll/Box/CasaTab
@onready var weapon_menu: Control = $HUD/WeaponMenu
@onready var weapon_money_label: Label = $HUD/WeaponMenu/Scroll/Box/MoneyMaterialsLabel
@onready var firearm_menu: Control = $HUD/FirearmMenu
@onready var firearm_money_label: Label = $HUD/FirearmMenu/Scroll/Box/MoneyMaterialsLabel
@onready var throwable_menu: Control = $HUD/ThrowableMenu
@onready var throwable_money_label: Label = $HUD/ThrowableMenu/Scroll/Box/MoneyMaterialsLabel
@onready var explosive_menu: Control = $HUD/ExplosiveMenu
@onready var explosive_money_label: Label = $HUD/ExplosiveMenu/Scroll/Box/MoneyMaterialsLabel
@onready var wardrobe_menu: Control = $HUD/WardrobeMenu
@onready var body_color_button: Button = $HUD/WardrobeMenu/Scroll/Box/BodyColorButton
@onready var wall_color_button: Button = $HUD/WardrobeMenu/Scroll/Box/WallRow/ColorButton
@onready var roof_color_button: Button = $HUD/WardrobeMenu/Scroll/Box/RoofRow/ColorButton
@onready var door_color_button: Button = $HUD/WardrobeMenu/Scroll/Box/DoorRow/ColorButton
@onready var color_pick_screen: Control = $HUD/ColorPickScreen
@onready var color_pick_title: Label = $HUD/ColorPickScreen/Box/Title
@onready var color_picker_widget: ColorPicker = $HUD/ColorPickScreen/Box/Picker
@onready var workbench_scroll: ScrollContainer = $HUD/WorkbenchMenu/Scroll
@onready var weapon_scroll: ScrollContainer = $HUD/WeaponMenu/Scroll
@onready var firearm_scroll: ScrollContainer = $HUD/FirearmMenu/Scroll
@onready var throwable_scroll: ScrollContainer = $HUD/ThrowableMenu/Scroll
@onready var explosive_scroll: ScrollContainer = $HUD/ExplosiveMenu/Scroll
@onready var placement_ui: Control = $HUD/PlacementUI
@onready var floor_row: Control = $HUD/PlacementUI/FloorRow
@onready var floor_up_button: Button = $HUD/PlacementUI/FloorRow/FloorUpButton
@onready var floor_down_button: Button = $HUD/PlacementUI/FloorRow/FloorDownButton
@onready var placement_highlight: MeshInstance3D = $PlacementHighlight
@onready var bench_ghost_holder: Node3D = $BenchGhostHolder
@onready var placed_benches_root: Node3D = $PlacedBenches
@onready var touch_controls = $HUD/TouchControls
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_panel: Control = $HUD/PausePanel
@onready var pause_stats_label: Label = $HUD/PausePanel/Scroll/Box/StatsLabel
@onready var pause_inventory_label: Label = $HUD/PausePanel/Scroll/Box/InventoryLabel

var placing_bench_type := ""
var placing_ghost: Node3D = null
var placing_orientation := "h"
var placing_col_idx := 0
var placing_row_idx := 0
var placing_valid := false

var current_weapon_category := "coltelli"
var current_firearm_category := "pistole"
var current_throwable_category := "armi_bianche_lancio"
var current_explosive_category := "lanciagranate"
var _current_interact := ""
var _placed_bench_nodes := {}
# Tocco/click prolungato sul banco 3D (invece dei vecchi tasti "Usa"/
# "Sposta"): un tocco breve apre il menu, uno tenuto premuto oltre
# HOLD_THRESHOLD_MS avvia lo spostamento. Vedi _try_claim_bench_touch().
const HOLD_THRESHOLD_MS := 500
var _bench_press_target := ""
# Quale colore si sta scegliendo nella schermata a tutto schermo aperta
# dall'Armadio: "body" | "wall" | "roof" | "door" (vuoto = nessuna).
var _color_pick_target := ""
var _bench_press_start_time := 0
var _indicator_bob := 0.0
# Stato "a tendina" dei menu delle armi: quali armi hanno statistiche e
# potenziamenti espansi, tenuti chiusi di default per non lasciare blocchi di
# testo troppo lunghi. Chiave = id arma, per tutti e 4 i banchi insieme.
var _expanded_weapons := {}

# Tasti "Compra"/"Potenzia" tenuti premuti: ripetono l'azione da soli finché
# non si toglie il dito, invece di richiedere un tocco per ogni acquisto.
const HOLD_REPEAT_INITIAL_DELAY := 0.4
const HOLD_REPEAT_INTERVAL := 0.12
var _hold_repeat_timer: Timer
var _hold_repeat_action := Callable()

func _ready() -> void:
	# Entrare in casa salva subito la partita (separato dal checkpoint ogni
	# 50 zone): così si può chiudere il gioco e riprendere da casa anche a
	# giorni di distanza, ricominciando dalla zona non ancora completata.
	if not DevMode.enabled:
		CheckpointData.save_continue()
	_setup_hold_repeat_timer()
	_apply_house_tier_geometry()
	_apply_screen_adjustment()
	GameSettings.changed.connect(_apply_screen_adjustment)
	player.global_position = _interior_spawn_position()
	player.face_direction(Vector3(0, 0, -1))
	interact_indicator.visible = false
	workbench_menu.visible = false
	weapon_menu.visible = false
	firearm_menu.visible = false
	throwable_menu.visible = false
	explosive_menu.visible = false
	wardrobe_menu.visible = false
	color_pick_screen.visible = false
	placement_ui.visible = false
	placement_highlight.visible = false
	pause_panel.visible = false
	# La pausa deve restare utilizzabile anche a gioco fermo (get_tree().paused),
	# stesso schema di hud.gd in Main.tscn.
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS

	touch_controls.external_press_test = _try_claim_bench_touch
	touch_controls.external_release = _on_bench_touch_released
	pause_button.pressed.connect(toggle_pause)
	$HUD/PausePanel/Scroll/Box/ResumeButton.pressed.connect(_on_resume_pressed)
	$HUD/PausePanel/Scroll/Box/SettingsButton.pressed.connect(_on_settings_pressed)
	$HUD/SettingsPanel.set_controls_editor_button_visible(true)
	$HUD/SettingsPanel.closed.connect(_on_settings_closed)
	$HUD/SettingsPanel.controls_editor_requested.connect(_on_controls_editor_requested)
	$HUD/SettingsPanel.controls_editor_finished.connect(_on_controls_editor_finished)
	$HUD/PausePanel/Scroll/Box/MainMenuButton.pressed.connect(_on_pause_main_menu_pressed)
	$HUD/WorkbenchMenu/Scroll/Box/CloseButton.pressed.connect(_close_house_menu)
	$HUD/WorkbenchMenu/Scroll/Box/TabsRow/UpgradesTabButton.pressed.connect(_show_upgrades_tab)
	$HUD/WorkbenchMenu/Scroll/Box/TabsRow/BenchesTabButton.pressed.connect(_show_benches_tab)
	$HUD/WorkbenchMenu/Scroll/Box/TabsRow/CasaTabButton.pressed.connect(_show_casa_tab)
	$HUD/WorkbenchMenu/Scroll/Box/CasaTab/Row_house/BuyButton.pressed.connect(_on_buy_house_tier_pressed)
	$HUD/WeaponMenu/Scroll/Box/CloseButton.pressed.connect(_close_weapon_menu)
	$HUD/FirearmMenu/Scroll/Box/CloseButton.pressed.connect(_close_firearm_menu)
	$HUD/ThrowableMenu/Scroll/Box/CloseButton.pressed.connect(_close_throwable_menu)
	$HUD/ExplosiveMenu/Scroll/Box/CloseButton.pressed.connect(_close_explosive_menu)
	$HUD/WardrobeMenu/Scroll/Box/CloseButton.pressed.connect(_close_wardrobe_menu)
	body_color_button.pressed.connect(_open_color_pick.bind("body", "Colore del corpo"))
	wall_color_button.pressed.connect(_open_color_pick.bind("wall", "Colore delle pareti"))
	roof_color_button.pressed.connect(_open_color_pick.bind("roof", "Colore del tetto"))
	door_color_button.pressed.connect(_open_color_pick.bind("door", "Colore della porta"))
	$HUD/ColorPickScreen/Box/ConfirmButton.pressed.connect(_on_color_pick_confirmed)
	$HUD/PlacementUI/ButtonRow/ConfirmButton.pressed.connect(_on_confirm_placement_pressed)
	$HUD/PlacementUI/ButtonRow/CancelButton.pressed.connect(_on_cancel_placement_pressed)
	$HUD/PlacementUI/ButtonRow/RotateButton.pressed.connect(_on_rotate_placement_pressed)
	floor_up_button.pressed.connect(_on_floor_up_pressed)
	floor_down_button.pressed.connect(_on_floor_down_pressed)

	for id in PlayerUpgrades.ORDER:
		var btn: Button = get_node("HUD/WorkbenchMenu/Scroll/Box/UpgradesTab/Row_%s/BuyButton" % id)
		_wire_hold_repeat(btn, _on_buy_upgrade_pressed.bind(id))

	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_bianche/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_bianche"))
	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_da_fuoco/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_da_fuoco"))
	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_da_lancio/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_da_lancio"))
	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_esplosive/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_esplosive"))
	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armadio/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armadio"))

	for tcat_id in THROWABLE_CATEGORY_BOXES.keys():
		var tcat_btn: Button = get_node("HUD/ThrowableMenu/Scroll/Box/CategoryRow/Btn_%s" % tcat_id)
		tcat_btn.pressed.connect(_show_throwable_category.bind(tcat_id))
		for wid in Throwables.CATEGORY_WEAPONS[tcat_id]:
			var tbase := get_node("HUD/ThrowableMenu/Scroll/Box/%s/Weapon_%s" % [THROWABLE_CATEGORY_BOXES[tcat_id], wid])
			var taction_btn: Button = tbase.get_node("MainRow/ActionButton")
			taction_btn.pressed.connect(_on_throwable_action_pressed.bind(wid))
			var tname_label: Label = tbase.get_node("MainRow/InfoLabel")
			tname_label.mouse_filter = Control.MOUSE_FILTER_STOP
			tname_label.gui_input.connect(_on_weapon_name_gui_input.bind(wid, _refresh_throwable_menu))
			var tammo_btn: Button = tbase.get_node("AmmoRow/BuyButton")
			_wire_hold_repeat(tammo_btn, _on_buy_throwable_ammo_pressed.bind(wid))
			for tid in Throwables.UPGRADE_TRACK_ORDER:
				var ttrack_row := tbase.get_node("Track_%s" % tid)
				_insert_track_separator(tbase, tid, ttrack_row)
				var tt_btn: Button = ttrack_row.get_node("BuyButton")
				_wire_hold_repeat(tt_btn, _on_upgrade_throwable_pressed.bind(wid, tid))

	for fcat_id in FIREARM_CATEGORY_BOXES.keys():
		var fcat_btn: Button = get_node("HUD/FirearmMenu/Scroll/Box/CategoryRow/Btn_%s" % fcat_id)
		fcat_btn.pressed.connect(_show_firearm_category.bind(fcat_id))
		for wid in Firearms.CATEGORY_WEAPONS[fcat_id]:
			var fbase := get_node("HUD/FirearmMenu/Scroll/Box/%s/Weapon_%s" % [FIREARM_CATEGORY_BOXES[fcat_id], wid])
			var faction_btn: Button = fbase.get_node("MainRow/ActionButton")
			faction_btn.pressed.connect(_on_firearm_action_pressed.bind(wid))
			var fname_label: Label = fbase.get_node("MainRow/InfoLabel")
			fname_label.mouse_filter = Control.MOUSE_FILTER_STOP
			fname_label.gui_input.connect(_on_weapon_name_gui_input.bind(wid, _refresh_firearm_menu))
			var fammo_btn: Button = fbase.get_node("AmmoRow/BuyButton")
			_wire_hold_repeat(fammo_btn, _on_buy_ammo_pressed.bind(wid))
			for tid in Firearms.UPGRADE_TRACK_ORDER:
				var ftrack_row := fbase.get_node("Track_%s" % tid)
				_insert_track_separator(fbase, tid, ftrack_row)
				var ft_btn: Button = ftrack_row.get_node("BuyButton")
				_wire_hold_repeat(ft_btn, _on_upgrade_firearm_pressed.bind(wid, tid))

	for ecat_id in EXPLOSIVE_CATEGORY_BOXES.keys():
		var ecat_btn: Button = get_node("HUD/ExplosiveMenu/Scroll/Box/CategoryRow/Btn_%s" % ecat_id)
		ecat_btn.pressed.connect(_show_explosive_category.bind(ecat_id))
		for wid in Firearms.CATEGORY_WEAPONS[ecat_id]:
			var ebase := get_node("HUD/ExplosiveMenu/Scroll/Box/%s/Weapon_%s" % [EXPLOSIVE_CATEGORY_BOXES[ecat_id], wid])
			var eaction_btn: Button = ebase.get_node("MainRow/ActionButton")
			eaction_btn.pressed.connect(_on_firearm_action_pressed.bind(wid))
			var ename_label: Label = ebase.get_node("MainRow/InfoLabel")
			ename_label.mouse_filter = Control.MOUSE_FILTER_STOP
			ename_label.gui_input.connect(_on_weapon_name_gui_input.bind(wid, _refresh_explosive_menu))
			var eammo_btn: Button = ebase.get_node("AmmoRow/BuyButton")
			_wire_hold_repeat(eammo_btn, _on_buy_ammo_pressed.bind(wid))
			for tid in Firearms.UPGRADE_TRACK_ORDER:
				var etrack_row := ebase.get_node("Track_%s" % tid)
				_insert_track_separator(ebase, tid, etrack_row)
				var et_btn: Button = etrack_row.get_node("BuyButton")
				_wire_hold_repeat(et_btn, _on_upgrade_firearm_pressed.bind(wid, tid))

	for cat_id in MeleeWeapons.CATEGORY_ORDER:
		var cat_btn: Button = get_node("HUD/WeaponMenu/Scroll/Box/CategoryRow/Btn_%s" % cat_id)
		cat_btn.pressed.connect(_show_weapon_category.bind(cat_id))
		for wid in MeleeWeapons.CATEGORY_WEAPONS[cat_id]:
			var base := get_node("HUD/WeaponMenu/Scroll/Box/%s/Weapon_%s" % [CATEGORY_BOXES[cat_id], wid])
			var action_btn: Button = base.get_node("MainRow/ActionButton")
			action_btn.pressed.connect(_on_weapon_action_pressed.bind(wid))
			var name_label: Label = base.get_node("MainRow/InfoLabel")
			name_label.mouse_filter = Control.MOUSE_FILTER_STOP
			name_label.gui_input.connect(_on_weapon_name_gui_input.bind(wid, _refresh_weapon_menu))
			for tid in MeleeWeapons.weapon_upgrade_tracks(wid):
				var track_row := _get_or_create_track_row(base, tid)
				_insert_track_separator(base, tid, track_row)
				var t_btn: Button = track_row.get_node("BuyButton")
				_wire_hold_repeat(t_btn, _on_upgrade_weapon_pressed.bind(wid, tid))

	$DoorTrigger.body_entered.connect(_on_door_entered)

	for b in CheckpointData.placed_benches:
		_instantiate_placed_bench(String(b.get("type", "")), String(b.get("orientation", "h")), int(b.get("col_idx", 0)), int(b.get("row_idx", 0)), int(b.get("floor", 0)))

	_show_upgrades_tab()
	_show_weapon_category("coltelli")
	_show_firearm_category("pistole")
	_show_throwable_category("armi_bianche_lancio")
	_show_explosive_category("lanciagranate")
	_refresh_workbench_menu()

	get_viewport().size_changed.connect(_update_menu_layout)
	_update_menu_layout()

func _setup_hold_repeat_timer() -> void:
	_hold_repeat_timer = Timer.new()
	_hold_repeat_timer.one_shot = false
	_hold_repeat_timer.timeout.connect(_on_hold_repeat_tick)
	add_child(_hold_repeat_timer)

# Un tasto "Compra"/"Potenzia" tenuto premuto ripete l'azione da solo finché
# non si toglie il dito, invece di richiedere un tocco per ogni acquisto.
# L'azione stessa (es. _on_buy_upgrade_pressed) già controlla soldi/materiali/
# livello massimo e non fa nulla se non è più possibile procedere, quindi è
# sicuro continuare a chiamarla anche oltre il limite.
func _wire_hold_repeat(btn: BaseButton, action: Callable) -> void:
	btn.button_down.connect(_start_hold_repeat.bind(action))
	btn.button_up.connect(_stop_hold_repeat)

func _start_hold_repeat(action: Callable) -> void:
	_hold_repeat_action = action
	if action.is_valid():
		action.call()
	_hold_repeat_timer.wait_time = HOLD_REPEAT_INITIAL_DELAY
	_hold_repeat_timer.start()

func _on_hold_repeat_tick() -> void:
	if not is_equal_approx(_hold_repeat_timer.wait_time, HOLD_REPEAT_INTERVAL):
		_hold_repeat_timer.wait_time = HOLD_REPEAT_INTERVAL
		_hold_repeat_timer.start()
	if _hold_repeat_action.is_valid():
		_hold_repeat_action.call()

func _stop_hold_repeat() -> void:
	_hold_repeat_timer.stop()
	_hold_repeat_action = Callable()

func _update_menu_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var is_landscape := vp.x > vp.y
	var is_portrait := not is_landscape

	UIScale.apply_orientation_scale(workbench_menu, is_portrait)
	UIScale.apply_orientation_scale(weapon_menu, is_portrait)
	UIScale.apply_orientation_scale(firearm_menu, is_portrait)
	UIScale.apply_orientation_scale(throwable_menu, is_portrait)
	UIScale.apply_orientation_scale(explosive_menu, is_portrait)
	UIScale.apply_orientation_scale(wardrobe_menu, is_portrait)
	UIScale.apply_orientation_scale(color_pick_screen, is_portrait)
	UIScale.apply_orientation_scale(placement_ui, is_portrait)
	UIScale.apply_orientation_scale(pause_panel, is_portrait)
	UIScale.apply_orientation_scale($HUD/SettingsPanel, is_portrait)

	var left := MENU_SCROLL_LEFT_LANDSCAPE if is_landscape else MENU_SCROLL_LEFT_PORTRAIT
	var right := MENU_SCROLL_RIGHT_LANDSCAPE if is_landscape else MENU_SCROLL_RIGHT_PORTRAIT
	workbench_scroll.offset_left = left
	workbench_scroll.offset_right = right
	weapon_scroll.offset_left = left
	weapon_scroll.offset_right = right
	firearm_scroll.offset_left = left
	firearm_scroll.offset_right = right
	throwable_scroll.offset_left = left
	throwable_scroll.offset_right = right
	explosive_scroll.offset_left = left
	explosive_scroll.offset_right = right

func _process(delta: float) -> void:
	if stairs_cooldown_timer > 0.0:
		stairs_cooldown_timer = maxf(0.0, stairs_cooldown_timer - delta)
	if placing_bench_type != "" or workbench_menu.visible or weapon_menu.visible or firearm_menu.visible or throwable_menu.visible or explosive_menu.visible or wardrobe_menu.visible or color_pick_screen.visible:
		_current_interact = ""
		interact_indicator.visible = false
		return

	var best_id := ""
	var best_dist := INTERACT_RANGE
	var d_casa := player.global_position.distance_to($Workbench.global_position)
	if d_casa <= best_dist:
		best_dist = d_casa
		best_id = "casa"
	for type_id in _placed_bench_nodes:
		var node: Node3D = _placed_bench_nodes[type_id]
		var d := player.global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			best_id = type_id
	_current_interact = best_id
	_update_interact_indicator(delta)

# Un piccolo anello luminoso sopra il banco in raggio, al posto dei vecchi
# tasti "Usa"/"Sposta": segnala dove si può toccare (tocco breve = apri,
# tenuto premuto = sposta). Stesso genere di animazione di waypoint.gd.
func _update_interact_indicator(delta: float) -> void:
	if _current_interact == "":
		interact_indicator.visible = false
		return
	var node := _interact_target_node(_current_interact)
	if node == null:
		interact_indicator.visible = false
		return
	_indicator_bob += delta
	interact_indicator.visible = true
	interact_indicator.rotation.y = _indicator_bob * 1.2
	interact_indicator.global_position = node.global_position + Vector3(0, 1.6 + sin(_indicator_bob * 2.5) * 0.08, 0)

func _interact_target_node(type_id: String) -> Node3D:
	if type_id == "casa":
		return $Workbench
	return _placed_bench_nodes.get(type_id)

# Aggancio per touch_controls.gd (vedi external_press_test): un tocco/click
# iniziale che cade davvero sul banco 3D attualmente in raggio "prenota"
# quel tocco, così joystick/mira/attacco non lo intercettano.
func _try_claim_bench_touch(pos: Vector2) -> bool:
	if placing_bench_type != "" or _current_interact == "":
		return false
	if workbench_menu.visible or weapon_menu.visible or firearm_menu.visible or throwable_menu.visible or explosive_menu.visible or wardrobe_menu.visible or color_pick_screen.visible:
		return false
	var node := _interact_target_node(_current_interact)
	if node == null:
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var from := cam.project_ray_origin(pos)
	var to := from + cam.project_ray_normal(pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty() or result.collider != node:
		return false
	_bench_press_target = _current_interact
	_bench_press_start_time = Time.get_ticks_msec()
	return true

# Un tocco breve apre il menu del banco (come il vecchio tasto "Usa"), uno
# tenuto premuto più a lungo di HOLD_THRESHOLD_MS avvia lo spostamento
# (come il vecchio tasto "Sposta"): la scelta si fa tutta al rilascio.
func _on_bench_touch_released(_pos: Vector2) -> void:
	if _bench_press_target == "":
		return
	var target := _bench_press_target
	_bench_press_target = ""
	var held_ms := Time.get_ticks_msec() - _bench_press_start_time
	if held_ms < HOLD_THRESHOLD_MS:
		_current_interact = target
		_on_interact_pressed()
	else:
		_start_bench_move(target)

func toggle_pause() -> void:
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_panel.visible = value
	pause_button.visible = not value
	if value:
		pause_stats_label.text = _pause_stats_text()
		pause_inventory_label.text = _pause_inventory_text()

# Stesso formato di main.gd:get_stats_text()/get_inventory_text(), letto
# direttamente da CheckpointData (dentro casa non esistono le var runtime
# "zone"/"money"/"materials" di main.gd).
func _pause_stats_text() -> String:
	var elapsed_sec := int(CheckpointData.stats_playtime_sec)
	var minutes := elapsed_sec / 60
	var seconds := elapsed_sec % 60
	return "Zona raggiunta: %d\nSoldi guadagnati: %d€\nNemici sconfitti: %d\nTempo: %02d:%02d" % [
		CheckpointData.stats_zone_reached, CheckpointData.stats_money_earned, CheckpointData.stats_enemies_defeated, minutes, seconds,
	]

func _pause_inventory_text() -> String:
	if DevMode.enabled:
		return "Soldi: ∞\n\nMateriali:\nLegno: ∞   Metallo: ∞   Cablaggi: ∞"
	return "Soldi: %d€\n\nMateriali:\nLegno: %d   Metallo: %d   Cablaggi: %d" % [
		int(CheckpointData.money), CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_pause_main_menu_pressed() -> void:
	if not DevMode.enabled:
		SaveData.report_run(CheckpointData.zone, int(CheckpointData.money))
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_settings_pressed() -> void:
	pause_panel.visible = false
	$HUD/SettingsPanel.open()

func _on_settings_closed() -> void:
	pause_panel.visible = true

func _on_controls_editor_requested() -> void:
	touch_controls.begin_edit_mode({})

func _on_controls_editor_finished() -> void:
	touch_controls.end_edit_mode()

func _on_interact_pressed() -> void:
	if _current_interact == "casa":
		_open_house_menu()
	elif _current_interact == "armi_bianche":
		_open_weapon_menu()
	elif _current_interact == "armi_da_fuoco":
		_open_firearm_menu()
	elif _current_interact == "armi_da_lancio":
		_open_throwable_menu()
	elif _current_interact == "armi_esplosive":
		_open_explosive_menu()
	elif _current_interact == "armadio":
		_open_wardrobe_menu()

func _start_bench_move(type_id: String) -> void:
	if type_id == "casa":
		moving_house_bench = true
		_start_bench_placement(type_id)
		return
	var idx := -1
	for i in range(CheckpointData.placed_benches.size()):
		var b: Dictionary = CheckpointData.placed_benches[i]
		if String(b.get("type", "")) == type_id and int(b.get("floor", 0)) == current_floor:
			idx = i
			break
	if idx < 0:
		return
	moving_bench_from_index = idx
	_start_bench_placement(type_id)

func _open_house_menu() -> void:
	workbench_menu.visible = true
	touch_controls.input_enabled = false
	_refresh_workbench_menu()

func _close_house_menu() -> void:
	workbench_menu.visible = false
	touch_controls.input_enabled = true

func _show_upgrades_tab() -> void:
	upgrades_tab.visible = true
	benches_tab.visible = false
	casa_tab.visible = false

func _show_benches_tab() -> void:
	upgrades_tab.visible = false
	benches_tab.visible = true
	casa_tab.visible = false
	_refresh_benches_tab()

func _show_casa_tab() -> void:
	upgrades_tab.visible = false
	benches_tab.visible = false
	casa_tab.visible = true
	_refresh_casa_tab()

func _refresh_workbench_menu() -> void:
	money_materials_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for id in PlayerUpgrades.ORDER:
		var level: int = CheckpointData.upgrades.get(id, 0)
		var def: Dictionary = PlayerUpgrades.DEFS[id]
		var row := get_node("HUD/WorkbenchMenu/Scroll/Box/UpgradesTab/Row_%s" % id)
		var info: Label = row.get_node("InfoLabel")
		var btn: Button = row.get_node("BuyButton")
		if PlayerUpgrades.is_maxed(id, level):
			info.text = "%s — LIVELLO MASSIMO (%d/%d)" % [def.label, level, PlayerUpgrades.MAX_LEVEL]
			btn.disabled = true
			btn.text = "Massimo"
		else:
			var cm := PlayerUpgrades.cost_money(id, level)
			var cmat := PlayerUpgrades.cost_material(id, level)
			var mat_name: String = MATERIAL_LABELS.get(def.material, def.material)
			info.text = "%s (Lv %d/%d)\n%s — costa %d€ + %d %s" % [def.label, level, PlayerUpgrades.MAX_LEVEL, def.desc, cm, cmat, mat_name]
			var can_afford: bool = CheckpointData.money >= cm and CheckpointData.materials.get(def.material, 0) >= cmat
			btn.disabled = not can_afford
			btn.text = "Compra"
	if benches_tab.visible:
		_refresh_benches_tab()
	if casa_tab.visible:
		_refresh_casa_tab()

func _refresh_benches_tab() -> void:
	money_materials_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	_refresh_bench_row("armi_bianche")
	_refresh_bench_row("armi_da_fuoco")
	_refresh_bench_row("armi_da_lancio")
	_refresh_bench_row("armi_esplosive")
	_refresh_bench_row("armadio")

func _refresh_bench_row(type_id: String) -> void:
	var row := get_node("HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_%s" % type_id)
	var info: Label = row.get_node("InfoLabel")
	var btn: Button = row.get_node("BuyButton")
	if _has_placed_bench(type_id):
		info.text = "%s — posizionato in casa" % BENCH_LABELS.get(type_id, type_id)
		btn.disabled = true
		btn.text = "Posizionato"
	else:
		var cost: Dictionary = BENCH_COSTS[type_id]
		var mat_name: String = MATERIAL_LABELS.get(cost.material, cost.material)
		info.text = "%s\n%s — costa %d€ + %d %s" % [BENCH_LABELS.get(type_id, type_id), BENCH_UNLOCK_DESC.get(type_id, ""), cost.money, cost.amount, mat_name]
		var afford: bool = CheckpointData.money >= cost.money and CheckpointData.materials.get(cost.material, 0) >= cost.amount
		btn.disabled = not afford
		btn.text = "Compra"

func _refresh_casa_tab() -> void:
	money_materials_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	var row := $HUD/WorkbenchMenu/Scroll/Box/CasaTab/Row_house
	var info: Label = row.get_node("InfoLabel")
	var btn: Button = row.get_node("BuyButton")
	var cur: Dictionary = HouseTiers.tier_data(CheckpointData.house_tier)
	var cur_space := HouseTiers.describe_space(CheckpointData.house_tier)
	if HouseTiers.is_max_tier(CheckpointData.house_tier):
		info.text = "Abitazione attuale: %s (%s)\nHai raggiunto il tier massimo di abitazione." % [cur.label, cur_space]
		btn.disabled = true
		btn.text = "Massimo"
		return
	var next_idx := HouseTiers.next_tier_index(CheckpointData.house_tier)
	var nxt: Dictionary = HouseTiers.tier_data(next_idx)
	var nxt_space := HouseTiers.describe_space(next_idx)
	var mat_name: String = MATERIAL_LABELS.get(nxt.cost_material, nxt.cost_material)
	if CheckpointData.zone < int(nxt.zone_required):
		info.text = "Abitazione attuale: %s (%s)\nProssima abitazione: %s (%s) — si sblocca alla zona %d" % [
			cur.label, cur_space, nxt.label, nxt_space, nxt.zone_required,
		]
		btn.disabled = true
		btn.text = "Bloccata"
		return
	info.text = "Abitazione attuale: %s (%s)\nProssima abitazione: %s (%s) — costa %d€ + %d %s" % [
		cur.label, cur_space, nxt.label, nxt_space, nxt.cost_money, nxt.cost_amount, mat_name,
	]
	var afford: bool = CheckpointData.money >= int(nxt.cost_money) and CheckpointData.materials.get(String(nxt.cost_material), 0) >= int(nxt.cost_amount)
	btn.disabled = not afford
	btn.text = "Compra"

func _on_buy_house_tier_pressed() -> void:
	if HouseTiers.is_max_tier(CheckpointData.house_tier):
		return
	var next_idx := HouseTiers.next_tier_index(CheckpointData.house_tier)
	var nxt: Dictionary = HouseTiers.tier_data(next_idx)
	if CheckpointData.zone < int(nxt.zone_required):
		return
	if CheckpointData.money < int(nxt.cost_money) or CheckpointData.materials.get(String(nxt.cost_material), 0) < int(nxt.cost_amount):
		return
	CheckpointData.money -= int(nxt.cost_money)
	CheckpointData.materials[String(nxt.cost_material)] = CheckpointData.materials.get(String(nxt.cost_material), 0) - int(nxt.cost_amount)
	CheckpointData.house_tier = next_idx
	_relocate_benches_for_shrunk_floors()
	_apply_house_tier_geometry()
	_close_house_menu()
	player.global_position = _interior_spawn_position()
	player.face_direction(Vector3(0, 0, -1))

# Un tier più avanzato non ha sempre piani/griglie più grandi di quello
# precedente (es. "casa" 4x5 -> "casa a due piani" 3x4 al piano terra): un
# banco che era in una cella valida può finire fuori dai nuovi limiti,
# causando un accesso fuori indice a col_values/row_values al prossimo
# ricalcolo della geometria. Qui si riportano piano/cella a un valore
# sicuro (0,0) per qualunque banco (compreso quello della casa, che non è
# in placed_benches) che non rientri più nella nuova griglia.
func _relocate_benches_for_shrunk_floors() -> void:
	var new_floor_count := HouseTiers.floor_count(CheckpointData.house_tier)
	for i in range(CheckpointData.placed_benches.size()):
		var b: Dictionary = CheckpointData.placed_benches[i]
		var floor_idx: int = int(b.get("floor", 0))
		if floor_idx >= new_floor_count:
			b["floor"] = new_floor_count - 1
			b["col_idx"] = 0
			b["row_idx"] = 0
			CheckpointData.placed_benches[i] = b
			continue
		var orientation: String = String(b.get("orientation", "h"))
		if not _fits_floor_grid(orientation, int(b.get("col_idx", 0)), int(b.get("row_idx", 0)), floor_idx):
			b["col_idx"] = 0
			b["row_idx"] = 0
			CheckpointData.placed_benches[i] = b
	if not _fits_floor_grid(CheckpointData.house_bench_orientation, CheckpointData.house_bench_col_idx, CheckpointData.house_bench_row_idx, 0):
		CheckpointData.house_bench_col_idx = 0
		CheckpointData.house_bench_row_idx = 0

# L'orientamento salvato ("h"/"v" più l'eventuale suffisso "180" per la
# rotazione di 180°) codifica due cose distinte: l'asse dell'ingombro a due
# celle (invariato dalla rotazione: "h"/"h180" occupano sempre due colonne
# sulla stessa riga, "v"/"v180" sempre due righe sulla stessa colonna) e la
# direzione in cui l'oggetto guarda (0°/180° per "h", 90°/270° per "v").
# Tutta la matematica di griglia/ingombro usa solo l'asse, mai il verso.
func _orientation_axis(orientation: String) -> String:
	return "h" if orientation.begins_with("h") else "v"

func _fits_floor_grid(orientation: String, col_idx: int, row_idx: int, floor_idx: int) -> bool:
	var cols: int = HouseTiers.col_values(CheckpointData.house_tier, floor_idx).size()
	var rows: int = HouseTiers.row_values(CheckpointData.house_tier, floor_idx).size()
	var is_h := _orientation_axis(orientation) == "h"
	var max_col: int = cols - (2 if is_h else 1)
	var max_row: int = rows - (1 if is_h else 2)
	return col_idx >= 0 and row_idx >= 0 and col_idx <= max_col and row_idx <= max_row

func _interior_spawn_position() -> Vector3:
	var depth: float = float(HouseTiers.floor_data(CheckpointData.house_tier, 0).rows) * 2.0
	return Vector3(0, 0, depth / 2.0 - 1.2)

# Luminosità/contrasto regolabili dalle Impostazioni, applicati tramite le
# proprietà native di Environment (niente shader custom): si aggiornano in
# tempo reale mentre il pannello Impostazioni resta aperto durante il gioco.
func _apply_screen_adjustment() -> void:
	var env: Environment = $WorldEnvironment.environment
	env.adjustment_enabled = true
	env.adjustment_brightness = GameSettings.brightness
	env.adjustment_contrast = GameSettings.contrast

func _apply_house_tier_geometry() -> void:
	var floors := HouseTiers.own_floors(CheckpointData.house_tier)
	var tier: Dictionary = HouseTiers.tier_data(CheckpointData.house_tier)
	var wall_color: Color = tier.wall_color

	_floor_mesh_instances.clear()
	_floor_mesh_instances[0] = []
	_build_floor0_geometry(floors[0], wall_color)

	var upper := get_node_or_null("UpperFloors")
	if upper != null:
		upper.free()
	upper = Node3D.new()
	upper.name = "UpperFloors"
	add_child(upper)
	for f in range(1, floors.size()):
		_build_upper_floor(upper, f, floors[f], wall_color)

	var stairs := get_node_or_null("Stairs")
	if stairs != null:
		stairs.free()
	stairs = Node3D.new()
	stairs.name = "Stairs"
	add_child(stairs)
	_build_stairs(stairs, floors)

	_set_current_floor(0)

func _build_floor0_geometry(dims: Dictionary, wall_color: Color) -> void:
	var width: float = float(dims.cols) * 2.0
	var depth: float = float(dims.rows) * 2.0
	# Griglia del piano terra ricalcolata al volo: i col_values/row_values
	# membro riflettono ancora il tier precedente finché _set_current_floor(0)
	# non li aggiorna, più sotto in questa stessa funzione chiamante.
	var cvals := HouseTiers.col_values(CheckpointData.house_tier, 0)
	var rvals := HouseTiers.row_values(CheckpointData.house_tier, 0)

	var floor_mesh: PlaneMesh = $Floor/Mesh.mesh
	floor_mesh.size = Vector2(width, depth)
	# Materiale unico (non condiviso) per poterne cambiare l'alpha in
	# dissolvenza senza toccare altri mesh.
	var floor_own_mat: StandardMaterial3D = ($Floor/Mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	$Floor/Mesh.set_surface_override_material(0, floor_own_mat)
	# Una shape delimitata invece del WorldBoundaryShape3D (piano infinito)
	# originale: un piano infinito a y=0 bloccherebbe fisicamente ovunque nel
	# mondo, impedendo di scendere ai piani sotterranei del bunker che stanno
	# a y negative.
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(width, 0.2, depth)
	$Floor/CollisionShape3D.shape = floor_shape
	$Floor/CollisionShape3D.position = Vector3(0, -0.1, 0)

	var ns_mesh := BoxMesh.new()
	ns_mesh.size = Vector3(width, 2.5, 0.2)
	var ns_shape := BoxShape3D.new()
	ns_shape.size = Vector3(width, 2.5, 0.2)
	$WallNorth/Mesh.mesh = ns_mesh
	$WallNorth/CollisionShape3D.shape = ns_shape
	$WallNorth.position = Vector3(0, 1.25, -depth / 2.0)
	$WallNorth/Mesh.set_surface_override_material(0, _tinted_wall_material(wall_color))

	var ew_mesh := BoxMesh.new()
	ew_mesh.size = Vector3(0.2, 2.5, depth)
	var ew_shape := BoxShape3D.new()
	ew_shape.size = Vector3(0.2, 2.5, depth)
	$WallEast/Mesh.mesh = ew_mesh
	$WallEast/CollisionShape3D.shape = ew_shape
	$WallEast.position = Vector3(width / 2.0, 1.25, 0)
	$WallEast/Mesh.set_surface_override_material(0, _tinted_wall_material(wall_color))
	$WallWest/Mesh.mesh = ew_mesh
	$WallWest/CollisionShape3D.shape = ew_shape
	$WallWest.position = Vector3(-width / 2.0, 1.25, 0)
	$WallWest/Mesh.set_surface_override_material(0, _tinted_wall_material(wall_color))

	var seg_width: float = (width - DOOR_GAP) / 2.0
	var seg_x: float = DOOR_GAP / 2.0 + seg_width / 2.0
	var seg_mesh := BoxMesh.new()
	seg_mesh.size = Vector3(seg_width, 2.5, 0.2)
	var seg_shape := BoxShape3D.new()
	seg_shape.size = Vector3(seg_width, 2.5, 0.2)
	$WallSouthLeft/Mesh.mesh = seg_mesh
	$WallSouthLeft/CollisionShape3D.shape = seg_shape
	$WallSouthLeft.position = Vector3(-seg_x, 1.25, depth / 2.0)
	$WallSouthLeft/Mesh.set_surface_override_material(0, _tinted_wall_material(wall_color))
	$WallSouthRight/Mesh.mesh = seg_mesh
	$WallSouthRight/CollisionShape3D.shape = seg_shape
	$WallSouthRight.position = Vector3(seg_x, 1.25, depth / 2.0)
	$WallSouthRight/Mesh.set_surface_override_material(0, _tinted_wall_material(wall_color))

	_floor_mesh_instances[0] = [
		$Floor/Mesh, $WallNorth/Mesh, $WallEast/Mesh, $WallWest/Mesh,
		$WallSouthLeft/Mesh, $WallSouthRight/Mesh,
	]

	$DoorTrigger.position = Vector3(0, 1, depth / 2.0 + 0.6)
	var wb_orientation := CheckpointData.house_bench_orientation
	var wb_col: int = CheckpointData.house_bench_col_idx
	var wb_row: int = CheckpointData.house_bench_row_idx
	if _orientation_axis(wb_orientation) == "h":
		$Workbench.position = Vector3((cvals[wb_col] + cvals[wb_col + 1]) / 2.0, 0, rvals[wb_row])
	else:
		$Workbench.position = Vector3(cvals[wb_col], 0, (rvals[wb_row] + rvals[wb_row + 1]) / 2.0)
	$Workbench.rotation_degrees.y = _bench_rotation_y(wb_orientation)

func _build_upper_floor(container: Node3D, floor_idx: int, dims: Dictionary, wall_color: Color) -> void:
	var width: float = float(dims.cols) * 2.0
	var depth: float = float(dims.rows) * 2.0
	var y: float = HouseTiers.floor_y(CheckpointData.house_tier, floor_idx)

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor%d" % floor_idx
	floor_body.position = Vector3(0, y, 0)
	container.add_child(floor_body)

	var floor_mesh_inst := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(width, depth)
	floor_mesh_inst.mesh = pm
	floor_mesh_inst.set_surface_override_material(0, _tinted_wall_material(Color(0.32, 0.28, 0.24, 1)))
	floor_body.add_child(floor_mesh_inst)

	var floor_shape_inst := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, 0.2, depth)
	floor_shape_inst.shape = box_shape
	floor_shape_inst.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_shape_inst)

	var floor_meshes: Array = [floor_mesh_inst]
	_floor_mesh_instances[floor_idx] = floor_meshes

	var wall_specs := [
		{"pos": Vector3(0, y + 1.25, -depth / 2.0), "size": Vector3(width, 2.5, 0.2)},
		{"pos": Vector3(0, y + 1.25, depth / 2.0), "size": Vector3(width, 2.5, 0.2)},
		{"pos": Vector3(width / 2.0, y + 1.25, 0), "size": Vector3(0.2, 2.5, depth)},
		{"pos": Vector3(-width / 2.0, y + 1.25, 0), "size": Vector3(0.2, 2.5, depth)},
	]
	for i in range(wall_specs.size()):
		var spec: Dictionary = wall_specs[i]
		var wall := StaticBody3D.new()
		wall.name = "Wall%d_%d" % [floor_idx, i]
		wall.position = spec.pos
		container.add_child(wall)
		var wm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec.size
		wm.mesh = bm
		wm.set_surface_override_material(0, _tinted_wall_material(wall_color))
		wall.add_child(wm)
		floor_meshes.append(wm)
		var wc := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = spec.size
		wc.shape = bs
		wall.add_child(wc)

func _corner_pos(cvals: Array, rvals: Array, corner: int) -> Vector2:
	var last_c: int = cvals.size() - 1
	var last_r: int = rvals.size() - 1
	match corner:
		0:
			return Vector2(cvals[0] + 0.5, rvals[0] + 0.5)
		1:
			return Vector2(cvals[last_c] - 0.5, rvals[last_r] - 0.5)
		2:
			return Vector2(cvals[last_c] - 0.5, rvals[0] + 0.5)
		_:
			return Vector2(cvals[0] + 0.5, rvals[last_r] - 0.5)

func _build_stairs(container: Node3D, floors: Array) -> void:
	var stair_mat := _tinted_wall_material(Color(0.55, 0.5, 0.42, 1))
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(1.2, 0.12, 1.2)
	for f in range(floors.size() - 1):
		var lower_cols := HouseTiers.col_values(CheckpointData.house_tier, f)
		var lower_rows := HouseTiers.row_values(CheckpointData.house_tier, f)
		var upper_cols := HouseTiers.col_values(CheckpointData.house_tier, f + 1)
		var upper_rows := HouseTiers.row_values(CheckpointData.house_tier, f + 1)
		# Ogni piano intermedio partecipa a due scale (una verso il piano
		# sotto, una verso quello sopra). Il punto "scendi" di un piano usa
		# sempre uno dei due angoli 0/1, quello "sali" sempre uno dei due
		# angoli 2/3 (diagonalmente opposti): così, qualunque sia la
		# combinazione di piani, le due scale di uno stesso piano non
		# coincidono mai nello stesso punto fisico.
		var up_corner: int = 2 + (f % 2)
		var down_corner: int = (f + 1) % 2
		var lpos := _corner_pos(lower_cols, lower_rows, up_corner)
		var upos := _corner_pos(upper_cols, upper_rows, down_corner)
		var lx: float = lpos.x
		var lz: float = lpos.y
		var ux: float = upos.x
		var uz: float = upos.y
		var ly: float = HouseTiers.floor_y(CheckpointData.house_tier, f)
		var uy: float = HouseTiers.floor_y(CheckpointData.house_tier, f + 1)
		# I punti di arrivo (dove il player compare dopo aver salito/sceso)
		# sono volutamente lontani dagli angoli usati dai trigger: se
		# coincidessero con il trigger di partenza dell'altro verso, il
		# player rientrerebbe subito nella zona e rimbalzerebbe su e giù.
		var arrive_up_z: float = upper_rows[0] + 0.5
		var arrive_down_z: float = lower_rows[0] + 0.5

		var up_marker := MeshInstance3D.new()
		up_marker.mesh = marker_mesh
		up_marker.set_surface_override_material(0, stair_mat)
		up_marker.position = Vector3(lx, ly + 0.06, lz)
		container.add_child(up_marker)

		var down_marker := MeshInstance3D.new()
		down_marker.mesh = marker_mesh
		down_marker.set_surface_override_material(0, stair_mat)
		down_marker.position = Vector3(ux, uy + 0.06, uz)
		container.add_child(down_marker)

		var up_trigger := Area3D.new()
		up_trigger.name = "StairsUp_%d" % f
		up_trigger.collision_layer = 0
		up_trigger.collision_mask = 2
		up_trigger.position = Vector3(lx, ly + 1.0, lz)
		var up_shape := CollisionShape3D.new()
		var up_box := BoxShape3D.new()
		up_box.size = Vector3(1.2, 2.0, 1.2)
		up_shape.shape = up_box
		up_trigger.add_child(up_shape)
		container.add_child(up_trigger)
		up_trigger.body_entered.connect(_on_stairs_entered.bind(f + 1, 0.0, uy + 0.1, arrive_up_z))

		var down_trigger := Area3D.new()
		down_trigger.name = "StairsDown_%d" % (f + 1)
		down_trigger.collision_layer = 0
		down_trigger.collision_mask = 2
		down_trigger.position = Vector3(ux, uy + 1.0, uz)
		var down_shape := CollisionShape3D.new()
		var down_box := BoxShape3D.new()
		down_box.size = Vector3(1.2, 2.0, 1.2)
		down_shape.shape = down_box
		down_trigger.add_child(down_shape)
		container.add_child(down_trigger)
		down_trigger.body_entered.connect(_on_stairs_entered.bind(f, 0.0, ly + 0.1, arrive_down_z))

const STAIRS_COOLDOWN := 0.5

func _on_stairs_entered(body: Node3D, target_floor: int, target_x: float, target_y: float, target_z: float) -> void:
	if not body.is_in_group("player"):
		return
	if stairs_cooldown_timer > 0.0:
		return
	if placing_bench_type != "":
		_end_placement()
	body.global_position = Vector3(target_x, target_y, target_z)
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO
	_set_current_floor(target_floor)
	stairs_cooldown_timer = STAIRS_COOLDOWN

const FLOOR_FADE_TRANSPARENCY := 0.92

func _set_current_floor(floor_idx: int) -> void:
	current_floor = floor_idx
	col_values = HouseTiers.col_values(CheckpointData.house_tier, current_floor)
	row_values = HouseTiers.row_values(CheckpointData.house_tier, current_floor)
	_update_floor_visibility()

func _update_floor_visibility() -> void:
	var current_y := HouseTiers.floor_y(CheckpointData.house_tier, current_floor)
	for f in _floor_mesh_instances.keys():
		var floor_y: float = HouseTiers.floor_y(CheckpointData.house_tier, f)
		var above: bool = floor_y > current_y + 0.1
		var alpha: float = 1.0 - FLOOR_FADE_TRANSPARENCY if above else 1.0
		for mesh_inst in _floor_mesh_instances[f]:
			_set_material_alpha(mesh_inst, alpha)

# GeometryInstance3D.transparency non è supportato dal renderer di
# compatibilità (usato dall'export Web), quindi la dissolvenza va fatta
# modificando direttamente l'alpha del materiale, che funziona ovunque.
func _set_material_alpha(mesh_inst: MeshInstance3D, alpha: float) -> void:
	var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color.a = alpha
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED

func _tinted_wall_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func _has_placed_bench(type_id: String) -> bool:
	for b in CheckpointData.placed_benches:
		if String(b.get("type", "")) == type_id:
			return true
	return false

func _on_buy_upgrade_pressed(id: String) -> void:
	var level: int = CheckpointData.upgrades.get(id, 0)
	if PlayerUpgrades.is_maxed(id, level):
		return
	var def: Dictionary = PlayerUpgrades.DEFS[id]
	var cm := PlayerUpgrades.cost_money(id, level)
	var cmat := PlayerUpgrades.cost_material(id, level)
	if CheckpointData.money < cm or CheckpointData.materials.get(def.material, 0) < cmat:
		return
	CheckpointData.money -= cm
	CheckpointData.materials[def.material] = CheckpointData.materials.get(def.material, 0) - cmat
	CheckpointData.upgrades[id] = level + 1
	_refresh_workbench_menu()

func _on_buy_bench_pressed(type_id: String) -> void:
	if _has_placed_bench(type_id):
		return
	var cost: Dictionary = BENCH_COSTS[type_id]
	if CheckpointData.money < cost.money or CheckpointData.materials.get(cost.material, 0) < cost.amount:
		return
	_start_bench_placement(type_id)

func _start_bench_placement(type_id: String) -> void:
	placing_bench_type = type_id
	workbench_menu.visible = false
	touch_controls.input_enabled = false
	touch_controls.move_vector = Vector2.ZERO
	touch_controls.attack_held = false

	placing_ghost = BENCH_SCENES[type_id].instantiate()
	bench_ghost_holder.add_child(placing_ghost)

	placing_orientation = "h"
	var slot = _first_free_slot("h")
	if slot == null:
		slot = _first_free_slot("v")
		if slot != null:
			placing_orientation = "v"
	if slot == null:
		slot = {"row_idx": 0, "col_idx": 0}
	placing_row_idx = slot.row_idx
	placing_col_idx = slot.col_idx

	_apply_ghost_transform()
	placement_highlight.visible = true
	placement_ui.visible = true
	floor_row.visible = HouseTiers.floor_count(CheckpointData.house_tier) > 1
	_update_floor_buttons()
	_update_placement_validity()

func _cell_key(col_idx: int, row_idx: int) -> String:
	return "%d:%d" % [col_idx, row_idx]

func _footprint_cells(orientation: String, col_idx: int, row_idx: int) -> Array:
	if _orientation_axis(orientation) == "h":
		return [_cell_key(col_idx, row_idx), _cell_key(col_idx + 1, row_idx)]
	return [_cell_key(col_idx, row_idx), _cell_key(col_idx, row_idx + 1)]

func _occupied_cells() -> Dictionary:
	var occ := {}
	if current_floor == 0 and not moving_house_bench:
		for key in _footprint_cells(CheckpointData.house_bench_orientation, CheckpointData.house_bench_col_idx, CheckpointData.house_bench_row_idx):
			occ[key] = true
	for i in range(CheckpointData.placed_benches.size()):
		if i == moving_bench_from_index:
			continue
		var b: Dictionary = CheckpointData.placed_benches[i]
		if int(b.get("floor", 0)) != current_floor:
			continue
		var orientation: String = String(b.get("orientation", "h"))
		var col_idx: int = int(b.get("col_idx", 0))
		var row_idx: int = int(b.get("row_idx", 0))
		for key in _footprint_cells(orientation, col_idx, row_idx):
			occ[key] = true
	return occ

func _first_free_slot(orientation: String):
	var occ := _occupied_cells()
	if orientation == "h":
		for r in range(row_values.size()):
			for c in range(col_values.size() - 1):
				var cells := _footprint_cells("h", c, r)
				if not occ.has(cells[0]) and not occ.has(cells[1]):
					return {"row_idx": r, "col_idx": c}
	else:
		for c in range(col_values.size()):
			for r in range(row_values.size() - 1):
				var cells := _footprint_cells("v", c, r)
				if not occ.has(cells[0]) and not occ.has(cells[1]):
					return {"row_idx": r, "col_idx": c}
	return null

func _bench_world_position(orientation: String, col_idx: int, row_idx: int, floor_idx: int = -1) -> Vector3:
	var f: int = current_floor if floor_idx < 0 else floor_idx
	var cvals: Array = col_values if f == current_floor else HouseTiers.col_values(CheckpointData.house_tier, f)
	var rvals: Array = row_values if f == current_floor else HouseTiers.row_values(CheckpointData.house_tier, f)
	var y: float = HouseTiers.floor_y(CheckpointData.house_tier, f)
	if _orientation_axis(orientation) == "h":
		var x: float = (cvals[col_idx] + cvals[col_idx + 1]) / 2.0
		return Vector3(x, y, rvals[row_idx])
	var z: float = (rvals[row_idx] + rvals[row_idx + 1]) / 2.0
	return Vector3(cvals[col_idx], y, z)

# 4 direzioni, una ogni 90°: "h"=0°, "v"=90°, "h180"=180°, "v180"=270°. Il
# giro di 180° non cambia l'asse dell'ingombro (vedi _orientation_axis), solo
# il verso in cui l'oggetto guarda — così non resta bloccato a guardare
# sempre la stessa parete o sempre quella opposta.
func _bench_rotation_y(orientation: String) -> float:
	match orientation:
		"v":
			return 90.0
		"h180":
			return 180.0
		"v180":
			return 270.0
		_:
			return 0.0

func _nearest_index(values: Array, v: float) -> int:
	var best_i := 0
	var best_d := INF
	for i in range(values.size()):
		var d: float = absf(v - float(values[i]))
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _nearest_pair_index(values: Array, v: float) -> int:
	var best_i := 0
	var best_d := INF
	for i in range(values.size() - 1):
		var mid: float = (values[i] + values[i + 1]) / 2.0
		var d: float = absf(v - mid)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _nearest_anchor(orientation: String, world_point: Vector3) -> Dictionary:
	if _orientation_axis(orientation) == "h":
		return {"row_idx": _nearest_index(row_values, world_point.z), "col_idx": _nearest_pair_index(col_values, world_point.x)}
	return {"row_idx": _nearest_pair_index(row_values, world_point.z), "col_idx": _nearest_index(col_values, world_point.x)}

func _apply_ghost_transform() -> void:
	placing_ghost.position = _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx)
	placing_ghost.rotation_degrees.y = _bench_rotation_y(placing_orientation)

const ORIENTATION_CYCLE := ["h", "v", "h180", "v180"]

func _on_rotate_placement_pressed() -> void:
	var current_pos := _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx)
	var idx := ORIENTATION_CYCLE.find(placing_orientation)
	placing_orientation = ORIENTATION_CYCLE[(maxi(idx, 0) + 1) % ORIENTATION_CYCLE.size()]
	var anchor := _nearest_anchor(placing_orientation, current_pos)
	placing_row_idx = anchor.row_idx
	placing_col_idx = anchor.col_idx
	_apply_ghost_transform()
	_update_placement_validity()

func _on_floor_up_pressed() -> void:
	if current_floor + 1 >= HouseTiers.floor_count(CheckpointData.house_tier):
		return
	_move_placement_to_floor(current_floor + 1)

func _on_floor_down_pressed() -> void:
	if current_floor <= 0:
		return
	_move_placement_to_floor(current_floor - 1)

# Il player segue l'oggetto che sta spostando: durante la modalità
# spostamento i comandi di movimento sono disabilitati (non si potrebbe
# comunque raggiungere le scale), quindi lo teletrasportiamo al centro del
# nuovo piano così può continuare a vedere/trascinare/ruotare il fantasma
# esattamente come prima, solo sul piano scelto.
func _move_placement_to_floor(floor_idx: int) -> void:
	_set_current_floor(floor_idx)
	if _orientation_axis(placing_orientation) == "h":
		placing_col_idx = clampi(placing_col_idx, 0, maxi(col_values.size() - 2, 0))
		placing_row_idx = clampi(placing_row_idx, 0, maxi(row_values.size() - 1, 0))
	else:
		placing_col_idx = clampi(placing_col_idx, 0, maxi(col_values.size() - 1, 0))
		placing_row_idx = clampi(placing_row_idx, 0, maxi(row_values.size() - 2, 0))
	player.global_position = Vector3(0, HouseTiers.floor_y(CheckpointData.house_tier, floor_idx), 0)
	_apply_ghost_transform()
	_update_placement_validity()
	_update_floor_buttons()

func _update_floor_buttons() -> void:
	floor_down_button.disabled = current_floor <= 0
	floor_up_button.disabled = current_floor + 1 >= HouseTiers.floor_count(CheckpointData.house_tier)

func _update_placement_validity() -> void:
	var cells := _footprint_cells(placing_orientation, placing_col_idx, placing_row_idx)
	var occ := _occupied_cells()
	placing_valid = not occ.has(cells[0]) and not occ.has(cells[1])
	var pos := _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx)
	placement_highlight.position = pos + Vector3(0, 0.02, 0)
	placement_highlight.rotation_degrees.y = _bench_rotation_y(placing_orientation)
	placement_highlight.set_surface_override_material(0, _placement_material(placing_valid))
	$HUD/PlacementUI/ButtonRow/ConfirmButton.disabled = not placing_valid

func _placement_material(valid: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if valid:
		mat.albedo_color = Color(0.3, 1.0, 0.4, 0.5)
	else:
		mat.albedo_color = Color(1.0, 0.25, 0.2, 0.5)
	return mat

func _input(event: InputEvent) -> void:
	if placing_bench_type == "":
		return
	var pos := Vector2.ZERO
	var relevant := false
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
		relevant = true
	elif event is InputEventScreenDrag:
		pos = event.position
		relevant = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		relevant = true
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = event.position
		relevant = true
	if not relevant:
		return
	_update_ghost_from_screen(pos)

func _update_ghost_from_screen(pos: Vector2) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	if pos.y > vp_size.y - 170.0:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var origin := cam.project_ray_origin(pos)
	var normal := cam.project_ray_normal(pos)
	if absf(normal.y) < 0.0001:
		return
	var floor_y: float = HouseTiers.floor_y(CheckpointData.house_tier, current_floor)
	var t: float = (floor_y - origin.y) / normal.y
	if t < 0.0:
		return
	var world_point := origin + normal * t
	var anchor := _nearest_anchor(placing_orientation, world_point)
	placing_row_idx = anchor.row_idx
	placing_col_idx = anchor.col_idx
	_apply_ghost_transform()
	_update_placement_validity()

func _on_confirm_placement_pressed() -> void:
	if not placing_valid:
		return
	var type_id := placing_bench_type
	if type_id == "casa":
		CheckpointData.house_bench_orientation = placing_orientation
		CheckpointData.house_bench_col_idx = placing_col_idx
		CheckpointData.house_bench_row_idx = placing_row_idx
		$Workbench.position = _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx, current_floor)
		$Workbench.rotation_degrees.y = _bench_rotation_y(placing_orientation)
		_end_placement()
		return
	if moving_bench_from_index >= 0:
		CheckpointData.placed_benches[moving_bench_from_index] = {
			"type": type_id, "orientation": placing_orientation,
			"col_idx": placing_col_idx, "row_idx": placing_row_idx, "floor": current_floor,
		}
	else:
		var cost: Dictionary = BENCH_COSTS[type_id]
		CheckpointData.money -= int(cost.money)
		CheckpointData.materials[cost.material] = CheckpointData.materials.get(cost.material, 0) - int(cost.amount)
		CheckpointData.placed_benches.append({
			"type": type_id, "orientation": placing_orientation,
			"col_idx": placing_col_idx, "row_idx": placing_row_idx, "floor": current_floor,
		})
	if _placed_bench_nodes.has(type_id):
		_placed_bench_nodes[type_id].queue_free()
		_placed_bench_nodes.erase(type_id)
	_instantiate_placed_bench(type_id, placing_orientation, placing_col_idx, placing_row_idx, current_floor)
	_end_placement()

func _on_cancel_placement_pressed() -> void:
	_end_placement()

func _end_placement() -> void:
	placing_bench_type = ""
	moving_bench_from_index = -1
	moving_house_bench = false
	if placing_ghost != null:
		placing_ghost.queue_free()
		placing_ghost = null
	placement_ui.visible = false
	placement_highlight.visible = false
	touch_controls.input_enabled = true
	_refresh_workbench_menu()

func _instantiate_placed_bench(type_id: String, orientation: String, col_idx: int, row_idx: int, floor_idx: int = 0) -> void:
	if not BENCH_SCENES.has(type_id):
		return
	var node: Node3D = BENCH_SCENES[type_id].instantiate()
	node.position = _bench_world_position(orientation, col_idx, row_idx, floor_idx)
	node.rotation_degrees.y = _bench_rotation_y(orientation)
	placed_benches_root.add_child(node)
	_placed_bench_nodes[type_id] = node

func _open_weapon_menu() -> void:
	weapon_menu.visible = true
	touch_controls.input_enabled = false
	_refresh_weapon_menu()

func _close_weapon_menu() -> void:
	weapon_menu.visible = false
	touch_controls.input_enabled = true

# Inserisce una linea sottile subito prima della riga di potenziamento tid,
# per separare visivamente i vari potenziamenti tra loro (e dalla riga
# principale/munizioni sopra) quando il menu a tendina è aperto.
func _insert_track_separator(base: Node, tid: String, track_row: Control) -> void:
	var sep := HSeparator.new()
	sep.name = "UpSep_%s" % tid
	base.add_child(sep)
	base.move_child(sep, track_row.get_index())

# La traccia "respinta" esiste solo per le armi bianche più pesanti (vedi
# MeleeWeapons.KNOCKBACK_CATEGORIES) e non ha una riga propria nella scena
# .tscn (a differenza di portata/velocità/danno/estrazione): la creiamo qui
# a runtime, con lo stesso stile delle altre righe di potenziamento.
func _get_or_create_track_row(base: Node, tid: String) -> HBoxContainer:
	var row_name := "Track_%s" % tid
	if base.has_node(row_name):
		return base.get_node(row_name)
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 20)
	base.add_child(row)

	var info := Label.new()
	info.name = "InfoLabel"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(info)

	var btn := Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(150, 56)
	btn.add_theme_font_size_override("font_size", 23)
	btn.text = "Potenzia"
	row.add_child(btn)

	return row

# Tocca il nome di un'arma per aprire/chiudere il suo "menu a tendina" con
# statistiche e potenziamenti (nascosti di default, per non lasciare blocchi
# di testo troppo lunghi nella lista). Ritoccando il nome si richiude.
#
# Un singolo tocco fisico sul touchscreen può generare sia un
# InputEventScreenTouch che un InputEventMouseButton "emulato" per lo stesso
# gesto: senza filtro, i due eventi facevano scattare il toggle due volte
# (apre e richiude subito), lasciando il pannello bloccato aperto al tocco
# successivo. Ignoriamo un secondo "pressed" sulla stessa arma se arriva a
# ridosso del precedente.
const WEAPON_TOGGLE_DEBOUNCE_MS := 250
var _weapon_toggle_last_ms := {}

func _on_weapon_name_gui_input(event: InputEvent, wid: String, refresh_callable: Callable) -> void:
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
	if not pressed:
		return
	var now := Time.get_ticks_msec()
	var last: int = _weapon_toggle_last_ms.get(wid, -WEAPON_TOGGLE_DEBOUNCE_MS - 1)
	if now - last < WEAPON_TOGGLE_DEBOUNCE_MS:
		return
	_weapon_toggle_last_ms[wid] = now
	_expanded_weapons[wid] = not _expanded_weapons.get(wid, false)
	refresh_callable.call()

func _show_weapon_category(cat_id: String) -> void:
	current_weapon_category = cat_id
	for cid in MeleeWeapons.CATEGORY_ORDER:
		get_node("HUD/WeaponMenu/Scroll/Box/%s" % CATEGORY_BOXES[cid]).visible = (cid == cat_id)
	if weapon_menu.visible:
		_refresh_weapon_menu()

func _refresh_weapon_menu() -> void:
	weapon_money_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for wid in MeleeWeapons.CATEGORY_WEAPONS[current_weapon_category]:
		var base := get_node("HUD/WeaponMenu/Scroll/Box/%s/Weapon_%s" % [CATEGORY_BOXES[current_weapon_category], wid])
		var main_info: Label = base.get_node("MainRow/InfoLabel")
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		var def: Dictionary = MeleeWeapons.WEAPONS[wid]
		var owned: bool = CheckpointData.owned_weapons.get(wid, false)
		var equipped: bool = CheckpointData.equipped_weapon == wid
		var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})

		if not owned:
			var mat_name: String = MATERIAL_LABELS.get(def.price_material, def.price_material)
			main_info.text = "%s\nDanno %d · Cooldown %.2fs · Portata x%.2f\nCosta %d€ + %d %s" % [
				def.label, int(def.damage), def.cooldown, def.reach_mult, def.price_money, def.price_amount, mat_name,
			]
			var afford: bool = CheckpointData.money >= def.price_money and CheckpointData.materials.get(def.price_material, 0) >= def.price_amount
			action_btn.disabled = not afford
			action_btn.text = "Compra"
		else:
			var stats_line := "Danno %d · Cooldown %.2fs · Portata x%.2f · Estrazione %.2fs" % [
				int(MeleeWeapons.final_damage(wid, wups)), MeleeWeapons.final_cooldown(wid, wups),
				MeleeWeapons.final_reach_mult(wid, wups), MeleeWeapons.final_draw_time(wid, wups),
			]
			if equipped:
				main_info.text = "%s — Equipaggiata\n%s" % [def.label, stats_line]
				action_btn.disabled = true
				action_btn.text = "Equipaggiata"
				action_btn.modulate = EQUIPPED_BUTTON_MODULATE
			else:
				main_info.text = "%s — posseduta\n%s" % [def.label, stats_line]
				action_btn.disabled = false
				action_btn.text = "Equipaggia"
				action_btn.modulate = OWNED_BUTTON_MODULATE

		# Statistiche e potenziamenti restano chiusi finché non si tocca il
		# nome dell'arma, per non lasciare blocchi di testo troppo lunghi.
		var expanded: bool = _expanded_weapons.get(wid, false)
		if not expanded:
			main_info.text = main_info.text.split("\n")[0]

		for tid in MeleeWeapons.weapon_upgrade_tracks(wid):
			var track_row := _get_or_create_track_row(base, tid)
			track_row.visible = expanded
			base.get_node("UpSep_%s" % tid).visible = expanded
			var t_info: Label = track_row.get_node("InfoLabel")
			var t_btn: Button = track_row.get_node("BuyButton")
			var level: int = wups.get(tid, 0)
			var tdef: Dictionary = MeleeWeapons.UPGRADE_TRACKS[tid]
			var track_max_level: int = int(tdef.max_level)
			if not owned:
				t_info.text = "%s (si sblocca comprando l'arma)" % tdef.label
				t_btn.disabled = true
				t_btn.text = "Potenzia"
			elif MeleeWeapons.upgrade_is_maxed(level, tid):
				var maxed_value := _track_value_text(tid, wid, wups)
				t_info.text = "%s — LIVELLO MASSIMO (%d/%d)\n%s" % [tdef.label, level, track_max_level, maxed_value]
				t_btn.disabled = true
				t_btn.text = "Massimo"
			else:
				var next_wups := wups.duplicate()
				next_wups[tid] = level + 1
				var preview := _track_preview_text(tid, wid, wups, next_wups)
				var cm := MeleeWeapons.upgrade_cost_money(wid, level, tid)
				var cmat := MeleeWeapons.upgrade_cost_material(wid, level, tid)
				var mat_name2: String = MATERIAL_LABELS.get(tdef.material, tdef.material)
				t_info.text = "%s (Lv %d/%d) — %s\n%s\ncosta %d€ + %d %s" % [tdef.label, level, track_max_level, tdef.desc, preview, cm, cmat, mat_name2]
				var afford2: bool = CheckpointData.money >= cm and CheckpointData.materials.get(tdef.material, 0) >= cmat
				t_btn.disabled = not afford2
				t_btn.text = "Potenzia"

func _track_value_text(tid: String, wid: String, wups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata attuale: x%.2f" % MeleeWeapons.final_reach_mult(wid, wups)
		"velocita":
			return "Cooldown attuale: %.2fs" % MeleeWeapons.final_cooldown(wid, wups)
		"danno":
			return "Danno attuale: %d" % int(MeleeWeapons.final_damage(wid, wups))
		"estrazione":
			return "Estrazione attuale: %.2fs" % MeleeWeapons.final_draw_time(wid, wups)
		"respinta":
			return "Respinta attuale: %.1f" % MeleeWeapons.final_knockback(wid, wups)
	return ""

func _track_preview_text(tid: String, wid: String, wups: Dictionary, next_wups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata: x%.2f → x%.2f" % [MeleeWeapons.final_reach_mult(wid, wups), MeleeWeapons.final_reach_mult(wid, next_wups)]
		"velocita":
			return "Cooldown: %.2fs → %.2fs" % [MeleeWeapons.final_cooldown(wid, wups), MeleeWeapons.final_cooldown(wid, next_wups)]
		"danno":
			return "Danno: %d → %d" % [int(MeleeWeapons.final_damage(wid, wups)), int(MeleeWeapons.final_damage(wid, next_wups))]
		"estrazione":
			return "Estrazione: %.2fs → %.2fs" % [MeleeWeapons.final_draw_time(wid, wups), MeleeWeapons.final_draw_time(wid, next_wups)]
		"respinta":
			return "Respinta: %.1f → %.1f" % [MeleeWeapons.final_knockback(wid, wups), MeleeWeapons.final_knockback(wid, next_wups)]
	return ""

func _on_weapon_action_pressed(wid: String) -> void:
	var owned: bool = CheckpointData.owned_weapons.get(wid, false)
	if not owned:
		var def: Dictionary = MeleeWeapons.WEAPONS[wid]
		if CheckpointData.money < def.price_money or CheckpointData.materials.get(def.price_material, 0) < def.price_amount:
			return
		CheckpointData.money -= int(def.price_money)
		CheckpointData.materials[def.price_material] = CheckpointData.materials.get(def.price_material, 0) - int(def.price_amount)
		CheckpointData.owned_weapons[wid] = true
		CheckpointData.weapon_upgrades[wid] = {}
		CheckpointData.equipped_weapon = wid
	else:
		CheckpointData.equipped_weapon = wid
	_refresh_weapon_menu()

func _on_upgrade_weapon_pressed(wid: String, tid: String) -> void:
	var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})
	var level: int = wups.get(tid, 0)
	if MeleeWeapons.upgrade_is_maxed(level, tid):
		return
	var cm := MeleeWeapons.upgrade_cost_money(wid, level, tid)
	var cmat := MeleeWeapons.upgrade_cost_material(wid, level, tid)
	var mat: String = MeleeWeapons.UPGRADE_TRACKS[tid].material
	if CheckpointData.money < cm or CheckpointData.materials.get(mat, 0) < cmat:
		return
	CheckpointData.money -= cm
	CheckpointData.materials[mat] = CheckpointData.materials.get(mat, 0) - cmat
	wups[tid] = level + 1
	CheckpointData.weapon_upgrades[wid] = wups
	_refresh_weapon_menu()

func _open_firearm_menu() -> void:
	firearm_menu.visible = true
	touch_controls.input_enabled = false
	_refresh_firearm_menu()

func _close_firearm_menu() -> void:
	firearm_menu.visible = false
	touch_controls.input_enabled = true

func _show_firearm_category(cat_id: String) -> void:
	current_firearm_category = cat_id
	for cid in FIREARM_CATEGORY_BOXES.keys():
		get_node("HUD/FirearmMenu/Scroll/Box/%s" % FIREARM_CATEGORY_BOXES[cid]).visible = (cid == cat_id)
	if firearm_menu.visible:
		_refresh_firearm_menu()

func _refresh_firearm_menu() -> void:
	firearm_money_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for wid in Firearms.CATEGORY_WEAPONS[current_firearm_category]:
		var base := get_node("HUD/FirearmMenu/Scroll/Box/%s/Weapon_%s" % [FIREARM_CATEGORY_BOXES[current_firearm_category], wid])
		var main_info: Label = base.get_node("MainRow/InfoLabel")
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		var ammo_info: Label = base.get_node("AmmoRow/InfoLabel")
		var ammo_btn: Button = base.get_node("AmmoRow/BuyButton")
		var def: Dictionary = Firearms.WEAPONS[wid]
		var owned: bool = CheckpointData.owned_firearms.get(wid, false)
		var equipped: bool = CheckpointData.equipped_firearm == wid
		var fups: Dictionary = CheckpointData.firearm_upgrades.get(wid, {})
		var mode_label: String = _firearm_mode_label(def)

		if not owned:
			var mat_name: String = MATERIAL_LABELS.get(def.price_material, def.price_material)
			main_info.text = "%s — %s\nDanno %d · Cadenza %.2fs · Caricatore %d · Portata %d\nCosta %d€ + %d %s" % [
				def.label, mode_label, int(def.damage), def.fire_cooldown, int(def.magazine_size), int(def.range),
				def.price_money, def.price_amount, mat_name,
			]
			var afford: bool = CheckpointData.money >= def.price_money and CheckpointData.materials.get(def.price_material, 0) >= def.price_amount
			action_btn.disabled = not afford
			action_btn.text = "Compra"
			ammo_info.text = "Munizioni: si sbloccano comprando l'arma"
			ammo_btn.disabled = true
			ammo_btn.text = "Compra munizioni"
		else:
			var stats_line := "Danno %d · Cadenza %.2fs · Portata %d · Estrazione %.2fs" % [
				int(Firearms.final_damage(wid, fups)), Firearms.final_cooldown(wid, fups),
				int(Firearms.final_range(wid, fups)), Firearms.final_draw_time(wid, fups),
			]
			if equipped:
				main_info.text = "%s — Equipaggiata (%s)\n%s" % [def.label, mode_label, stats_line]
				action_btn.disabled = true
				action_btn.text = "Equipaggiata"
				action_btn.modulate = EQUIPPED_BUTTON_MODULATE
			else:
				main_info.text = "%s — posseduta (%s)\n%s" % [def.label, mode_label, stats_line]
				action_btn.disabled = false
				action_btn.text = "Equipaggia"
				action_btn.modulate = OWNED_BUTTON_MODULATE

			var reserve: int = int(CheckpointData.firearm_ammo.get(wid, 0))
			var cap: int = Firearms.final_reserve_cap(wid, fups)
			var pack_amt: int = int(def.ammo_pack_amount)
			var pack_cost: int = int(def.ammo_pack_price_money)
			if reserve >= cap:
				ammo_info.text = "Munizioni in riserva: %d/%d (al massimo)" % [reserve, cap]
				ammo_btn.disabled = true
			else:
				ammo_info.text = "Munizioni in riserva: %d/%d\nCompra %d colpi per %d€" % [reserve, cap, pack_amt, pack_cost]
				ammo_btn.disabled = CheckpointData.money < pack_cost
			ammo_btn.text = "Compra munizioni"

		var expanded: bool = _expanded_weapons.get(wid, false)
		if not expanded:
			main_info.text = main_info.text.split("\n")[0]
		base.get_node("AmmoRow").visible = expanded

		for tid in Firearms.UPGRADE_TRACK_ORDER:
			var track_row := base.get_node("Track_%s" % tid)
			track_row.visible = expanded
			base.get_node("UpSep_%s" % tid).visible = expanded
			var t_info: Label = track_row.get_node("InfoLabel")
			var t_btn: Button = track_row.get_node("BuyButton")
			var level: int = fups.get(tid, 0)
			var tdef: Dictionary = Firearms.UPGRADE_TRACKS[tid]
			if not owned:
				t_info.text = "%s (si sblocca comprando l'arma)" % tdef.label
				t_btn.disabled = true
				t_btn.text = "Potenzia"
			elif Firearms.upgrade_is_maxed(level):
				var maxed_value := _firearm_track_value_text(tid, wid, fups)
				t_info.text = "%s — LIVELLO MASSIMO (%d/%d)\n%s" % [tdef.label, level, Firearms.UPGRADE_MAX_LEVEL, maxed_value]
				t_btn.disabled = true
				t_btn.text = "Massimo"
			else:
				var next_fups := fups.duplicate()
				next_fups[tid] = level + 1
				var preview := _firearm_track_preview_text(tid, wid, fups, next_fups)
				var cm := Firearms.upgrade_cost_money(wid, level)
				var cmat := Firearms.upgrade_cost_material(wid, level)
				var mat_name2: String = MATERIAL_LABELS.get(tdef.material, tdef.material)
				t_info.text = "%s (Lv %d/%d) — %s\n%s\ncosta %d€ + %d %s" % [tdef.label, level, Firearms.UPGRADE_MAX_LEVEL, tdef.desc, preview, cm, cmat, mat_name2]
				var afford2: bool = CheckpointData.money >= cm and CheckpointData.materials.get(tdef.material, 0) >= cmat
				t_btn.disabled = not afford2
				t_btn.text = "Potenzia"

func _open_explosive_menu() -> void:
	explosive_menu.visible = true
	touch_controls.input_enabled = false
	_refresh_explosive_menu()

func _close_explosive_menu() -> void:
	explosive_menu.visible = false
	touch_controls.input_enabled = true

const DEFAULT_DOOR_COLOR := Color(0.08, 0.07, 0.06, 1)
const DEFAULT_ROOF_COLOR := Color(0.4, 0.3, 0.25, 1)
const DEFAULT_BODY_COLOR := Color(0.2, 0.45, 0.95, 1)

func _open_wardrobe_menu() -> void:
	wardrobe_menu.visible = true
	touch_controls.input_enabled = false
	var tier: Dictionary = HouseTiers.tier_data(CheckpointData.house_tier)
	body_color_button.self_modulate = Color(CheckpointData.player_body_color) if CheckpointData.player_body_color != "" else DEFAULT_BODY_COLOR
	wall_color_button.self_modulate = Color(CheckpointData.house_wall_color) if CheckpointData.house_wall_color != "" else Color(tier.wall_color)
	roof_color_button.self_modulate = Color(CheckpointData.house_roof_color) if CheckpointData.house_roof_color != "" else Color(tier.get("roof_color", DEFAULT_ROOF_COLOR))
	door_color_button.self_modulate = Color(CheckpointData.house_door_color) if CheckpointData.house_door_color != "" else DEFAULT_DOOR_COLOR

func _close_wardrobe_menu() -> void:
	wardrobe_menu.visible = false
	touch_controls.input_enabled = true

func _open_color_pick(target: String, title: String) -> void:
	_color_pick_target = target
	color_pick_title.text = title
	var button: Button = body_color_button
	if target == "wall":
		button = wall_color_button
	elif target == "roof":
		button = roof_color_button
	elif target == "door":
		button = door_color_button
	color_picker_widget.color = button.self_modulate
	wardrobe_menu.visible = false
	color_pick_screen.visible = true

func _on_color_pick_confirmed() -> void:
	var color := color_picker_widget.color
	if _color_pick_target == "body":
		body_color_button.self_modulate = color
		_on_body_color_changed(color)
	elif _color_pick_target == "wall":
		wall_color_button.self_modulate = color
		_on_wall_color_changed(color)
	elif _color_pick_target == "roof":
		roof_color_button.self_modulate = color
		_on_roof_color_changed(color)
	elif _color_pick_target == "door":
		door_color_button.self_modulate = color
		_on_door_color_changed(color)
	_color_pick_target = ""
	color_pick_screen.visible = false
	wardrobe_menu.visible = true

func _on_body_color_changed(color: Color) -> void:
	CheckpointData.player_body_color = color.to_html(false)
	player.apply_body_color(color)

func _on_wall_color_changed(color: Color) -> void:
	CheckpointData.house_wall_color = color.to_html(false)

func _on_roof_color_changed(color: Color) -> void:
	CheckpointData.house_roof_color = color.to_html(false)

func _on_door_color_changed(color: Color) -> void:
	CheckpointData.house_door_color = color.to_html(false)

func _show_explosive_category(cat_id: String) -> void:
	current_explosive_category = cat_id
	for cid in EXPLOSIVE_CATEGORY_BOXES.keys():
		get_node("HUD/ExplosiveMenu/Scroll/Box/%s" % EXPLOSIVE_CATEGORY_BOXES[cid]).visible = (cid == cat_id)
	if explosive_menu.visible:
		_refresh_explosive_menu()

func _refresh_explosive_menu() -> void:
	# Stesso slot/dati delle armi da fuoco: riuso le formule e i campi di
	# Firearms.gd e CheckpointData.owned_firearms/equipped_firearm/ecc.,
	# solo mostrati in un banco e un menu fisicamente separati.
	explosive_money_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for wid in Firearms.CATEGORY_WEAPONS[current_explosive_category]:
		var base := get_node("HUD/ExplosiveMenu/Scroll/Box/%s/Weapon_%s" % [EXPLOSIVE_CATEGORY_BOXES[current_explosive_category], wid])
		var main_info: Label = base.get_node("MainRow/InfoLabel")
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		var ammo_info: Label = base.get_node("AmmoRow/InfoLabel")
		var ammo_btn: Button = base.get_node("AmmoRow/BuyButton")
		var def: Dictionary = Firearms.WEAPONS[wid]
		var owned: bool = CheckpointData.owned_firearms.get(wid, false)
		var equipped: bool = CheckpointData.equipped_firearm == wid
		var fups: Dictionary = CheckpointData.firearm_upgrades.get(wid, {})
		var mode_label: String = _firearm_mode_label(def)

		if not owned:
			var mat_name: String = MATERIAL_LABELS.get(def.price_material, def.price_material)
			main_info.text = "%s — %s\nDanno %d · Cadenza %.2fs · Caricatore %d · Portata %d\nCosta %d€ + %d %s" % [
				def.label, mode_label, int(def.damage), def.fire_cooldown, int(def.magazine_size), int(def.range),
				def.price_money, def.price_amount, mat_name,
			]
			var afford: bool = CheckpointData.money >= def.price_money and CheckpointData.materials.get(def.price_material, 0) >= def.price_amount
			action_btn.disabled = not afford
			action_btn.text = "Compra"
			ammo_info.text = "Munizioni: si sbloccano comprando l'arma"
			ammo_btn.disabled = true
			ammo_btn.text = "Compra munizioni"
		else:
			var stats_line := "Danno %d · Cadenza %.2fs · Portata %d · Estrazione %.2fs" % [
				int(Firearms.final_damage(wid, fups)), Firearms.final_cooldown(wid, fups),
				int(Firearms.final_range(wid, fups)), Firearms.final_draw_time(wid, fups),
			]
			if equipped:
				main_info.text = "%s — Equipaggiata (%s)\n%s" % [def.label, mode_label, stats_line]
				action_btn.disabled = true
				action_btn.text = "Equipaggiata"
				action_btn.modulate = EQUIPPED_BUTTON_MODULATE
			else:
				main_info.text = "%s — posseduta (%s)\n%s" % [def.label, mode_label, stats_line]
				action_btn.disabled = false
				action_btn.text = "Equipaggia"
				action_btn.modulate = OWNED_BUTTON_MODULATE

			var reserve: int = int(CheckpointData.firearm_ammo.get(wid, 0))
			var cap: int = Firearms.final_reserve_cap(wid, fups)
			var pack_amt: int = int(def.ammo_pack_amount)
			var pack_cost: int = int(def.ammo_pack_price_money)
			if reserve >= cap:
				ammo_info.text = "Munizioni in riserva: %d/%d (al massimo)" % [reserve, cap]
				ammo_btn.disabled = true
			else:
				ammo_info.text = "Munizioni in riserva: %d/%d\nCompra %d colpi per %d€" % [reserve, cap, pack_amt, pack_cost]
				ammo_btn.disabled = CheckpointData.money < pack_cost
			ammo_btn.text = "Compra munizioni"

		var expanded: bool = _expanded_weapons.get(wid, false)
		if not expanded:
			main_info.text = main_info.text.split("\n")[0]
		base.get_node("AmmoRow").visible = expanded

		for tid in Firearms.UPGRADE_TRACK_ORDER:
			var track_row := base.get_node("Track_%s" % tid)
			track_row.visible = expanded
			base.get_node("UpSep_%s" % tid).visible = expanded
			var t_info: Label = track_row.get_node("InfoLabel")
			var t_btn: Button = track_row.get_node("BuyButton")
			var level: int = fups.get(tid, 0)
			var tdef: Dictionary = Firearms.UPGRADE_TRACKS[tid]
			if not owned:
				t_info.text = "%s (si sblocca comprando l'arma)" % tdef.label
				t_btn.disabled = true
				t_btn.text = "Potenzia"
			elif Firearms.upgrade_is_maxed(level):
				var maxed_value := _firearm_track_value_text(tid, wid, fups)
				t_info.text = "%s — LIVELLO MASSIMO (%d/%d)\n%s" % [tdef.label, level, Firearms.UPGRADE_MAX_LEVEL, maxed_value]
				t_btn.disabled = true
				t_btn.text = "Massimo"
			else:
				var next_fups := fups.duplicate()
				next_fups[tid] = level + 1
				var preview := _firearm_track_preview_text(tid, wid, fups, next_fups)
				var cm := Firearms.upgrade_cost_money(wid, level)
				var cmat := Firearms.upgrade_cost_material(wid, level)
				var mat_name2: String = MATERIAL_LABELS.get(tdef.material, tdef.material)
				t_info.text = "%s (Lv %d/%d) — %s\n%s\ncosta %d€ + %d %s" % [tdef.label, level, Firearms.UPGRADE_MAX_LEVEL, tdef.desc, preview, cm, cmat, mat_name2]
				var afford2: bool = CheckpointData.money >= cm and CheckpointData.materials.get(tdef.material, 0) >= cmat
				t_btn.disabled = not afford2
				t_btn.text = "Potenzia"

func _firearm_mode_label(def: Dictionary) -> String:
	var style: String = String(def.get("fire_style", ""))
	match String(def.fire_mode):
		"burst":
			return "%s (al rilascio della mira)" % style
		"single":
			return "%s (al rilascio della mira)" % style
		_:
			return style

func _firearm_track_value_text(tid: String, wid: String, fups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata attuale: %d" % int(Firearms.final_range(wid, fups))
		"velocita":
			return "Cadenza attuale: %.2fs" % Firearms.final_cooldown(wid, fups)
		"danno":
			return "Danno attuale: %d" % int(Firearms.final_damage(wid, fups))
		"estrazione":
			return "Estrazione attuale: %.2fs" % Firearms.final_draw_time(wid, fups)
		"mirino":
			return "Linea di mira attuale: %.1fm" % Firearms.final_aim_line_length(wid, fups)
		"caricatore":
			return "Scorta massima attuale: %d" % Firearms.final_reserve_cap(wid, fups)
	return ""

func _firearm_track_preview_text(tid: String, wid: String, fups: Dictionary, next_fups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata: %d → %d" % [int(Firearms.final_range(wid, fups)), int(Firearms.final_range(wid, next_fups))]
		"velocita":
			return "Cadenza: %.2fs → %.2fs" % [Firearms.final_cooldown(wid, fups), Firearms.final_cooldown(wid, next_fups)]
		"danno":
			return "Danno: %d → %d" % [int(Firearms.final_damage(wid, fups)), int(Firearms.final_damage(wid, next_fups))]
		"estrazione":
			return "Estrazione: %.2fs → %.2fs" % [Firearms.final_draw_time(wid, fups), Firearms.final_draw_time(wid, next_fups)]
		"mirino":
			return "Mirino: %.1fm → %.1fm" % [Firearms.final_aim_line_length(wid, fups), Firearms.final_aim_line_length(wid, next_fups)]
		"caricatore":
			return "Scorta massima: %d → %d" % [Firearms.final_reserve_cap(wid, fups), Firearms.final_reserve_cap(wid, next_fups)]
	return ""

func _refresh_firearm_or_explosive_menu() -> void:
	if explosive_menu.visible:
		_refresh_explosive_menu()
	else:
		_refresh_firearm_menu()

func _on_firearm_action_pressed(wid: String) -> void:
	var owned: bool = CheckpointData.owned_firearms.get(wid, false)
	if not owned:
		var def: Dictionary = Firearms.WEAPONS[wid]
		if CheckpointData.money < def.price_money or CheckpointData.materials.get(def.price_material, 0) < def.price_amount:
			return
		CheckpointData.money -= int(def.price_money)
		CheckpointData.materials[def.price_material] = CheckpointData.materials.get(def.price_material, 0) - int(def.price_amount)
		CheckpointData.owned_firearms[wid] = true
		CheckpointData.firearm_upgrades[wid] = {}
		CheckpointData.firearm_ammo[wid] = int(def.magazine_size)
		CheckpointData.equipped_firearm = wid
	else:
		CheckpointData.equipped_firearm = wid
	_refresh_firearm_or_explosive_menu()

func _on_buy_ammo_pressed(wid: String) -> void:
	var def: Dictionary = Firearms.WEAPONS[wid]
	var fups: Dictionary = CheckpointData.firearm_upgrades.get(wid, {})
	var cap := Firearms.final_reserve_cap(wid, fups)
	var current: int = int(CheckpointData.firearm_ammo.get(wid, 0))
	if current >= cap:
		return
	var cost: int = int(def.ammo_pack_price_money)
	if CheckpointData.money < cost:
		return
	CheckpointData.money -= cost
	CheckpointData.firearm_ammo[wid] = min(cap, current + int(def.ammo_pack_amount))
	_refresh_firearm_or_explosive_menu()

func _on_upgrade_firearm_pressed(wid: String, tid: String) -> void:
	var fups: Dictionary = CheckpointData.firearm_upgrades.get(wid, {})
	var level: int = fups.get(tid, 0)
	if Firearms.upgrade_is_maxed(level):
		return
	var cm := Firearms.upgrade_cost_money(wid, level)
	var cmat := Firearms.upgrade_cost_material(wid, level)
	var mat: String = Firearms.UPGRADE_TRACKS[tid].material
	if CheckpointData.money < cm or CheckpointData.materials.get(mat, 0) < cmat:
		return
	CheckpointData.money -= cm
	CheckpointData.materials[mat] = CheckpointData.materials.get(mat, 0) - cmat
	fups[tid] = level + 1
	CheckpointData.firearm_upgrades[wid] = fups
	_refresh_firearm_or_explosive_menu()

func _open_throwable_menu() -> void:
	throwable_menu.visible = true
	touch_controls.input_enabled = false
	_refresh_throwable_menu()

func _close_throwable_menu() -> void:
	throwable_menu.visible = false
	touch_controls.input_enabled = true

func _show_throwable_category(cat_id: String) -> void:
	current_throwable_category = cat_id
	for cid in THROWABLE_CATEGORY_BOXES.keys():
		get_node("HUD/ThrowableMenu/Scroll/Box/%s" % THROWABLE_CATEGORY_BOXES[cid]).visible = (cid == cat_id)
	if throwable_menu.visible:
		_refresh_throwable_menu()

func _refresh_throwable_menu() -> void:
	throwable_money_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for wid in Throwables.CATEGORY_WEAPONS[current_throwable_category]:
		var base := get_node("HUD/ThrowableMenu/Scroll/Box/%s/Weapon_%s" % [THROWABLE_CATEGORY_BOXES[current_throwable_category], wid])
		var main_info: Label = base.get_node("MainRow/InfoLabel")
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		var ammo_info: Label = base.get_node("AmmoRow/InfoLabel")
		var ammo_btn: Button = base.get_node("AmmoRow/BuyButton")
		var def: Dictionary = Throwables.WEAPONS[wid]
		var owned: bool = CheckpointData.owned_throwables.get(wid, false)
		var equipped: bool = CheckpointData.equipped_throwables.get(String(def.category), "") == wid
		var tups: Dictionary = CheckpointData.throwable_upgrades.get(wid, {})

		if not owned:
			var mat_name: String = MATERIAL_LABELS.get(def.price_material, def.price_material)
			main_info.text = "%s\nDanno %d · Cadenza %.2fs · Portata %d\nCosta %d€ + %d %s" % [
				def.label, int(def.damage), def.throw_cooldown, int(def.range), def.price_money, def.price_amount, mat_name,
			]
			var afford: bool = CheckpointData.money >= def.price_money and CheckpointData.materials.get(def.price_material, 0) >= def.price_amount
			action_btn.disabled = not afford
			action_btn.text = "Compra"
			ammo_info.text = "Scorta: si sblocca comprando l'arma"
			ammo_btn.disabled = true
			ammo_btn.text = "Compra scorta"
		else:
			var stats_line := "Danno %d · Cadenza %.2fs · Portata %d · Estrazione %.2fs" % [
				int(Throwables.final_damage(wid, tups)), Throwables.final_cooldown(wid, tups),
				int(Throwables.final_range(wid, tups)), Throwables.final_draw_time(wid, tups),
			]
			if equipped:
				main_info.text = "%s — Equipaggiata (tocca di nuovo per togliere)\n%s" % [def.label, stats_line]
				action_btn.disabled = false
				action_btn.text = "Disequipaggia"
				action_btn.modulate = EQUIPPED_BUTTON_MODULATE
			else:
				var other_equipped: String = String(CheckpointData.equipped_throwables.get(String(def.category), ""))
				if other_equipped != "":
					var other_label: String = String(Throwables.WEAPONS[other_equipped].label)
					main_info.text = "%s — posseduta (sostituirà %s)\n%s" % [def.label, other_label, stats_line]
				else:
					main_info.text = "%s — posseduta\n%s" % [def.label, stats_line]
				action_btn.disabled = false
				action_btn.text = "Equipaggia"
				action_btn.modulate = OWNED_BUTTON_MODULATE

			var reserve: int = int(CheckpointData.throwable_ammo.get(wid, 0))
			var cap: int = Throwables.final_reserve_cap(wid, tups)
			var pack_cost: int = int(def.ammo_pack_price_money)
			if reserve >= cap:
				ammo_info.text = "Scorta: %d/%d (al massimo)" % [reserve, cap]
				ammo_btn.disabled = true
			else:
				ammo_info.text = "Scorta: %d/%d\nCompra 1 unità per %d€" % [reserve, cap, pack_cost]
				ammo_btn.disabled = CheckpointData.money < pack_cost
			ammo_btn.text = "Compra scorta"

		var expanded: bool = _expanded_weapons.get(wid, false)
		if not expanded:
			main_info.text = main_info.text.split("\n")[0]
		base.get_node("AmmoRow").visible = expanded

		for tid in Throwables.UPGRADE_TRACK_ORDER:
			var track_row := base.get_node("Track_%s" % tid)
			track_row.visible = expanded
			base.get_node("UpSep_%s" % tid).visible = expanded
			var t_info: Label = track_row.get_node("InfoLabel")
			var t_btn: Button = track_row.get_node("BuyButton")
			var level: int = tups.get(tid, 0)
			var tdef: Dictionary = Throwables.UPGRADE_TRACKS[tid]
			if not owned:
				t_info.text = "%s (si sblocca comprando l'arma)" % tdef.label
				t_btn.disabled = true
				t_btn.text = "Potenzia"
			elif Throwables.upgrade_is_maxed(level):
				var maxed_value := _throwable_track_value_text(tid, wid, tups)
				t_info.text = "%s — LIVELLO MASSIMO (%d/%d)\n%s" % [tdef.label, level, Throwables.UPGRADE_MAX_LEVEL, maxed_value]
				t_btn.disabled = true
				t_btn.text = "Massimo"
			else:
				var next_tups := tups.duplicate()
				next_tups[tid] = level + 1
				var preview := _throwable_track_preview_text(tid, wid, tups, next_tups)
				var cm := Throwables.upgrade_cost_money(wid, level)
				var cmat := Throwables.upgrade_cost_material(wid, level)
				var mat_name2: String = MATERIAL_LABELS.get(tdef.material, tdef.material)
				t_info.text = "%s (Lv %d/%d) — %s\n%s\ncosta %d€ + %d %s" % [tdef.label, level, Throwables.UPGRADE_MAX_LEVEL, tdef.desc, preview, cm, cmat, mat_name2]
				var afford2: bool = CheckpointData.money >= cm and CheckpointData.materials.get(tdef.material, 0) >= cmat
				t_btn.disabled = not afford2
				t_btn.text = "Potenzia"

func _throwable_track_value_text(tid: String, wid: String, tups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata attuale: %d" % int(Throwables.final_range(wid, tups))
		"velocita":
			return "Cadenza attuale: %.2fs" % Throwables.final_cooldown(wid, tups)
		"danno":
			return "Danno attuale: %d" % int(Throwables.final_damage(wid, tups))
		"estrazione":
			return "Estrazione attuale: %.2fs" % Throwables.final_draw_time(wid, tups)
		"mira":
			return "Linea di mira attuale: %.1fm" % Throwables.final_aim_line_length(wid, tups)
		"scorta":
			return "Scorta massima attuale: %d" % Throwables.final_reserve_cap(wid, tups)
	return ""

func _throwable_track_preview_text(tid: String, wid: String, tups: Dictionary, next_tups: Dictionary) -> String:
	match tid:
		"portata":
			return "Portata: %d → %d" % [int(Throwables.final_range(wid, tups)), int(Throwables.final_range(wid, next_tups))]
		"velocita":
			return "Cadenza: %.2fs → %.2fs" % [Throwables.final_cooldown(wid, tups), Throwables.final_cooldown(wid, next_tups)]
		"danno":
			return "Danno: %d → %d" % [int(Throwables.final_damage(wid, tups)), int(Throwables.final_damage(wid, next_tups))]
		"mira":
			return "Mira: %.1fm → %.1fm" % [Throwables.final_aim_line_length(wid, tups), Throwables.final_aim_line_length(wid, next_tups)]
		"estrazione":
			return "Estrazione: %.2fs → %.2fs" % [Throwables.final_draw_time(wid, tups), Throwables.final_draw_time(wid, next_tups)]
		"scorta":
			return "Scorta massima: %d → %d" % [Throwables.final_reserve_cap(wid, tups), Throwables.final_reserve_cap(wid, next_tups)]
	return ""

func _on_throwable_action_pressed(wid: String) -> void:
	var owned: bool = CheckpointData.owned_throwables.get(wid, false)
	var cat: String = String(Throwables.WEAPONS[wid].category)
	if not owned:
		var def: Dictionary = Throwables.WEAPONS[wid]
		if CheckpointData.money < def.price_money or CheckpointData.materials.get(def.price_material, 0) < def.price_amount:
			return
		CheckpointData.money -= int(def.price_money)
		CheckpointData.materials[def.price_material] = CheckpointData.materials.get(def.price_material, 0) - int(def.price_amount)
		CheckpointData.owned_throwables[wid] = true
		CheckpointData.throwable_upgrades[wid] = {}
		# Equipaggiata subito, anche se sostituisce quella già scelta per
		# la stessa categoria: così il player non entra in zona disarmato.
		CheckpointData.equipped_throwables[cat] = wid
		CheckpointData.equipped_throwable = wid
	else:
		if CheckpointData.equipped_throwables.get(cat, "") == wid:
			# Un secondo tocco sulla stessa arma la toglie dal loadout di questa categoria.
			CheckpointData.equipped_throwables[cat] = ""
			if CheckpointData.equipped_throwable == wid:
				CheckpointData.equipped_throwable = ""
		else:
			# Al massimo un'arma equipaggiata per categoria: questa sostituisce
			# quella eventualmente già scelta per la stessa categoria.
			CheckpointData.equipped_throwables[cat] = wid
			CheckpointData.equipped_throwable = wid
	_refresh_throwable_menu()

func _on_buy_throwable_ammo_pressed(wid: String) -> void:
	var def: Dictionary = Throwables.WEAPONS[wid]
	var tups: Dictionary = CheckpointData.throwable_upgrades.get(wid, {})
	var cap := Throwables.final_reserve_cap(wid, tups)
	var current: int = int(CheckpointData.throwable_ammo.get(wid, 0))
	if current >= cap:
		return
	var cost: int = int(def.ammo_pack_price_money)
	if CheckpointData.money < cost:
		return
	CheckpointData.money -= cost
	CheckpointData.throwable_ammo[wid] = current + 1
	_refresh_throwable_menu()

func _on_upgrade_throwable_pressed(wid: String, tid: String) -> void:
	var tups: Dictionary = CheckpointData.throwable_upgrades.get(wid, {})
	var level: int = tups.get(tid, 0)
	if Throwables.upgrade_is_maxed(level):
		return
	var cm := Throwables.upgrade_cost_money(wid, level)
	var cmat := Throwables.upgrade_cost_material(wid, level)
	var mat: String = Throwables.UPGRADE_TRACKS[tid].material
	if CheckpointData.money < cm or CheckpointData.materials.get(mat, 0) < cmat:
		return
	CheckpointData.money -= cm
	CheckpointData.materials[mat] = CheckpointData.materials.get(mat, 0) - cmat
	tups[tid] = level + 1
	CheckpointData.throwable_upgrades[wid] = tups
	_refresh_throwable_menu()

func _on_door_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
