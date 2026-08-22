extends Node3D

const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")

const WORKBENCH_POS := Vector3(1.3, 0.0, -2.2)
const INTERACT_RANGE := 2.2
const MATERIAL_LABELS := {"legno": "Legno", "metallo": "Metallo", "cablaggi": "Cablaggi"}

const ROOM_ROWS := [-2.0, 0.0, 2.0]
const FIXED_BENCH_ROW := -2.0

const BENCH_SCENES := {
	"armi_bianche": preload("res://scenes/WorkbenchArmiBianche.tscn"),
}
const BENCH_COSTS := {
	"armi_bianche": {"money": 250, "material": "metallo", "amount": 20},
}
const BENCH_LABELS := {
	"armi_bianche": "Banco delle armi bianche",
}

@onready var player: Node3D = $Player
@onready var interact_button: Button = $HUD/InteractButton
@onready var workbench_menu: Control = $HUD/WorkbenchMenu
@onready var money_materials_label: Label = $HUD/WorkbenchMenu/Scroll/Box/MoneyMaterialsLabel
@onready var upgrades_tab: Control = $HUD/WorkbenchMenu/Scroll/Box/UpgradesTab
@onready var benches_tab: Control = $HUD/WorkbenchMenu/Scroll/Box/BenchesTab
@onready var weapon_menu: Control = $HUD/WeaponMenu
@onready var weapon_money_label: Label = $HUD/WeaponMenu/Scroll/Box/MoneyMaterialsLabel
@onready var placement_ui: Control = $HUD/PlacementUI
@onready var placement_highlight: MeshInstance3D = $PlacementHighlight
@onready var bench_ghost_holder: Node3D = $BenchGhostHolder
@onready var placed_benches_root: Node3D = $PlacedBenches
@onready var touch_controls = $HUD/TouchControls

var placing_bench_type := ""
var placing_ghost: Node3D = null
var placing_row := 0.0
var placing_valid := false

var _current_interact := ""
var _placed_bench_nodes := {}

func _ready() -> void:
	interact_button.visible = false
	workbench_menu.visible = false
	weapon_menu.visible = false
	placement_ui.visible = false
	placement_highlight.visible = false

	interact_button.pressed.connect(_on_interact_pressed)
	$HUD/WorkbenchMenu/Scroll/Box/CloseButton.pressed.connect(_close_house_menu)
	$HUD/WorkbenchMenu/Scroll/Box/TabsRow/UpgradesTabButton.pressed.connect(_show_upgrades_tab)
	$HUD/WorkbenchMenu/Scroll/Box/TabsRow/BenchesTabButton.pressed.connect(_show_benches_tab)
	$HUD/WeaponMenu/Scroll/Box/CloseButton.pressed.connect(_close_weapon_menu)
	$HUD/PlacementUI/ButtonRow/ConfirmButton.pressed.connect(_on_confirm_placement_pressed)
	$HUD/PlacementUI/ButtonRow/CancelButton.pressed.connect(_on_cancel_placement_pressed)

	for id in PlayerUpgrades.ORDER:
		var btn: Button = get_node("HUD/WorkbenchMenu/Scroll/Box/UpgradesTab/Row_%s/BuyButton" % id)
		btn.pressed.connect(_on_buy_upgrade_pressed.bind(id))

	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_bianche/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_bianche"))

	for wid in MeleeWeapons.CATEGORY_WEAPONS["coltelli"]:
		var base := get_node("HUD/WeaponMenu/Scroll/Box/KnivesBox/Weapon_%s" % wid)
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		action_btn.pressed.connect(_on_weapon_action_pressed.bind(wid))
		for tid in MeleeWeapons.UPGRADE_TRACK_ORDER:
			var t_btn: Button = base.get_node("Track_%s/BuyButton" % tid)
			t_btn.pressed.connect(_on_upgrade_weapon_pressed.bind(wid, tid))

	$DoorTrigger.body_entered.connect(_on_door_entered)

	for b in CheckpointData.placed_benches:
		_instantiate_placed_bench(String(b.get("type", "")), float(b.get("row", 0.0)))

	_show_upgrades_tab()
	_refresh_workbench_menu()

func _process(_delta: float) -> void:
	if placing_bench_type != "" or workbench_menu.visible or weapon_menu.visible:
		interact_button.visible = false
		return

	var best_id := ""
	var best_dist := INTERACT_RANGE
	var d_casa := player.global_position.distance_to(WORKBENCH_POS)
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
	interact_button.visible = best_id != ""
	if best_id == "casa":
		interact_button.text = "Usa il banco della casa"
	elif best_id != "":
		interact_button.text = "Usa %s" % BENCH_LABELS.get(best_id, best_id)

