extends Node3D

const EnemyScene := preload("res://scenes/Enemy.tscn")
const MedikitScene := preload("res://scenes/Medikit.tscn")
const EnemyArchetypes := preload("res://scripts/enemy_archetypes.gd")
const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const MeleeWeapons := preload("res://scripts/melee_weapons.gd")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")
const HouseTiers := preload("res://scripts/house_tiers.gd")
const HouseLight := preload("res://scripts/house_light.gd")
const Scenarios := preload("res://scripts/scenarios.gd")
const NightGodScene := preload("res://scenes/NightGod.tscn")
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
const HOUSE_INTERACT_RANGE := 2.5
const HOUSE_EXIT_SPAWN_POS := Vector3(0, 0, 21)

# "Tempesta": il buio inizia a chiudersi verso la casa 90s dopo essere
# usciti, oppure subito alla sconfitta di tutti i nemici della zona (quale
# delle due capita prima) — non si riazzera cambiando zona senza tornare a
# casa (_skip_home()), solo tornando davvero a casa (nuova istanza di
# Main.tscn). Raggio di partenza abbastanza grande da coprire tutta l'arena
# vista dalla casa (diagonale ~70, con margine). Il raggio minimo verso cui
# si restringe non è fisso: dipende dalla luce della casa (HouseLight,
# 0 senza luce acquistata — il buio arriva fino alla porta — fino a 24 al
# livello massimo), un margine che il player può ampliare potenziandola.
const STORM_DELAY := 90.0
const STORM_DURATION := 30.0
# Deve partire esattamente dai bordi del campo da gioco, non da un valore
# arbitrario più grande: il punto dell'arena (ARENA_HALF=38) più lontano
# dalla casa è uno degli angoli opposti, a ~64.4 unità (casa a z=14, angolo
# a x=∓38/z=-38) — 65 lo supera appena, così la tempesta è già visibile fin
# dal primo istante invece di restringersi per un bel po' senza alcun
# effetto percepibile.
const STORM_START_RADIUS := 65.0
# Quando il buio si chiude del tutto senza che la zona sia stata ripulita, i
# nemici ancora vivi devono "sentire" il player ovunque nell'arena (vedi
# Enemy.detect_range_override, già usato per gli incontri scriptati del
# tutorial).
const STORM_ENEMY_DETECT_OVERRIDE := 200.0

# Buio personale: appena il player esce dal raggio sicuro (sopra) non muore
# sul colpo — vede solo pochi passi attorno a sé (una piccola vignetta a
# schermo sempre centrata sul player, vedi shaders/darkness_vignette e
# hud.set_house_vignette) e a intervalli casuali tra
# NIGHT_GOD_SPAWN_INTERVAL_MIN e MAX nasce a NIGHT_GOD_SPAWN_DISTANCE dal
# player, dal lato rivolto verso casa, un "dio della notte": lento (una
# frazione della velocità attuale del player, aggiornamenti/potenziamenti
# compresi) ma letale al contatto e con vita spropositata (in pratica
# infondabile, l'unica strategia è scappare). Rientrare nel raggio sicuro li
# dissolve subito: il buio, da quel momento, torna innocuo.
const NIGHT_GOD_SPAWN_DISTANCE := 6.0
const NIGHT_GOD_SPAWN_INTERVAL_MIN := 0.5
const NIGHT_GOD_SPAWN_INTERVAL_MAX := 3.0
const NIGHT_GOD_SPAWN_INTERVAL_STEP := 0.5
const NIGHT_GOD_SPEED_FACTOR := 0.5
const NIGHT_GOD_HP_MULTIPLIER := 100.0

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
# Gli oggetti distruttibili (alberi, panchine, ecc.) restano ben visibili
# anche quando sfumano per non coprire il player: solo un'attenuazione
# leggera (90% di opacità), non la quasi-invisibilità usata per i muri
# (molto più grandi e quindi molto più invasivi se restano opachi).
const OBJECT_FADE_TRANSPARENCY := 0.10
# La casa resta più visibile dei muri quando sfuma (65% invece del 15%): è
# l'elemento a cui il player deve tornare, vale la pena riconoscerla anche
# mentre è tra telecamera e player.
const HOUSE_FADE_TRANSPARENCY := 0.35
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

