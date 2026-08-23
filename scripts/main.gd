extends Node3D

const EnemyScene := preload("res://scenes/Enemy.tscn")
const MedikitScene := preload("res://scenes/Medikit.tscn")
const EnemyArchetypes := preload("res://scripts/enemy_archetypes.gd")
const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")
const HouseTiers := preload("res://scripts/house_tiers.gd")
const MEDIKIT_CHANCE := 0.16

const STEAL_CHANCE := 0.35
const STEAL_BASE_FRACTION := 0.12
const BASE_PLAYER_MAX_HP := 100.0

const OBJECT_SCENES := {
	"albero": preload("res://scenes/Albero.tscn"),
	"lampione": preload("res://scenes/Lampione.tscn"),
	"panchina": preload("res://scenes/Panchina.tscn"),
	"cassonetto": preload("res://scenes/Cassonetto.tscn"),
	"barile": preload("res://scenes/Barile.tscn"),
	"cestino": preload("res://scenes/Cestino.tscn"),
	"recinzione": preload("res://scenes/Recinzione.tscn"),
}
const ARENA_HALF := 38.0
const OBJECT_CLEAR_RADIUS := 6.0
const OBJECT_COUNT_MIN := 30
const OBJECT_COUNT_MAX := 45

const HOUSE_DOOR_POS := Vector3(0, 0, 17.5)
const HOUSE_CLEAR_RADIUS := 10.0
const HOUSE_INTERACT_RANGE := 2.5
const HOUSE_EXIT_SPAWN_POS := Vector3(0, 0, 21)

const MATERIAL_LABELS := {
	"legno": "Legno",
	"metallo": "Metallo",
	"cablaggi": "Cablaggi",
}

const BASE_ENEMIES := 5
const PER_ZONE := 2
const MAX_ENEMIES_PER_ZONE := 16
const MAX_CONCURRENT := 6
const SPAWN_INTERVAL := 0.9

const HP_PER_ZONE := 0.033
const DAMAGE_PER_ZONE := 0.023
const SPEED_PER_ZONE := 0.018
const COOLDOWN_FACTOR_PER_ZONE := 0.011
const MIN_COOLDOWN := 0.35
const MONEY_PER_ZONE := 0.025
const BASE_ENEMY_COOLDOWN := 1.0

const ZONE_NAMES := [
	"Ai margini del quartiere", "Vicoli stretti", "Cortili abbandonati",
	"Il blocco centrale", "Zona rossa", "Il fondo del quartiere",
	"Oltre i confini conosciuti", "Il centro città in fiamme",
	"Le torri abbandonate", "L'ultimo isolato",
]

const SPAWN_GRID_STEP := 12.0
const SPAWN_GRID_HALF := 32.0
const SPAWN_HOUSE_EXCLUDE_RADIUS := 12.0
const SPAWN_DEACTIVATE_RADIUS := 18.0
const SPAWN_RETRY_DELAY := 0.2

@onready var hud = $HUD
@onready var player: Node3D = $Player
@onready var touch_controls = $HUD/TouchControls
@onready var wall_south_mesh: MeshInstance3D = $WallSouth/MeshInstance3D

const OCCLUDER_FADE_TRANSPARENCY := 0.85
const OCCLUDER_FADE_SPEED := 4.0
const WALL_SOUTH_HALF_EXTENTS := Vector3(42.0, 1.5, 0.5)
var _house_half_extents := Vector3(2.0, 3.5, 3.0)
var _house_exterior_meshes: Array = []

var zone := 1
var money := 0.0
var enemies_defeated := 0
var run_start_msec := 0
var materials := {"legno": 0, "metallo": 0, "cablaggi": 0}
var upgrades := {}
var weapon_name := "Pugni"

var zone_enemies_total := 0
var zone_enemies_spawned := 0
var zone_enemies_alive := 0
var spawn_timer := 0.0
var zone_transitioning := false
var spawn_points := []

var _pre_creator_money := 0.0
var _pre_creator_materials := {}

