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
# Il furto è un importo fisso (scalato per zona come la ricompensa da
# uccisione), non più una percentuale del portafoglio corrente: così il
# rapporto tra quanto un nemico rilascia morendo e quanto ruba colpendo
# resta sempre 5:1, a qualunque cifra sia arrivato il player, invece di
# diventare sempre più punitivo in termini assoluti quanto più soldi si
# accumulano.
const KILL_REWARD_MIN := 20.0
const KILL_REWARD_MAX := 36.0
const STEAL_BASE_MONEY_MIN := KILL_REWARD_MIN / 5.0
const STEAL_BASE_MONEY_MAX := KILL_REWARD_MAX / 5.0
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

# Forza/potenza/salute dei nemici crescono con la stessa curva a rendimenti
# decrescenti dei potenziamenti delle armi (vedi upgrade_effect() in
# melee_weapons.gd/firearms.gd/throwables.gd): ci si avvicina in modo molto
# graduale a un tetto massimo senza mai raggiungerlo del tutto, invece di
# salire linearmente all'infinito. I valori di "MAX_BONUS" sono calibrati
# per coincidere con il vecchio moltiplicatore lineare a zona 50 (stesso
# livello di sfida al traguardo economico principale del gioco), ma qui la
# salita è molto più dolce zona dopo zona e non esplode nelle run più lunghe.
const HP_MAX_BONUS := 1.617
const DAMAGE_MAX_BONUS := 1.127
const SPEED_MAX_BONUS := 0.882
const COOLDOWN_MAX_REDUCTION := 0.65
const ZONE_SATURATION_ZONES := 17.0
const MONEY_PER_ZONE := 0.025
const BASE_ENEMY_COOLDOWN := 1.0

# Le prime EASY_PHASE_ZONES zone sono una fase di "rodaggio": il player ha
# il tempo di attrezzarsi (armi, potenziamenti, casa) senza che la difficoltà
# cresca già sul serio — resta quasi piatta, arrivando appena a
# EASY_PHASE_SATURATION_CAP. Da lì in poi la difficoltà comincia a salire
# davvero e continua a farlo molto gradualmente, sempre più vicina (ma senza
# mai raggiungerlo) al tetto massimo, richiedendo abilità e strategia via
# via crescenti per proseguire.
const EASY_PHASE_ZONES := 25
const EASY_PHASE_SATURATION_CAP := 0.15

# Quanto ci si è avvicinati al tetto massimo di difficoltà: 0 a zona 1, resta
# bassa fino a EASY_PHASE_ZONES, poi si avvicina a 1 molto gradualmente (mai
# raggiunto del tutto).
func _zone_difficulty_saturation(current_zone: int) -> float:
	if current_zone <= EASY_PHASE_ZONES:
		return EASY_PHASE_SATURATION_CAP * float(current_zone - 1) / float(EASY_PHASE_ZONES - 1)
	var z := float(current_zone - EASY_PHASE_ZONES)
	return EASY_PHASE_SATURATION_CAP + (1.0 - EASY_PHASE_SATURATION_CAP) * (1.0 - exp(-z / ZONE_SATURATION_ZONES))

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
# Nelle prime EASY_PHASE_ZONES zone i nemici nascono più vicini al player
# (ma sempre fuori dalla visuale, stesso vincolo di sempre) per rendere il
# gioco più rapido: meno tempo di attesa/avvicinamento tra un combattimento
# e l'altro mentre il player si sta ancora attrezzando.
const CLOSE_SPAWN_RADIUS := 30.0

@onready var hud = $HUD
@onready var player: Node3D = $Player
@onready var touch_controls = $HUD/TouchControls

const OCCLUDER_FADE_TRANSPARENCY := 0.85
const OCCLUDER_FADE_SPEED := 4.0
const OBJECT_OCCLUDER_RADIUS := 1.3
# Margine aggiunto al test di occlusione: non solo il punto esatto in cui si
# trova il player, ma un raggio più ampio intorno a lui, così quando è dietro
# un grande ostacolo l'area che sparisce è larga abbastanza da fargli vedere
# cosa ha davanti (più vicino alla sua visuale reale che a un singolo punto).
const PLAYER_VISIBILITY_MARGIN := 3.0
const PLAYER_VISIBILITY_MARGIN_OBJECT := 1.5
const PARK_WALL_CONFIGS := [
	{"path": "WallNorth", "half_extents": Vector3(42.0, 1.5, 0.5)},
	{"path": "WallSouth", "half_extents": Vector3(42.0, 1.5, 0.5)},
	{"path": "WallEast", "half_extents": Vector3(0.5, 1.5, 42.0)},
	{"path": "WallWest", "half_extents": Vector3(0.5, 1.5, 42.0)},
]
var _wall_occluders: Array = []
var _house_half_extents := Vector3(2.0, 3.5, 3.0)
var _house_exterior_meshes: Array = []