var storm_active := false
var storm_full_closed := false
var storm_elapsed := 0.0
var _time_outside := 0.0
var _storm_mesh: Node3D = null

var in_darkness := false
var _night_god_spawn_timer := 0.0
var _night_gods: Array = []

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
	_apply_screen_adjustment()
	GameSettings.changed.connect(_apply_screen_adjustment)
	hud.update_money(money)
	for obj in get_tree().get_nodes_in_group("park_objects"):
		obj.destroyed.connect(_on_object_destroyed.bind(obj))
	_build_spawn_points()
	_setup_storm()
	_start_zone()

# Luminosità/contrasto regolabili dalle Impostazioni, applicati tramite le
# proprietà native di Environment (niente shader custom): si aggiornano in
# tempo reale mentre il pannello Impostazioni resta aperto durante il gioco.
func _apply_screen_adjustment() -> void:
	var env: Environment = $Environment.environment
	env.adjustment_enabled = true
	env.adjustment_brightness = GameSettings.brightness
	env.adjustment_contrast = GameSettings.contrast

# Terreno/muri/cielo cambiano di netto allo scenario della zona attuale
# (mai gradualmente: solo l'aspetto di alberi e nemici transita, vedi
# _scenario_data_for_spawn()). La casa esterna non è mai toccata da
# questo sistema, resta quella scelta dal player con l'Armadio.
#
# Solo il Parco (scenario 0) ha già una vera texture per terreno/muri e un
# cielo fotografico al posto del gradiente procedurale: Bosco e Palude
# restano con l'aspetto a tinta unita di sempre, non ancora rifatti.
const PARCO_SKY_PANORAMA := preload("res://assets/textures/sky/skybox-day.png")
var _parco_ground_noise_tex: NoiseTexture2D = null
var _parco_wall_noise_tex: NoiseTexture2D = null

func _parco_ground_texture() -> NoiseTexture2D:
	if _parco_ground_noise_tex == null:
		var noise := FastNoiseLite.new()
		noise.seed = 1
		noise.frequency = 0.06
		noise.fractal_octaves = 3
		_parco_ground_noise_tex = NoiseTexture2D.new()
		_parco_ground_noise_tex.seamless = true
		_parco_ground_noise_tex.width = 256
		_parco_ground_noise_tex.height = 256
		_parco_ground_noise_tex.noise = noise
	return _parco_ground_noise_tex

func _parco_wall_texture() -> NoiseTexture2D:
	if _parco_wall_noise_tex == null:
		var noise := FastNoiseLite.new()
		noise.seed = 2
		noise.frequency = 0.09
		noise.fractal_octaves = 3
		_parco_wall_noise_tex = NoiseTexture2D.new()
		_parco_wall_noise_tex.seamless = true
		_parco_wall_noise_tex.width = 256
		_parco_wall_noise_tex.height = 256
		_parco_wall_noise_tex.noise = noise
	return _parco_wall_noise_tex

