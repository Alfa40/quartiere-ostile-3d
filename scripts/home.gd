extends Node3D

const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")
const UIScale := preload("res://scripts/ui_scale.gd")

const MENU_SCROLL_LEFT_PORTRAIT := 60.0
const MENU_SCROLL_RIGHT_PORTRAIT := -60.0
const MENU_SCROLL_LEFT_LANDSCAPE := 110.0
const MENU_SCROLL_RIGHT_LANDSCAPE := -10.0

const WORKBENCH_POS := Vector3(1.3, 0.0, -2.2)
const INTERACT_RANGE := 2.2
const MATERIAL_LABELS := {"legno": "Legno", "metallo": "Metallo", "cablaggi": "Cablaggi"}

const COL_VALUES := [-1.0, 1.0]
const ROW_VALUES := [-2.0, 0.0, 2.0]
const FIXED_BENCH_CELLS := ["0:0", "1:0"]

const CATEGORY_BOXES := {
	"coltelli": "KnivesBox",
	"spade": "SpadeBox",
	"mazze": "MazzeBox",
	"martelli": "MartelliBox",
	"lance": "LanceBox",
}

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
@onready var workbench_scroll: ScrollContainer = $HUD/WorkbenchMenu/Scroll
@onready var weapon_scroll: ScrollContainer = $HUD/WeaponMenu/Scroll
@onready var placement_ui: Control = $HUD/PlacementUI
@onready var placement_highlight: MeshInstance3D = $PlacementHighlight
@onready var bench_ghost_holder: Node3D = $BenchGhostHolder
@onready var placed_benches_root: Node3D = $PlacedBenches
@onready var touch_controls = $HUD/TouchControls

var placing_bench_type := ""
var placing_ghost: Node3D = null
var placing_orientation := "h"
var placing_col_idx := 0
var placing_row_idx := 0
var placing_valid := false

var current_weapon_category := "coltelli"
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
	$HUD/PlacementUI/ButtonRow/RotateButton.pressed.connect(_on_rotate_placement_pressed)

	for id in PlayerUpgrades.ORDER:
		var btn: Button = get_node("HUD/WorkbenchMenu/Scroll/Box/UpgradesTab/Row_%s/BuyButton" % id)
		btn.pressed.connect(_on_buy_upgrade_pressed.bind(id))

	$HUD/WorkbenchMenu/Scroll/Box/BenchesTab/Row_armi_bianche/BuyButton.pressed.connect(_on_buy_bench_pressed.bind("armi_bianche"))

	for cat_id in MeleeWeapons.CATEGORY_ORDER:
		var cat_btn: Button = get_node("HUD/WeaponMenu/Scroll/Box/CategoryRow/Btn_%s" % cat_id)
		cat_btn.pressed.connect(_show_weapon_category.bind(cat_id))
		for wid in MeleeWeapons.CATEGORY_WEAPONS[cat_id]:
			var base := get_node("HUD/WeaponMenu/Scroll/Box/%s/Weapon_%s" % [CATEGORY_BOXES[cat_id], wid])
			var action_btn: Button = base.get_node("MainRow/ActionButton")
			action_btn.pressed.connect(_on_weapon_action_pressed.bind(wid))
			for tid in MeleeWeapons.UPGRADE_TRACK_ORDER:
				var t_btn: Button = base.get_node("Track_%s/BuyButton" % tid)
				t_btn.pressed.connect(_on_upgrade_weapon_pressed.bind(wid, tid))

	$DoorTrigger.body_entered.connect(_on_door_entered)

	for b in CheckpointData.placed_benches:
		_instantiate_placed_bench(String(b.get("type", "")), String(b.get("orientation", "h")), int(b.get("col_idx", 0)), int(b.get("row_idx", 0)))

	_show_upgrades_tab()
	_show_weapon_category("coltelli")
	_refresh_workbench_menu()

	get_viewport().size_changed.connect(_update_menu_layout)
	_update_menu_layout()

func _update_menu_layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var is_landscape := vp.x > vp.y
	var is_portrait := not is_landscape

	UIScale.apply_orientation_scale(workbench_menu, is_portrait)
	UIScale.apply_orientation_scale(weapon_menu, is_portrait)
	UIScale.apply_orientation_scale(placement_ui, is_portrait)

	var left := MENU_SCROLL_LEFT_LANDSCAPE if is_landscape else MENU_SCROLL_LEFT_PORTRAIT
	var right := MENU_SCROLL_RIGHT_LANDSCAPE if is_landscape else MENU_SCROLL_RIGHT_PORTRAIT
	workbench_scroll.offset_left = left
	workbench_scroll.offset_right = right
	weapon_scroll.offset_left = left
	weapon_scroll.offset_right = right

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
	_update_placement_validity()