var zone := 1
var money := 0.0
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
	# WallMaterial è condiviso dai 4 muri del perimetro: un duplicato unico a
	# testa evita che la dissolvenza dell'uno si propaghi agli altri.
	for cfg in PARK_WALL_CONFIGS:
		var wall_node := get_node(String(cfg.path)) as StaticBody3D
		var wall_mesh := wall_node.get_node("MeshInstance3D") as MeshInstance3D
		var own_mat: StandardMaterial3D = (wall_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
		wall_mesh.set_surface_override_material(0, own_mat)
		_wall_occluders.append({"mesh": wall_mesh, "node": wall_node, "half_extents": cfg.half_extents})
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

	# Ogni piano sopra il terreno usa le sue vere dimensioni interne (non una
	# scala arbitraria del piano terra), impilato via via più in alto: così
	# l'esterno riflette fedelmente la pianta reale di ciascun piano, come
	# la villetta col primo piano più stretto del piano terra.
	var top_y: float = height / 2.0
	var top_width: float = width
	var top_depth: float = depth
	if not underground:
		for f in range(1, tier.floors.size()):
			var fdims: Dictionary = tier.floors[f]
			var fw: float = float(fdims.cols) * 2.0
			var fd: float = float(fdims.rows) * 2.0
			var fmesh := BoxMesh.new()
			fmesh.size = Vector3(fw, height, fd)
			var fbox := MeshInstance3D.new()
			fbox.mesh = fmesh
			fbox.set_surface_override_material(0, accent_mat)
			fbox.position = Vector3(0, top_y + height / 2.0, 0)
			accents.add_child(fbox)
			top_y = fbox.position.y + height / 2.0
			top_width = fw
			top_depth = fd

	if tier.has("roof_color"):
		var roof_height: float = height * 0.6
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(top_width * 1.08, roof_height, top_depth * 1.08)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = tier.roof_color
		roof_mat.roughness = 0.85
		var roof := MeshInstance3D.new()
		roof.mesh = roof_mesh
		roof.set_surface_override_material(0, roof_mat)
		roof.position = Vector3(0, top_y + roof_height / 2.0, 0)
		accents.add_child(roof)
		top_y = roof.position.y + roof_height / 2.0

	if int(tier.towers) > 0:
		var tower_mesh := CylinderMesh.new()
		tower_mesh.top_radius = 0.6
		tower_mesh.bottom_radius = 0.7
		tower_mesh.height = height * 2.4
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var tower := MeshInstance3D.new()
				tower.mesh = tower_mesh
				tower.set_surface_override_material(0, accent_mat)
				tower.position = Vector3(sx * (width / 2.0 - 0.6), tower_mesh.height / 2.0 - height / 2.0, sz * (depth / 2.0 - 0.6))
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

		# Una passerella di legno sopra il fossato, sul lato della porta,
		# per poterla raggiungere a piedi invece di dover attraversare
		# l'acqua.
		var bridge_length := 3.4
		var bridge_mesh := BoxMesh.new()
		bridge_mesh.size = Vector3(2.4, 0.15, bridge_length)
		var bridge_mat := StandardMaterial3D.new()
		bridge_mat.albedo_color = Color(0.42, 0.32, 0.22, 1)
		bridge_mat.roughness = 0.85
		var bridge := MeshInstance3D.new()
		bridge.mesh = bridge_mesh
		bridge.set_surface_override_material(0, bridge_mat)
		bridge.position = Vector3(0, -height / 2.0, -(depth / 2.0 + bridge_length / 2.0 - 0.1))
		accents.add_child(bridge)

	var tower_top_y: float = (height * 2.4 - height / 2.0) if int(tier.towers) > 0 else 0.0
	_house_half_extents = Vector3(max(width, top_width) / 2.0 + 1.5, max(top_y, tower_top_y) + 1.0, max(depth, top_depth) / 2.0 + 1.5)
	_house_exterior_meshes = [tent, door]
	for child in accents.get_children():
		if child is MeshInstance3D:
			_house_exterior_meshes.append(child)

	var door_world_z: float = house.position.z + depth / 2.0 + 0.02
	player.global_position = Vector3(0, 0, door_world_z + 2.5)
	player.face_direction(Vector3(0, 0, 1))

func _update_occlusion_fade(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p0 := cam.global_position
	var p1 := player.global_position

	var margin := Vector3.ONE * PLAYER_VISIBILITY_MARGIN
	for w in _wall_occluders:
		var blocking: bool = _segment_hits_aabb(p0, p1, (w.node as Node3D).global_position, w.half_extents + margin)
		_fade_toward(w.mesh, blocking, delta)

	# A zona già ripulita il player viene guidato verso casa (pulsante
	# "Torna a casa", raggio d'interazione sulla porta): la casa deve
	# restare sempre ben visibile in quel momento, non sfumare.
	var house_blocking := not zone_transitioning and _segment_hits_aabb(p0, p1, $HouseExterior.global_position, _house_half_extents + margin)
	for m in _house_exterior_meshes:
		_fade_toward(m, house_blocking, delta)

	for obj in get_tree().get_nodes_in_group("park_objects"):
		if not is_instance_valid(obj) or bool(obj.get("low_object")):
			continue
		var obj3d := obj as Node3D
		var obj_blocking: bool = _segment_hits_sphere(p0, p1, obj3d.global_position, OBJECT_OCCLUDER_RADIUS + PLAYER_VISIBILITY_MARGIN_OBJECT)
		if not obj_blocking and not obj.has_meta("occluder_meshes"):
			continue
		for m in _object_occluder_meshes(obj):
			_fade_toward(m, obj_blocking, delta)

# Materiali unici per gli oggetti creati la prima volta che servono (un
# albero/lampione/ecc. può avere più mesh, es. tronco+chioma), non subito
# per tutti i 30-45 oggetti del parco a ogni frame.
func _object_occluder_meshes(obj: Node) -> Array:
	if obj.has_meta("occluder_meshes"):
		return obj.get_meta("occluder_meshes")
	var meshes: Array = []
	_collect_unique_meshes(obj, meshes)
	obj.set_meta("occluder_meshes", meshes)
	return meshes

func _collect_unique_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
		if mat != null:
			mesh_inst.set_surface_override_material(0, mat.duplicate())
		out.append(mesh_inst)
	for child in node.get_children():
		_collect_unique_meshes(child, out)

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

# Come sopra ma per un ostacolo approssimato a una sfera (usato per gli
# oggetti del parco, più economico di un AABB orientato correttamente).
func _segment_hits_sphere(p0: Vector3, p1: Vector3, center: Vector3, radius: float) -> bool:
	var d := p1 - p0
	var len2 := d.length_squared()
	if len2 < 0.0001:
		return p0.distance_to(center) <= radius
	var t: float = clampf((center - p0).dot(d) / len2, 0.0, 1.0)
	var closest := p0 + d * t
	return closest.distance_to(center) <= radius

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
	# Il joystick di mira (e con esso il riposizionamento dei tasti
	# arma/lancio) serve anche a chi possiede solo armi da lancio e nessuna
	# arma da fuoco: senza il "or" qui i tasti restavano bloccati nel
	# segnaposto in alto a sinistra del .tscn, mai spostati vicino al
	# joystick perché _update_throw_button_positions() dipende da questo
	# stesso flag.
	touch_controls.aim_enabled = not CheckpointData.owned_firearms.is_empty() or not CheckpointData.owned_throwables.is_empty()
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
	touch_controls.aim_enabled = not CheckpointData.owned_firearms.is_empty() or not CheckpointData.owned_throwables.is_empty()
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
	# Un secondo tocco mentre l'arma da lancio è già armata la disarma (senza
	# disequipaggiarla): l'arma da fuoco torna subito utilizzabile perché il
	# blocco dipende solo dall'essere armati, non dal semplice possesso.
	if player.throw_armed:
		player.throw_armed = false
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
	var money_mult := 1.0 + MONEY_PER_ZONE * (zone - 1)
	var stolen := roundi(randf_range(STEAL_BASE_MONEY_MIN, STEAL_BASE_MONEY_MAX) * money_mult * (1.0 - reduction))
	stolen = mini(stolen, int(money))
	if stolen <= 0:
		return
	money -= stolen
	hud.update_money(money)
	hud.show_message("Un nemico ti ha rubato %d€!" % stolen)

func _start_zone() -> void:
	CheckpointData.stats_zone_reached = max(CheckpointData.stats_zone_reached, zone)
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
	# Tempo di gioco cumulativo di tutta la partita (dalla zona 1): a
	# differenza del resto dello stato, un checkpoint/morte non lo riporta
	# mai indietro (vedi CheckpointData._apply_state, usa max()).
	CheckpointData.stats_playtime_sec += delta

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
	if zone <= EASY_PHASE_ZONES:
		var near_points := []
		for sp in active_points:
			if player.global_position.distance_to(sp.pos) <= CLOSE_SPAWN_RADIUS:
				near_points.append(sp)
		if not near_points.is_empty():
			return near_points[randi() % near_points.size()]
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

	var sat := _zone_difficulty_saturation(zone)
	var hp_mult := 1.0 + HP_MAX_BONUS * sat
	var dmg_mult := 1.0 + DAMAGE_MAX_BONUS * sat
	var speed_mult := 1.0 + SPEED_MAX_BONUS * sat
	var cooldown: float = BASE_ENEMY_COOLDOWN * (1.0 - COOLDOWN_MAX_REDUCTION * sat)
	var archetype_id := EnemyArchetypes.pick(zone)
	enemy.configure(hp_mult, dmg_mult, speed_mult, cooldown, archetype_id)
	enemy.died.connect(_on_enemy_died.bind(enemy))

	zone_enemies_spawned += 1
	zone_enemies_alive += 1

func _on_enemy_died(enemy: Node3D) -> void:
	zone_enemies_alive -= 1
	CheckpointData.stats_enemies_defeated += 1
	var money_mult := 1.0 + MONEY_PER_ZONE * (zone - 1)
	var saccheggio_mult: float = 1.0 + PlayerUpgrades.effect("saccheggio", upgrades.get("saccheggio", 0))
	var reward := roundi(randf_range(KILL_REWARD_MIN, KILL_REWARD_MAX) * money_mult * saccheggio_mult)
	money += reward
	CheckpointData.stats_money_earned += reward
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

const OBJECT_SPAWN_POINT_CLEARANCE := 3.5

func _random_object_position() -> Vector3:
	var pos := Vector3.ZERO
	for attempt in range(10):
		var x := randf_range(-ARENA_HALF, ARENA_HALF)
		var z := randf_range(-ARENA_HALF, ARENA_HALF)
		pos = Vector3(x, 0.0, z)
		if pos.length() > OBJECT_CLEAR_RADIUS and pos.distance_to(HOUSE_DOOR_POS) > HOUSE_CLEAR_RADIUS and not _near_spawn_point(pos):
			return pos
	return pos

# Evita che un oggetto compaia esattamente su un punto di spawn dei nemici:
# altrimenti il nemico che nasce lì resta incastrato nell'oggetto.
func _near_spawn_point(pos: Vector3) -> bool:
	for sp in spawn_points:
		if pos.distance_to(sp.pos) < OBJECT_SPAWN_POINT_CLEARANCE:
			return true
	return false

func _on_player_died() -> void:
	hud.show_message("Sei stato steso.")
	if not DevMode.enabled:
		SaveData.report_run(zone, int(money))
		CheckpointData.load_checkpoint()
		# Il salvataggio "riprendi partita" (più recente del checkpoint)
		# andrebbe altrimenti a resuscitare i progressi appena persi con la
		# morte a un successivo riavvio del gioco: lo invalido insieme al
		# ripristino del checkpoint.
		CheckpointData.clear_continue_save()
	hud.show_game_over()

func get_stats_text() -> String:
	# Statistiche cumulative dell'intera partita dalla zona 1: a differenza
	# di zone/money correnti (che un checkpoint riporta indietro in caso di
	# morte), queste contano il totale giocato, morti comprese.
	var stats_zone: int = max(CheckpointData.stats_zone_reached, zone)
	var elapsed_sec := int(CheckpointData.stats_playtime_sec)
	var minutes := elapsed_sec / 60
	var seconds := elapsed_sec % 60
	return "Zona raggiunta: %d\nSoldi guadagnati: %d€\nNemici sconfitti: %d\nTempo: %02d:%02d" % [
		stats_zone, CheckpointData.stats_money_earned, CheckpointData.stats_enemies_defeated, minutes, seconds,
	]

func get_inventory_text() -> String:
	if DevMode.enabled:
		return "Arma equipaggiata: %s\n\nMateriali:\nLegno: ∞   Metallo: ∞   Cablaggi: ∞" % weapon_name
	return "Arma equipaggiata: %s\n\nMateriali:\nLegno: %d   Metallo: %d   Cablaggi: %d" % [
		weapon_name, materials.get("legno", 0), materials.get("metallo", 0), materials.get("cablaggi", 0)
	]
