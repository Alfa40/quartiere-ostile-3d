extends Node3D

const EnemyScene := preload("res://scenes/Enemy.tscn")
const MedikitScene := preload("res://scenes/Medikit.tscn")
const EnemyArchetypes := preload("res://scripts/enemy_archetypes.gd")
const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")
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
	hud.update_money(money)
	for obj in get_tree().get_nodes_in_group("park_objects"):
		obj.destroyed.connect(_on_object_destroyed.bind(obj))
	_build_spawn_points()
	_start_zone()

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
	)

func get_firearm_reserve_ammo(fid: String) -> int:
	return int(CheckpointData.firearm_ammo.get(fid, 0))

func consume_firearm_reserve_ammo(fid: String, amount: int) -> void:
	CheckpointData.firearm_ammo[fid] = max(0, int(CheckpointData.firearm_ammo.get(fid, 0)) - amount)

func _apply_throwable_stats() -> void:
	var tid: String = CheckpointData.equipped_throwable
	if tid == "" or not Throwables.WEAPONS.has(tid):
		player.unequip_throwable()
		hud.update_throw_type_label("-")
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
	)
	hud.update_throw_type_label(String(def.label))

func get_throwable_reserve_ammo(tid: String) -> int:
	return int(CheckpointData.throwable_ammo.get(tid, 0))

func consume_throwable_reserve_ammo(tid: String, amount: int) -> void:
	CheckpointData.throwable_ammo[tid] = max(0, int(CheckpointData.throwable_ammo.get(tid, 0)) - amount)

func _on_throw_type_pressed() -> void:
	var owned: Array = CheckpointData.owned_throwables.keys()
	if owned.is_empty():
		return
	var idx := owned.find(CheckpointData.equipped_throwable)
	idx = (idx + 1) % owned.size()
	CheckpointData.equipped_throwable = owned[idx]
	_apply_throwable_stats()

func _on_throw_arm_pressed() -> void:
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