func _ready() -> void:
	run_start_msec = Time.get_ticks_msec()
	# WallMaterial è condiviso dai 4 muri del perimetro: duplicarlo solo per
	# quello sud evita che la sua dissolvenza si propaghi agli altri tre.
	var wall_south_own_mat: StandardMaterial3D = (wall_south_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	wall_south_mesh.set_surface_override_material(0, wall_south_own_mat)
	zone = CheckpointData.zone
	upgrades = CheckpointData.upgrades.duplicate()
	if DevMode.enabled:
		money = 999999.0
		materials = {"legno": 999999, "metallo": 999999, "cablaggi": 999999}
	else:
		money = float(CheckpointData.money)
		materials = CheckpointData.materials.duplicate()
	player.hp_changed.connect(hud.on_player_hp_changed)
	player.died.connect(_on_player_died)
	hud.go_home_chosen.connect(_go_home)
	hud.skip_home_chosen.connect(_skip_home)
	hud.house_enter_pressed.connect(_enter_house_anytime)
	hud.throw_type_pressed.connect(_on_throw_type_pressed)
	hud.throw_arm_pressed.connect(_on_throw_arm_pressed)
	_apply_upgrade_effects()
	_apply_weapon_stats()
	_apply_firearm_stats()
	_apply_throwable_stats()
	_apply_house_exterior()
	hud.update_money(money)
	for obj in get_tree().get_nodes_in_group("park_objects"):
		obj.destroyed.connect(_on_object_destroyed.bind(obj))
	_build_spawn_points()
	_start_zone()

func _apply_house_exterior() -> void:
	var tier: Dictionary = HouseTiers.tier_data(CheckpointData.house_tier)
	var floors: int = int(tier.floors.size())
	var underground: bool = bool(tier.underground)
	var ground: Dictionary = tier.floors[0]
	var width: float = 3.0 if underground else float(ground.cols) * 2.0
	var depth: float = 3.0 if underground else float(ground.rows) * 2.0
	var height: float = 2.2

	var house := $HouseExterior
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = tier.wall_color
	wall_mat.roughness = 0.9

	var tent := house.get_node("Tent") as MeshInstance3D
	if String(tier.shape) == "tent":
		var tent_mesh := PrismMesh.new()
		tent_mesh.size = Vector3(width, height, depth)
		tent.mesh = tent_mesh
	else:
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(width, height, depth)
		tent.mesh = box_mesh
	tent.set_surface_override_material(0, wall_mat)

	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, height, depth)
	(house.get_node("CollisionShape3D") as CollisionShape3D).shape = box_shape

	var door := house.get_node("Door") as MeshInstance3D
	door.position = Vector3(0, -0.3, -(depth / 2.0 + 0.02))
	# Materiale unico anche per la porta: il sub_resource della scena
	# sarebbe altrimenti condiviso tra le varie istanze di Main.tscn create
	# a ogni cambio di scena, facendo persistere un'eventuale dissolvenza.
	var door_own_mat: StandardMaterial3D = (door.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	door.set_surface_override_material(0, door_own_mat)

	var light := house.get_node("Light") as OmniLight3D
	light.position = Vector3(0, height * 0.68, -(depth / 2.0 - 1.0))

	var accents := house.get_node_or_null("Accents")
	if accents != null:
		accents.free()
	accents = Node3D.new()
	accents.name = "Accents"
	house.add_child(accents)

	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = tier.accent_color
	accent_mat.roughness = 0.7

	var top_y: float = height / 2.0
	if floors >= 2 and not underground:
		var upper_mesh := BoxMesh.new()
		var upper_w: float = width * 0.7
		var upper_d: float = depth * 0.7
		upper_mesh.size = Vector3(upper_w, height * 0.8, upper_d)
		var upper := MeshInstance3D.new()
		upper.mesh = upper_mesh
		upper.set_surface_override_material(0, accent_mat)
		upper.position = Vector3(0, height / 2.0 + height * 0.4, 0)
		accents.add_child(upper)
		top_y = upper.position.y + upper_mesh.size.y / 2.0

	if tier.has("roof_color"):
		var top_floor: Dictionary = tier.floors[tier.floors.size() - 1]
		var roof_width: float = float(top_floor.cols) * 2.0
		var roof_depth: float = float(top_floor.rows) * 2.0
		var roof_height: float = height * 0.6
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(roof_width * 1.08, roof_height, roof_depth * 1.08)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = tier.roof_color
		roof_mat.roughness = 0.85
		var roof := MeshInstance3D.new()
		roof.mesh = roof_mesh
		roof.set_surface_override_material(0, roof_mat)
		roof.position = Vector3(0, top_y + roof_height / 2.0, 0)
		accents.add_child(roof)

	_house_half_extents = Vector3(width / 2.0 + 1.5, 3.5, depth / 2.0 + 1.5)
	_house_exterior_meshes = [tent, door]
	for child in accents.get_children():
		if child is MeshInstance3D:
			_house_exterior_meshes.append(child)

	if int(tier.towers) > 0:
		var tower_mesh := CylinderMesh.new()
		tower_mesh.top_radius = 0.35
		tower_mesh.bottom_radius = 0.4
		tower_mesh.height = height * 1.6
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var tower := MeshInstance3D.new()
				tower.mesh = tower_mesh
				tower.set_surface_override_material(0, accent_mat)
				tower.position = Vector3(sx * (width / 2.0 - 0.3), tower_mesh.height / 2.0 - height / 2.0, sz * (depth / 2.0 - 0.3))
				accents.add_child(tower)

	if bool(tier.moat):
		var moat_mesh := BoxMesh.new()
		moat_mesh.size = Vector3(width + 3.0, 0.15, depth + 3.0)
		var moat_mat := StandardMaterial3D.new()
		moat_mat.albedo_color = Color(0.15, 0.35, 0.55, 1)
		moat_mat.roughness = 0.3
		var moat := MeshInstance3D.new()
		moat.mesh = moat_mesh
		moat.set_surface_override_material(0, moat_mat)
		moat.position = Vector3(0, -height / 2.0 - 0.05, 0)
		accents.add_child(moat)

	var door_world_z: float = house.position.z + depth / 2.0 + 0.02
	player.global_position = Vector3(0, 0, door_world_z + 2.5)
	player.face_direction(Vector3(0, 0, 1))

func _update_occlusion_fade(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p0 := cam.global_position
	var p1 := player.global_position

	var wall_blocking := _segment_hits_aabb(p0, p1, $WallSouth.global_position, WALL_SOUTH_HALF_EXTENTS)
	_fade_toward(wall_south_mesh, wall_blocking, delta)

	var house_blocking := _segment_hits_aabb(p0, p1, $HouseExterior.global_position, _house_half_extents)
	for m in _house_exterior_meshes:
		_fade_toward(m, house_blocking, delta)

func _fade_toward(mesh_inst: MeshInstance3D, blocking: bool, delta: float) -> void:
	if mesh_inst == null:
		return
	var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	var target: float = 1.0 - OCCLUDER_FADE_TRANSPARENCY if blocking else 1.0
	var new_alpha: float = move_toward(mat.albedo_color.a, target, OCCLUDER_FADE_SPEED * delta)
	mat.albedo_color.a = new_alpha
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if new_alpha < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED

# Test segmento-vs-AABB (metodo delle slab) usato per far svanire un
# ostacolo (muro sud, esterno della casa) quando si trova esattamente sulla
# linea tra la telecamera e il player, così da non coprirne la visuale.
func _segment_hits_aabb(p0: Vector3, p1: Vector3, box_center: Vector3, half_extents: Vector3) -> bool:
	var d := p1 - p0
	var tmin := 0.0
	var tmax := 1.0
	for axis in range(3):
		var o: float = p0[axis] - box_center[axis]
		var dd: float = d[axis]
		var he: float = half_extents[axis]
		if absf(dd) < 0.0001:
			if absf(o) > he:
				return false
		else:
			var t1: float = (-he - o) / dd
			var t2: float = (he - o) / dd
			if t1 > t2:
				var tmp := t1
				t1 = t2
				t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return false
	return true

func _build_spawn_points() -> void:
	spawn_points.clear()
	var house_pos := Vector3(0, 0, 14)
	var x := -SPAWN_GRID_HALF
	while x <= SPAWN_GRID_HALF:
		var z := -SPAWN_GRID_HALF
		while z <= SPAWN_GRID_HALF:
			var pos := Vector3(x, 0, z)
			if pos.distance_to(house_pos) > SPAWN_HOUSE_EXCLUDE_RADIUS:
				spawn_points.append({"pos": pos, "active": true})
			z += SPAWN_GRID_STEP
		x += SPAWN_GRID_STEP

func _apply_upgrade_effects() -> void:
	var speed_bonus: float = PlayerUpgrades.effect("scarpe", upgrades.get("scarpe", 0))
	player.speed_mult = 1.0 + speed_bonus
	var hp_bonus: float = PlayerUpgrades.effect("salute", upgrades.get("salute", 0))
	player.max_hp = BASE_PLAYER_MAX_HP + hp_bonus
	player.hp = player.max_hp
	player.hp_changed.emit(player.hp, player.max_hp)

func _apply_weapon_stats() -> void:
	var wid: String = CheckpointData.equipped_weapon
	if wid == "pugni" or not MeleeWeapons.WEAPONS.has(wid):
		weapon_name = "Pugni"
		player.attack_damage = player.BASE_ATTACK_DAMAGE
		player.attack_cooldown = player.BASE_ATTACK_COOLDOWN
		player.attack_reach_mult = 1.0
		return
	var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})
	var def: Dictionary = MeleeWeapons.WEAPONS[wid]
	weapon_name = String(def.label)
	player.attack_damage = MeleeWeapons.final_damage(wid, wups)
	player.attack_cooldown = MeleeWeapons.final_cooldown(wid, wups)
	player.attack_reach_mult = MeleeWeapons.final_reach_mult(wid, wups)
	player.apply_draw_delay(MeleeWeapons.final_draw_time(wid, wups))