func _apply_scenario_visuals() -> void:
	var idx := Scenarios.scenario_index_for_zone(zone)
	var data: Dictionary = Scenarios.scenario_data(idx)
	var is_parco := idx == 0

	var floor_mat := $Floor/MeshInstance3D.get_surface_override_material(0) as StandardMaterial3D
	floor_mat.albedo_color = data.floor_color
	if is_parco:
		floor_mat.albedo_texture = _parco_ground_texture()
		floor_mat.uv1_scale = Vector3(24.0, 24.0, 1.0)
	else:
		floor_mat.albedo_texture = null
		floor_mat.uv1_scale = Vector3.ONE

	for occ in _wall_occluders:
		var wall_mat := (occ.mesh as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		var new_color: Color = data.wall_color
		# Non tocca l'alpha: potrebbe essere a metà di una dissolvenza per
		# occlusione (_update_occlusion_fade), non è compito nostro azzerarla.
		new_color.a = wall_mat.albedo_color.a
		wall_mat.albedo_color = new_color
		if is_parco:
			wall_mat.albedo_texture = _parco_wall_texture()
			wall_mat.uv1_scale = Vector3(10.0, 3.0, 1.0)
		else:
			wall_mat.albedo_texture = null
			wall_mat.uv1_scale = Vector3.ONE

	var env: Environment = $Environment.environment
	if is_parco:
		if not (env.sky.sky_material is PanoramaSkyMaterial):
			var pano := PanoramaSkyMaterial.new()
			pano.panorama = PARCO_SKY_PANORAMA
			env.sky.sky_material = pano
	else:
		if not (env.sky.sky_material is ProceduralSkyMaterial):
			env.sky.sky_material = ProceduralSkyMaterial.new()
		var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
		sky_mat.sky_top_color = data.sky_top_color
		sky_mat.sky_horizon_color = data.sky_horizon_color
		sky_mat.ground_bottom_color = data.ground_bottom_color
		sky_mat.ground_horizon_color = data.ground_horizon_color
	env.ambient_light_color = data.ambient_light_color
	env.ambient_light_energy = data.ambient_light_energy

# Indice dello scenario da usare per il prossimo albero/nemico/oggetto che
# nasce: durante la finestra di transizione (le ultime zone prima del
# checkpoint), ogni nascita tira a sorte in modo indipendente se usare già
# lo scenario successivo, con probabilità crescente zona per zona — così il
# passaggio è graduale e "misto" invece che a scatti.
func _scenario_index_for_spawn() -> int:
	var current_idx := Scenarios.scenario_index_for_zone(zone)
	var p := Scenarios.transition_progress(zone)
	if p > 0.0 and randf() < p:
		return Scenarios.next_scenario_index_for_zone(zone)
	return current_idx

func _scenario_data_for_spawn() -> Dictionary:
	return Scenarios.scenario_data(_scenario_index_for_spawn())

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
	wall_mat.albedo_color = Color(CheckpointData.house_wall_color) if CheckpointData.house_wall_color != "" else tier.wall_color
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
	if CheckpointData.house_door_color != "":
		door_own_mat.albedo_color = Color(CheckpointData.house_door_color)
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
		roof_mat.albedo_color = Color(CheckpointData.house_roof_color) if CheckpointData.house_roof_color != "" else tier.roof_color
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
		_fade_toward(m, house_blocking, delta, HOUSE_FADE_TRANSPARENCY)

	for obj in get_tree().get_nodes_in_group("park_objects"):
		if not is_instance_valid(obj) or bool(obj.get("low_object")):
			continue
		var obj3d := obj as Node3D
		var obj_blocking: bool = _segment_hits_sphere(p0, p1, obj3d.global_position, OBJECT_OCCLUDER_RADIUS + PLAYER_VISIBILITY_MARGIN_OBJECT)
		if not obj_blocking and not obj.has_meta("occluder_meshes"):
			continue
		for m in _object_occluder_meshes(obj):
			_fade_toward(m, obj_blocking, delta, OBJECT_FADE_TRANSPARENCY)

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

func _fade_toward(mesh_inst: MeshInstance3D, blocking: bool, delta: float, fade_transparency: float = OCCLUDER_FADE_TRANSPARENCY) -> void:
	if mesh_inst == null:
		return
	var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	var target: float = 1.0 - fade_transparency if blocking else 1.0
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
		player.attack_knockback = 0.0
		return
	var wups: Dictionary = CheckpointData.weapon_upgrades.get(wid, {})
	var def: Dictionary = MeleeWeapons.WEAPONS[wid]
	weapon_name = String(def.label)
	player.attack_damage = MeleeWeapons.final_damage(wid, wups)
	player.attack_cooldown = MeleeWeapons.final_cooldown(wid, wups)
	player.attack_reach_mult = MeleeWeapons.final_reach_mult(wid, wups)
	player.attack_knockback = MeleeWeapons.final_knockback(wid, wups)
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
	_apply_scenario_visuals()
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
	_update_storm(delta)

	if zone_transitioning or player.dead:
		if zone_transitioning and not player.dead:
			var dist_to_house := player.global_position.distance_to(HOUSE_DOOR_POS)
			hud.set_house_button_visible(dist_to_house <= HOUSE_INTERACT_RANGE)
		else:
			hud.set_house_button_visible(false)
		hud.set_throw_buttons_visible(false)
		return

	# Il buio del tutto chiuso senza aver ripulito la zona lascia comunque
	# rifugiarsi in casa (vedi _on_storm_fully_closed()): la zona passa,
	# solo con meno soldi per i nemici non uccisi.
	if storm_full_closed:
		var dist_to_house2 := player.global_position.distance_to(HOUSE_DOOR_POS)
		hud.set_house_button_visible(dist_to_house2 <= HOUSE_INTERACT_RANGE)
	else:
		hud.set_house_button_visible(false)
	hud.set_throw_buttons_visible(not CheckpointData.owned_throwables.is_empty())
	_update_spawn_points()

	if zone_enemies_spawned < zone_enemies_total:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and zone_enemies_alive < MAX_CONCURRENT:
			_spawn_enemy()

# Ancora logica per posizione (casa) e raggio attuale, usata da
# is_in_darkness, chiusura completa, nemici e posizione degli dei della
# notte. Tutte le distanze contano solo sul piano orizzontale
# (_horizontal_distance_to_house), mai sulla quota di player/telecamera.
func _setup_storm() -> void:
	_storm_mesh = Node3D.new()
	add_child(_storm_mesh)
	_storm_mesh.global_position = $HouseExterior.global_position

# Distanza sul solo piano orizzontale (XZ) dalla casa: la tempesta è una
# circonferenza sul terreno, non una sfera, quindi l'altezza di player o
# telecamera non deve mai contare nel determinare se si è "fuori".
func _horizontal_distance_to_house(pos: Vector3) -> float:
	var house_pos: Vector3 = _storm_mesh.global_position
	return Vector2(pos.x - house_pos.x, pos.z - house_pos.z).length()

func _random_night_god_interval() -> float:
	var steps: int = int(round((NIGHT_GOD_SPAWN_INTERVAL_MAX - NIGHT_GOD_SPAWN_INTERVAL_MIN) / NIGHT_GOD_SPAWN_INTERVAL_STEP))
	return NIGHT_GOD_SPAWN_INTERVAL_MIN + float(randi() % (steps + 1)) * NIGHT_GOD_SPAWN_INTERVAL_STEP

func _storm_safe_radius() -> float:
	return HouseLight.radius_for_level(CheckpointData.house_light_level)

func _storm_progress() -> float:
	return clamp(storm_elapsed / STORM_DURATION, 0.0, 1.0)

func _current_storm_radius() -> float:
	return lerp(STORM_START_RADIUS, _storm_safe_radius(), _storm_progress())

# Vignetta a schermo centrata sulla casa, calcolata con un vero raycast dal
# piano di terra invece di un cerchio 2D approssimato: per ogni pixel, lo
# shader ricostruisce a quale punto del terreno corrisponde (intersecando il
# raggio telecamera-pixel col piano orizzontale all'altezza della casa) e lo
# confronta con la vera distanza orizzontale dalla casa — lo stesso identico
# calcolo già usato per la meccanica (_horizontal_distance_to_house), non
# un'approssimazione. Questo garantisce che il confine visibile coincida
# sempre esattamente con quello reale: il player non vede mai il buio finché
# non lo ha davvero superato, qualunque sia la sua posizione o distanza
# dalla casa, e il cerchio resta corretto anche visto da lontano.
#
# I quattro raggi (uno per angolo dello schermo) bastano perché per una
# proiezione prospettica la direzione del raggio varia linearmente con la
# posizione a schermo: lo shader interpola bilinearmente tra i quattro per
# ottenere la direzione esatta di ogni pixel, senza bisogno di passare le
# matrici di camera/proiezione.
func _update_house_vignette(radius: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var ray_tl: Vector3 = cam.project_ray_normal(Vector2(0.0, 0.0))
	var ray_tr: Vector3 = cam.project_ray_normal(Vector2(vp.x, 0.0))
	var ray_bl: Vector3 = cam.project_ray_normal(Vector2(0.0, vp.y))
	var ray_br: Vector3 = cam.project_ray_normal(Vector2(vp.x, vp.y))
	var house_pos: Vector3 = _storm_mesh.global_position
	hud.set_house_vignette(cam.global_position, ray_tl, ray_tr, ray_bl, ray_br, Vector2(house_pos.x, house_pos.z), house_pos.y, radius)

func _update_storm(delta: float) -> void:
	# Deve funzionare (e potersi testare) anche in Modalità Creator: l'unico
	# vero blocco è il player morto. In Creator il player resta comunque
	# invincibile (vedi Player.take_damage), quindi gli dei della notte non
	# possono davvero ucciderlo lì, ma il buio/la vignetta/il loro
	# comportamento restano visibili e testabili.
	if player.dead:
		return
	if not storm_active:
		_time_outside += delta
		if _time_outside >= STORM_DELAY:
			_start_storm()
		return

	storm_elapsed += delta
	var radius: float = _current_storm_radius()
	_update_house_vignette(radius)
	if not storm_full_closed and storm_elapsed >= STORM_DURATION:
		storm_full_closed = true
		_on_storm_fully_closed()

	var now_in_darkness: bool = _horizontal_distance_to_house(player.global_position) > radius
	if now_in_darkness and not in_darkness:
		_enter_darkness()
	elif not now_in_darkness and in_darkness:
		_exit_darkness()
	if in_darkness:
		_update_night_gods(delta)

func _start_storm() -> void:
	if storm_active:
		return
	storm_active = true
	storm_elapsed = 0.0
	hud.set_house_vignette_visible(true)
	hud.show_storm_warning()

# Il buio ha chiuso del tutto senza che la zona sia stata ripulita: i nemici
# ancora vivi (e quelli che nasceranno da qui in avanti, vedi _spawn_enemy)
# "sentono" il player ovunque nell'arena, per forzare lo scontro invece di
# lasciare che il player li ignori — ma non è obbligatorio ucciderli: si può
# comunque correre a casa (vedi _enter_house_anytime), la zona passa lo
# stesso, solo con meno soldi guadagnati per i nemici non uccisi.
func _on_storm_fully_closed() -> void:
	if zone_enemies_alive <= 0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.detect_range_override = STORM_ENEMY_DETECT_OVERRIDE

# Il player è appena finito nel buio vero e proprio (oltre il raggio sicuro
# attuale, che sia ancora in restringimento o già fermo al minimo dato dalla
# luce della casa): niente morte istantanea, solo la minaccia degli dei
# della notte (vedi _update_night_gods/_spawn_night_god).
func _enter_darkness() -> void:
	in_darkness = true
	_night_god_spawn_timer = _random_night_god_interval()

# Rientrati nel raggio sicuro (o in casa): il buio torna innocuo, gli dei
# della notte che stavano inseguendo il player si dissolvono subito.
func _exit_darkness() -> void:
	in_darkness = false
	for god in _night_gods:
		if is_instance_valid(god):
			god.queue_free()
	_night_gods.clear()

func _update_night_gods(delta: float) -> void:
	_night_god_spawn_timer -= delta
	if _night_god_spawn_timer <= 0.0:
		_night_god_spawn_timer = _random_night_god_interval()
		_spawn_night_god()

# Nasce sempre sul bordo della bolla di visuale del player, dal lato rivolto
# verso casa: si troverà così sempre di fronte al player, che dovrà scartare
# di lato invece di poter semplicemente correre in linea retta verso casa.
func _spawn_night_god() -> void:
	var house_pos: Vector3 = _storm_mesh.global_position
	var dir_to_house: Vector3 = house_pos - player.global_position
	dir_to_house.y = 0.0
	if dir_to_house.length() < 0.01:
		dir_to_house = Vector3(0, 0, 1)
	dir_to_house = dir_to_house.normalized()

	var god := NightGodScene.instantiate()
	add_child(god)
	god.global_position = player.global_position + dir_to_house * NIGHT_GOD_SPAWN_DISTANCE
	god.target = player
	god.speed = player.BASE_SPEED * player.speed_mult * NIGHT_GOD_SPEED_FACTOR
	god.max_hp = player.max_hp * NIGHT_GOD_HP_MULTIPLIER
	god.hp = god.max_hp
	_night_gods.append(god)

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
	if storm_full_closed:
		enemy.detect_range_override = STORM_ENEMY_DETECT_OVERRIDE
	var sdata := _scenario_data_for_spawn()
	enemy.apply_color_override(sdata.enemy_colors.get(archetype_id, EnemyArchetypes.DATA[archetype_id].color))
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
	# La tempesta/buio deve comparire anche in Modalità Creator (per poterla
	# testare), a differenza di checkpoint/classifica che restano isolati
	# dalle partite normali.
	_start_storm()
	if not DevMode.enabled:
		if CheckpointData.is_checkpoint_zone(zone):
			CheckpointData.save_checkpoint(zone, int(money), materials, upgrades)
		# La classifica riflette l'ultima zona davvero completata, non quella
		# in corso: qui "zone" è ancora il numero appena superato (l'incremento
		# avviene solo dopo, in _go_home()/_skip_home()).
		Leaderboard.submit(zone, int(money))
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
	if not zone_transitioning and storm_full_closed:
		_force_home_after_storm()
		return
	CheckpointData.set_live_state(zone, int(money), materials, upgrades)
	get_tree().change_scene_to_file("res://scenes/Home.tscn")

# Rifugio forzato: il buio ha chiuso del tutto e la zona non era stata
# ripulita, ma il player è comunque riuscito a rientrare in casa. La zona
# passa lo stesso (stesso trattamento di _complete_zone(), checkpoint e
# classifica compresi), semplicemente con meno soldi guadagnati per i
# nemici non uccisi — niente pannello di scelta, il player ha già scelto
# correndo a casa.
func _force_home_after_storm() -> void:
	zone_transitioning = true
	if not DevMode.enabled:
		if CheckpointData.is_checkpoint_zone(zone):
			CheckpointData.save_checkpoint(zone, int(money), materials, upgrades)
		Leaderboard.submit(zone, int(money))
	_go_home()

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
		var scenario_idx := _scenario_index_for_spawn()
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
		# apply_scenario_appearance/set_parco_visual toccano nodi @onready:
		# serve che l'oggetto sia già nella scena, quindi dopo add_child().
		if type_id == "albero":
			var tree_sdata: Dictionary = Scenarios.scenario_data(scenario_idx)
			obj.apply_scenario_appearance(tree_sdata.tree_trunk_color, tree_sdata.tree_foliage_color, tree_sdata.tree_shape)
		elif obj.has_method("set_parco_visual"):
			obj.set_parco_visual(scenario_idx == 0)
		obj.destroyed.connect(_on_object_destroyed.bind(obj))

const OBJECT_SPAWN_POINT_CLEARANCE := 3.5
# Margine minimo oltre l'ingombro reale della casa (_house_half_extents, già
# calcolato per tier/torri comprese): basta a evitare che un oggetto finisca
# incollato al muro (dove un nemico rischia di incastrarsi nell'angolo, es.
# un lampione appoggiato al muro), senza allontanare gli oggetti dalla casa
# più dello stretto necessario — la vera protezione contro l'incastro è la
# via di fuga di enemy.gd basata sulle normali di collisione reali, non
# questo margine, che resta solo un aiuto in più.
const HOUSE_OBJECT_CLEAR_MARGIN := 1.0

func _random_object_position() -> Vector3:
	var pos := Vector3.ZERO
	for attempt in range(10):
		var x := randf_range(-ARENA_HALF, ARENA_HALF)
		var z := randf_range(-ARENA_HALF, ARENA_HALF)
		pos = Vector3(x, 0.0, z)
		if pos.length() > OBJECT_CLEAR_RADIUS and not _near_house(pos) and not _near_spawn_point(pos):
			return pos
	return pos

# A differenza del vecchio controllo (un raggio fisso dalla sola porta),
# usa l'ingombro reale della casa nel tier attuale: corretto a qualunque
# dimensione la casa cresca, torri comprese.
func _near_house(pos: Vector3) -> bool:
	var house_pos: Vector3 = $HouseExterior.global_position
	var half_w: float = _house_half_extents.x + HOUSE_OBJECT_CLEAR_MARGIN
	var half_d: float = _house_half_extents.z + HOUSE_OBJECT_CLEAR_MARGIN
	return absf(pos.x - house_pos.x) < half_w and absf(pos.z - house_pos.z) < half_d

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
		# La classifica torna anch'essa ai valori dell'ultimo checkpoint (0 se
		# la zona 50 non è ancora stata superata): CheckpointData.zone/money
		# sono già stati riportati indietro dalla load_checkpoint() qui sopra.
		Leaderboard.submit(CheckpointData.zone, int(CheckpointData.money))
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