func _cell_key(col_idx: int, row_idx: int) -> String:
	return "%d:%d" % [col_idx, row_idx]

func _footprint_cells(orientation: String, col_idx: int, row_idx: int) -> Array:
	if orientation == "h":
		return [_cell_key(0, row_idx), _cell_key(1, row_idx)]
	return [_cell_key(col_idx, row_idx), _cell_key(col_idx, row_idx + 1)]

func _occupied_cells() -> Dictionary:
	var occ := {}
	for key in FIXED_BENCH_CELLS:
		occ[key] = true
	for b in CheckpointData.placed_benches:
		var orientation: String = String(b.get("orientation", "h"))
		var col_idx: int = int(b.get("col_idx", 0))
		var row_idx: int = int(b.get("row_idx", 0))
		for key in _footprint_cells(orientation, col_idx, row_idx):
			occ[key] = true
	return occ

func _first_free_slot(orientation: String):
	var occ := _occupied_cells()
	if orientation == "h":
		for r in range(ROW_VALUES.size()):
			var cells := _footprint_cells("h", 0, r)
			if not occ.has(cells[0]) and not occ.has(cells[1]):
				return {"row_idx": r, "col_idx": 0}
	else:
		for c in range(COL_VALUES.size()):
			for r in range(ROW_VALUES.size() - 1):
				var cells := _footprint_cells("v", c, r)
				if not occ.has(cells[0]) and not occ.has(cells[1]):
					return {"row_idx": r, "col_idx": c}
	return null

func _bench_world_position(orientation: String, col_idx: int, row_idx: int) -> Vector3:
	if orientation == "h":
		return Vector3(0, 0, ROW_VALUES[row_idx])
	var z: float = (ROW_VALUES[row_idx] + ROW_VALUES[row_idx + 1]) / 2.0
	return Vector3(COL_VALUES[col_idx], 0, z)

func _bench_rotation_y(orientation: String) -> float:
	return 90.0 if orientation == "v" else 0.0

func _nearest_index(values: Array, v: float) -> int:
	var best_i := 0
	var best_d := INF
	for i in range(values.size()):
		var d: float = absf(v - float(values[i]))
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _nearest_anchor(orientation: String, world_point: Vector3) -> Dictionary:
	if orientation == "h":
		return {"row_idx": _nearest_index(ROW_VALUES, world_point.z), "col_idx": 0}
	var col_idx := _nearest_index(COL_VALUES, world_point.x)
	var row_idx := 0
	if ROW_VALUES.size() >= 3:
		var mid0: float = (ROW_VALUES[0] + ROW_VALUES[1]) / 2.0
		var mid1: float = (ROW_VALUES[1] + ROW_VALUES[2]) / 2.0
		if absf(world_point.z - mid1) < absf(world_point.z - mid0):
			row_idx = 1
	return {"row_idx": row_idx, "col_idx": col_idx}

func _apply_ghost_transform() -> void:
	placing_ghost.position = _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx)
	placing_ghost.rotation_degrees.y = _bench_rotation_y(placing_orientation)

func _on_rotate_placement_pressed() -> void:
	var current_pos := _bench_world_position(placing_orientation, placing_col_idx, placing_row_idx)
	placing_orientation = "v" if placing_orientation == "h" else "h"
	var anchor := _nearest_anchor(placing_orientation, current_pos)
	placing_row_idx = anchor.row_idx
	placing_col_idx = anchor.col_idx
	_apply_ghost_transform()
	_update_placement_validity()

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
	var t: float = -origin.y / normal.y
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
	var cost: Dictionary = BENCH_COSTS[type_id]
	CheckpointData.money -= int(cost.money)
	CheckpointData.materials[cost.material] = CheckpointData.materials.get(cost.material, 0) - int(cost.amount)
	CheckpointData.placed_benches.append({
		"type": type_id, "orientation": placing_orientation,
		"col_idx": placing_col_idx, "row_idx": placing_row_idx,
	})
	_instantiate_placed_bench(type_id, placing_orientation, placing_col_idx, placing_row_idx)
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

func _instantiate_placed_bench(type_id: String, orientation: String, col_idx: int, row_idx: int) -> void:
	if not BENCH_SCENES.has(type_id):
		return
	var node: Node3D = BENCH_SCENES[type_id].instantiate()
	node.position = _bench_world_position(orientation, col_idx, row_idx)
	node.rotation_degrees.y = _bench_rotation_y(orientation)
	placed_benches_root.add_child(node)
	_placed_bench_nodes[type_id] = node

func _open_weapon_menu() -> void:
	weapon_menu.visible = true
	interact_button.visible = false
	_refresh_weapon_menu()

func _close_weapon_menu() -> void:
	weapon_menu.visible = false

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