func _apply_firearm_stats() -> void:
	var fid: String = CheckpointData.equipped_firearm
	touch_controls.aim_enabled = not CheckpointData.owned_firearms.is_empty()
	if fid == "" or not Firearms.WEAPONS.has(fid):
		player.unequip_firearm()
		return
	var fups: Dictionary = CheckpointData.firearm_upgrades.get(fid, {})
	var def: Dictionary = Firearms.WEAPONS[fid]
	player.equip_firearm(
		fid,
		Firearms.final_damage(fid, fups),
		Firearms.final_cooldown(fid, fups),
		Firearms.final_range(fid, fups),
		Firearms.final_draw_time(fid, fups),
		int(def.magazine_size),
		float(def.reload_time),
		String(def.fire_mode),
		int(def.get("burst_count", 1)),
		float(def.get("burst_delay", 0.0)),
		Firearms.bullet_speed(fid),
		Firearms.final_spread_degrees(fid, fups),
		Firearms.pellet_count(fid),
		Firearms.final_pellet_spread_degrees(fid, fups),
		Firearms.final_aim_line_length(fid, fups),
		String(def.get("projectile_type", "bullet")),
		String(def.get("grenade_type", "")),
		float(def.get("explosion_radius", 3.0)),
		float(def.get("burn_duration", 0.0)),
		float(def.get("burn_dps", 0.0)),
		int(def.get("cluster_count", 0)),
		float(def.get("cluster_radius", 0.0)),
		float(def.get("stun_duration", 0.0)),
	)