func _on_interact_pressed() -> void:
	if _current_interact == "casa":
		_open_house_menu()
	elif _current_interact != "":
		_open_weapon_menu()

func _open_house_menu() -> void:
	workbench_menu.visible = true
	interact_button.visible = false
	_refresh_workbench_menu()

func _close_house_menu() -> void:
	workbench_menu.visible = false

func _show_upgrades_tab() -> void:
	upgrades_tab.visible = true
	benches_tab.visible = false

func _show_benches_tab() -> void:
	upgrades_tab.visible = false
	benches_tab.visible = true
	_refresh_benches_tab()

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
			info.text = "%s — LIVELLO MASSIMO (%d/%d)" % [def.label, level, def.max_level]
			btn.disabled = true
			btn.text = "Massimo"
		else:
			var cm := PlayerUpgrades.cost_money(id, level)
			var cmat := PlayerUpgrades.cost_material(id, level)
			var mat_name: String = MATERIAL_LABELS.get(def.material, def.material)
			info.text = "%s (Lv %d/%d)\n%s — costa %d€ + %d %s" % [def.label, level, def.max_level, def.desc, cm, cmat, mat_name]
			var can_afford: bool = CheckpointData.money >= cm and CheckpointData.materials.get(def.material, 0) >= cmat
			btn.disabled = not can_afford
			btn.text = "Compra"
	if benches_tab.visible:
		_refresh_benches_tab()

func _refresh_benches_tab() -> void:
	money_materials_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	var row := $HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_bianche
	var info: Label = row.get_node("InfoLabel")
	var btn: Button = row.get_node("BuyButton")
	if _has_placed_bench("armi_bianche"):
		info.text = "Banco delle armi bianche — posizionato in casa"
		btn.disabled = true
		btn.text = "Posizionato"
	else:
		var cost: Dictionary = BENCH_COSTS["armi_bianche"]
		var mat_name: String = MATERIAL_LABELS.get(cost.material, cost.material)
		info.text = "Banco delle armi bianche\nSblocca coltelli, spade, mazze, martelli e lance — costa %d€ + %d %s" % [cost.money, cost.amount, mat_name]
		var afford: bool = CheckpointData.money >= cost.money and CheckpointData.materials.get(cost.material, 0) >= cost.amount
		btn.disabled = not afford
		btn.text = "Compra"

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
	interact_button.visible = false
	touch_controls.input_enabled = false
	touch_controls.move_vector = Vector2.ZERO
	touch_controls.attack_held = false

	placing_ghost = BENCH_SCENES[type_id].instantiate()
	bench_ghost_holder.add_child(placing_ghost)
	placing_row = _first_free_row()
	placing_ghost.position = Vector3(0, 0, placing_row)
	placement_highlight.visible = true
	placement_ui.visible = true
	_update_placement_validity()

func _first_free_row() -> float:
	var occ := _occupied_rows()
	for r in ROOM_ROWS:
		if not occ.has(r):
			return r
	return ROOM_ROWS[0]

func _occupied_rows() -> Dictionary:
	var occ := {FIXED_BENCH_ROW: true}
	for b in CheckpointData.placed_benches:
		occ[float(b.get("row", 0.0))] = true
	return occ

func _update_placement_validity() -> void:
	placing_valid = not _occupied_rows().has(placing_row)
	placement_highlight.position = Vector3(0, 0.02, placing_row)
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
	var t: float = -origin.y / normal.y
	if t < 0.0:
		return
	var world_point := origin + normal * t
	var nearest_row: float = ROOM_ROWS[0]
	var best_dist := INF
	for r in ROOM_ROWS:
		var d: float = absf(world_point.z - float(r))
		if d < best_dist:
			best_dist = d
			nearest_row = r
	placing_row = nearest_row
	placing_ghost.position = Vector3(0, 0, placing_row)
	_update_placement_validity()

func _on_confirm_placement_pressed() -> void:
	if not placing_valid:
		return
	var type_id := placing_bench_type
	var cost: Dictionary = BENCH_COSTS[type_id]
	CheckpointData.money -= int(cost.money)
	CheckpointData.materials[cost.material] = CheckpointData.materials.get(cost.material, 0) - int(cost.amount)
	CheckpointData.placed_benches.append({"type": type_id, "row": placing_row})
	_instantiate_placed_bench(type_id, placing_row)
	_end_placement()

func _on_cancel_placement_pressed() -> void:
	_end_placement()

func _end_placement() -> void:
	placing_bench_type = ""
	if placing_ghost != null:
		placing_ghost.queue_free()
		placing_ghost = null
	placement_ui.visible = false
	placement_highlight.visible = false
	touch_controls.input_enabled = true
	_refresh_workbench_menu()