func get_firearm_reserve_ammo(fid: String) -> int:
	return int(CheckpointData.firearm_ammo.get(fid, 0))

func consume_firearm_reserve_ammo(fid: String, amount: int) -> void:
	CheckpointData.firearm_ammo[fid] = max(0, int(CheckpointData.firearm_ammo.get(fid, 0)) - amount)

func _apply_throwable_stats() -> void:
	var tid: String = CheckpointData.equipped_throwable
	# L'arma "in mano" deve sempre far parte del loadout attuale (al massimo
	# un'arma per categoria): se non lo è più (es. tolta dal banco), scelgo
	# la prima arma ancora equipaggiata, se ce n'è una.
	if tid == "" or not CheckpointData.equipped_throwables.values().has(tid):
		tid = ""
		for cat_id in CheckpointData.equipped_throwables:
			var cat_wid: String = String(CheckpointData.equipped_throwables[cat_id])
			if cat_wid != "":
				tid = cat_wid
				break
		CheckpointData.equipped_throwable = tid
	if tid == "" or not Throwables.WEAPONS.has(tid):
		player.unequip_throwable()
		return
	var tups: Dictionary = CheckpointData.throwable_upgrades.get(tid, {})
	var def: Dictionary = Throwables.WEAPONS[tid]
	player.equip_throwable(
		tid,
		Throwables.final_damage(tid, tups),
		Throwables.final_cooldown(tid, tups),
		Throwables.final_range(tid, tups),
		Throwables.final_draw_time(tid, tups),
		String(def.get("grenade_type", "")),
		float(def.get("explosion_radius", 3.0)),
		float(def.get("burn_duration", 0.0)),
		float(def.get("burn_dps", 0.0)),
		int(def.get("cluster_count", 0)),
		float(def.get("cluster_radius", 0.0)),
		Throwables.final_aim_line_length(tid, tups),
		float(def.get("stun_duration", 0.0)),
	)