func _instantiate_placed_bench(type_id: String, row: float) -> void:
	if not BENCH_SCENES.has(type_id):
		return
	var node: Node3D = BENCH_SCENES[type_id].instantiate()
	node.position = Vector3(0, 0, row)
	placed_benches_root.add_child(node)
	_placed_bench_nodes[type_id] = node

func _open_weapon_menu() -> void:
	weapon_menu.visible = true
	interact_button.visible = false
	_refresh_weapon_menu()

func _close_weapon_menu() -> void:
	weapon_menu.visible = false

func _refresh_weapon_menu() -> void:
	weapon_money_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for wid in MeleeWeapons.CATEGORY_WEAPONS["coltelli"]:
		var base := get_node("HUD/WeaponMenu/Scroll/Box/KnivesBox/Weapon_%s" % wid)
		var main_info: Label = base.get_node("MainRow/InfoLabel")
		var action_btn: Button = base.get_node("MainRow/ActionButton")
		var def: Dictionary = MeleeWeapons.WEAPONS[wid]
		var owned: bool = CheckpointData.owned_weapons.get(wid, false)
		var equipped: bool = CheckpointData.equipped_weapon == wid

		if not owned:
			var mat_name: String = MATERIAL_LABELS.get(def.price_material, def.price_material)
			main_info.text = "%s\nDanno %d · Cooldown %.2fs · Portata x%.2f\nCosta %d€ + %d %s" % [
				def.label, int(def.damage), def.cooldown, def.reach_mult, def.price_money, def.price_amount, mat_name,
			]
			var afford: bool = CheckpointData.money >= def.price_money and CheckpointData.materials.get(def.price_material, 0) >= def.price_amount
			action_btn.disabled = not afford
			action_btn.text = "Compra"
		elif equipped:
			main_info.text = "%s — Equipaggiata" % def.label
			action_btn.disabled = true
			action_btn.text = "Equipaggiata"
		else:
			main_info.text = "%s — posseduta" % def.label
			action_btn.disabled = false
			action_btn.text = "Equipaggia"

		var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})
		for tid in MeleeWeapons.UPGRADE_TRACK_ORDER:
			var track_row := base.get_node("Track_%s" % tid)
			var t_info: Label = track_row.get_node("InfoLabel")
			var t_btn: Button = track_row.get_node("BuyButton")
			var level: int = wups.get(tid, 0)
			var tdef: Dictionary = MeleeWeapons.UPGRADE_TRACKS[tid]
			if not owned:
				t_info.text = "%s (si sblocca comprando l'arma)" % tdef.label
				t_btn.disabled = true
				t_btn.text = "Potenzia"
			elif MeleeWeapons.upgrade_is_maxed(level):
				t_info.text = "%s — LIVELLO MASSIMO (%d/%d)" % [tdef.label, level, MeleeWeapons.UPGRADE_MAX_LEVEL]
				t_btn.disabled = true
				t_btn.text = "Massimo"
			else:
				var cm := MeleeWeapons.upgrade_cost_money(wid, level)
				var cmat := MeleeWeapons.upgrade_cost_material(wid, level)
				var mat_name2: String = MATERIAL_LABELS.get(tdef.material, tdef.material)
				t_info.text = "%s (Lv %d/%d) — %s\ncosta %d€ + %d %s" % [tdef.label, level, MeleeWeapons.UPGRADE_MAX_LEVEL, tdef.desc, cm, cmat, mat_name2]
				var afford2: bool = CheckpointData.money >= cm and CheckpointData.materials.get(tdef.material, 0) >= cmat
				t_btn.disabled = not afford2
				t_btn.text = "Potenzia"

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
	else:
		CheckpointData.equipped_weapon = wid
	_refresh_weapon_menu()

func _on_upgrade_weapon_pressed(wid: String, tid: String) -> void:
	var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})
	var level: int = wups.get(tid, 0)
	if MeleeWeapons.upgrade_is_maxed(level):
		return
	var cm := MeleeWeapons.upgrade_cost_money(wid, level)
	var cmat := MeleeWeapons.upgrade_cost_material(wid, level)
	var mat: String = MeleeWeapons.UPGRADE_TRACKS[tid].material
	if CheckpointData.money < cm or CheckpointData.materials.get(mat, 0) < cmat:
		return
	CheckpointData.money -= cm
	CheckpointData.materials[mat] = CheckpointData.materials.get(mat, 0) - cmat
	wups[tid] = level + 1
	CheckpointData.weapon_upgrades[wid] = wups
	_refresh_weapon_menu()

func _on_door_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