func get_throwable_reserve_ammo(tid: String) -> int:
	return int(CheckpointData.throwable_ammo.get(tid, 0))

func consume_throwable_reserve_ammo(tid: String, amount: int) -> void:
	CheckpointData.throwable_ammo[tid] = max(0, int(CheckpointData.throwable_ammo.get(tid, 0)) - amount)

func _on_throw_type_pressed() -> void:
	# Il ciclo passa solo tra le armi effettivamente equipaggiate (al massimo
	# una per categoria), non tra tutte quelle possedute.
	var loadout: Array = []
	for cat_id in Throwables.CATEGORY_ORDER:
		var wid: String = String(CheckpointData.equipped_throwables.get(cat_id, ""))
		if wid != "":
			loadout.append(wid)
	if loadout.is_empty():
		return
	var idx := loadout.find(CheckpointData.equipped_throwable)
	idx = (idx + 1) % loadout.size()
	CheckpointData.equipped_throwable = loadout[idx]
	_apply_throwable_stats()
	var new_tid: String = CheckpointData.equipped_throwable
	var new_label: String = String(Throwables.WEAPONS[new_tid].label) if Throwables.WEAPONS.has(new_tid) else "-"
	hud.flash_throw_type_toast(new_label)

func _on_throw_arm_pressed() -> void:
	# Se una granata appiccicosa è in attesa di detonazione ha sempre la
	# priorità (arm_throw() la gestisce internamente).
	if player.active_sticky_grenade != null and is_instance_valid(player.active_sticky_grenade):
		player.arm_throw()
		return
	# Un secondo tocco mentre l'arma da lancio è già armata la disequipaggia,
	# così il player può tornare subito a usare l'arma da fuoco senza dover
	# sprecare un lancio o passare dal banco di casa.
	if player.throw_armed:
		player.throw_armed = false
		CheckpointData.equipped_throwable = ""
		_apply_throwable_stats()
		return
	player.arm_throw()

func set_creator_mode(target_enabled: bool) -> void:
	if target_enabled and not DevMode.enabled:
		_pre_creator_money = money
		_pre_creator_materials = materials.duplicate()
		DevMode.enabled = true
		money = 999999.0
		materials = {"legno": 999999, "metallo": 999999, "cablaggi": 999999}
		hud.update_money(money)
	elif not target_enabled and DevMode.enabled:
		DevMode.enabled = false
		money = _pre_creator_money
		materials = _pre_creator_materials.duplicate()
		hud.update_money(money)

func dev_jump_to_zone(target: int) -> void:
	if not DevMode.enabled or zone_transitioning:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	zone = max(1, target)
	_start_zone()

func dev_clear_zone() -> void:
	if not DevMode.enabled or zone_transitioning:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	zone_enemies_alive = 0
	zone_enemies_spawned = zone_enemies_total
	_complete_zone()

func on_player_damaged(_amount: float) -> void:
	if DevMode.enabled or money <= 0.0:
		return
	if randf() > STEAL_CHANCE:
		return
	var reduction: float = clamp(PlayerUpgrades.effect("sicurezza", upgrades.get("sicurezza", 0)), 0.0, 0.9)
	var steal_fraction := STEAL_BASE_FRACTION * (1.0 - reduction)
	var stolen := roundi(money * steal_fraction)
	if stolen <= 0:
		return
	money -= stolen
	hud.update_money(money)
	hud.show_message("Un nemico ti ha rubato %d€!" % stolen)

func _start_zone() -> void:
	zone_transitioning = false
	if zone > 1:
		_regenerate_objects()
	zone_enemies_total = min(BASE_ENEMIES + PER_ZONE * (zone - 1), MAX_ENEMIES_PER_ZONE)
	zone_enemies_spawned = 0
	zone_enemies_alive = 0
	spawn_timer = 0.0
	var zone_name: String = ZONE_NAMES[min(zone - 1, ZONE_NAMES.size() - 1)]
	hud.update_zone(zone, zone_name)
	hud.show_message("Zona %d iniziata: ripulisci il quartiere!" % zone)
	if not DevMode.enabled:
		SaveData.report_run(zone, int(money))

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		get_tree().paused = false
		get_tree().reload_current_scene()

	_update_occlusion_fade(delta)

	if zone_transitioning or player.dead:
		if zone_transitioning and not player.dead:
			var dist_to_house := player.global_position.distance_to(HOUSE_DOOR_POS)
			hud.set_house_button_visible(dist_to_house <= HOUSE_INTERACT_RANGE)
		else:
			hud.set_house_button_visible(false)
		hud.set_throw_buttons_visible(false)
		return

	hud.set_house_button_visible(false)
	hud.set_throw_buttons_visible(not CheckpointData.owned_throwables.is_empty())
	_update_spawn_points()

	if zone_enemies_spawned < zone_enemies_total:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and zone_enemies_alive < MAX_CONCURRENT:
			_spawn_enemy()

func _update_spawn_points() -> void:
	var cam := get_viewport().get_camera_3d()
	for sp in spawn_points:
		if sp.active:
			if player.global_position.distance_to(sp.pos) < SPAWN_DEACTIVATE_RADIUS:
				sp.active = false
		elif cam == null or not _point_in_camera_frustum(cam, sp.pos):
			sp.active = true

func _point_in_camera_frustum(cam: Camera3D, pos: Vector3) -> bool:
	for plane in cam.get_frustum():
		if plane.is_point_over(pos):
			return false
	return true

func _pick_active_spawn_point():
	var active_points := []
	for sp in spawn_points:
		if sp.active:
			active_points.append(sp)
	if active_points.is_empty():
		return null
	return active_points[randi() % active_points.size()]

func _spawn_enemy() -> void:
	var sp = _pick_active_spawn_point()
	if sp == null:
		spawn_timer = SPAWN_RETRY_DELAY
		return
	sp.active = false

	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	enemy.position = sp.pos
	spawn_timer = SPAWN_INTERVAL

	var hp_mult := 1.0 + HP_PER_ZONE * (zone - 1)
	var dmg_mult := 1.0 + DAMAGE_PER_ZONE * (zone - 1)
	var speed_mult := 1.0 + SPEED_PER_ZONE * (zone - 1)
	var cooldown: float = max(BASE_ENEMY_COOLDOWN * (1.0 - COOLDOWN_FACTOR_PER_ZONE * (zone - 1)), MIN_COOLDOWN)
	var archetype_id := EnemyArchetypes.pick(zone)
	enemy.configure(hp_mult, dmg_mult, speed_mult, cooldown, archetype_id)
	enemy.died.connect(_on_enemy_died.bind(enemy))

	zone_enemies_spawned += 1
	zone_enemies_alive += 1

func _on_enemy_died(enemy: Node3D) -> void:
	zone_enemies_alive -= 1
	enemies_defeated += 1
	var money_mult := 1.0 + MONEY_PER_ZONE * (zone - 1)
	var saccheggio_mult: float = 1.0 + PlayerUpgrades.effect("saccheggio", upgrades.get("saccheggio", 0))
	var reward := roundi(randf_range(10.0, 18.0) * money_mult * saccheggio_mult)
	money += reward
	hud.update_money(money)

	var msg := "Nemico sconfitto (+%d€)" % reward
	if randf() < MEDIKIT_CHANCE:
		_spawn_medikit(enemy.global_position)
		msg += " — ha lasciato un medikit"
	hud.show_message(msg)

	if zone_enemies_spawned >= zone_enemies_total and zone_enemies_alive <= 0 and not zone_transitioning:
		_complete_zone()

func _spawn_medikit(pos: Vector3) -> void:
	var medikit = MedikitScene.instantiate()
	add_child(medikit)
	medikit.position = pos

func _on_object_destroyed(obj: Node3D) -> void:
	var drops: Dictionary = obj.material_drops
	if drops.is_empty():
		return
	var zaino_mult: float = 1.0 + PlayerUpgrades.effect("zaino", upgrades.get("zaino", 0))
	var parts: Array[String] = []
	for mat in drops:
		var amount := roundi(int(drops[mat]) * zaino_mult)
		materials[mat] = materials.get(mat, 0) + amount
		parts.append("+%d %s" % [amount, MATERIAL_LABELS.get(mat, mat)])
	hud.show_message(", ".join(parts))

func _complete_zone() -> void:
	zone_transitioning = true
	if not DevMode.enabled and CheckpointData.is_checkpoint_zone(zone):
		CheckpointData.save_checkpoint(zone, int(money), materials, upgrades)
	hud.show_zone_complete_choice()

func _go_home() -> void:
	CheckpointData.set_live_state(zone + 1, int(money), materials, upgrades)
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _skip_home() -> void:
	zone += 1
	player.global_position = HOUSE_EXIT_SPAWN_POS
	player.velocity = Vector3.ZERO
	_start_zone()

func _enter_house_anytime() -> void:
	CheckpointData.set_live_state(zone, int(money), materials, upgrades)
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

func _regenerate_objects() -> void:
	for obj in get_tree().get_nodes_in_group("park_objects"):
		obj.queue_free()

	var count := randi_range(OBJECT_COUNT_MIN, OBJECT_COUNT_MAX)
	var keys := OBJECT_SCENES.keys()
	for i in range(count):
		var type_id: String = keys[randi() % keys.size()]
		var scene: PackedScene = OBJECT_SCENES[type_id]
		var obj = scene.instantiate()
		obj.position = _random_object_position()
		if type_id == "albero":
			var tier := randf()
			if tier < 0.34:
				obj.scale = Vector3.ONE * 0.65
				obj.max_hp = 140.0
				obj.material_drops = {"legno": 2}
			elif tier < 0.67:
				obj.scale = Vector3.ONE * 1.0
				obj.max_hp = 280.0
				obj.material_drops = {"legno": 4}
			else:
				obj.scale = Vector3.ONE * 1.5
				obj.max_hp = 480.0
				obj.material_drops = {"legno": 6}
		elif type_id == "recinzione":
			obj.rotation_degrees.y = 90.0 if randf() < 0.5 else 0.0
		add_child(obj)
		obj.destroyed.connect(_on_object_destroyed.bind(obj))

func _random_object_position() -> Vector3:
	var pos := Vector3.ZERO
	for attempt in range(10):
		var x := randf_range(-ARENA_HALF, ARENA_HALF)
		var z := randf_range(-ARENA_HALF, ARENA_HALF)
		pos = Vector3(x, 0.0, z)
		if pos.length() > OBJECT_CLEAR_RADIUS and pos.distance_to(HOUSE_DOOR_POS) > HOUSE_CLEAR_RADIUS:
			return pos
	return pos

func _on_player_died() -> void:
	hud.show_message("Sei stato steso.")
	if not DevMode.enabled:
		SaveData.report_run(zone, int(money))
		CheckpointData.load_checkpoint()
	hud.show_game_over()

func get_stats_text() -> String:
	var elapsed_sec := int((Time.get_ticks_msec() - run_start_msec) / 1000.0)
	var minutes := elapsed_sec / 60
	var seconds := elapsed_sec % 60
	return "Zona raggiunta: %d\nSoldi guadagnati: %d€\nNemici sconfitti: %d\nTempo: %02d:%02d" % [zone, int(money), enemies_defeated, minutes, seconds]

func get_inventory_text() -> String:
	if DevMode.enabled:
		return "Arma equipaggiata: %s\n\nMateriali:\nLegno: ∞   Metallo: ∞   Cablaggi: ∞" % weapon_name
	return "Arma equipaggiata: %s\n\nMateriali:\nLegno: %d   Metallo: %d   Cablaggi: %d" % [
		weapon_name, materials.get("legno", 0), materials.get("metallo", 0), materials.get("cablaggi", 0)
	]
