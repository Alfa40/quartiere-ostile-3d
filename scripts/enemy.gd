extends CharacterBody3D

const BASE_SPEED := 3.2
const BASE_MAX_HP := 40.0
const BASE_ATTACK_DAMAGE := 4.0
const BASE_ATTACK_COOLDOWN := 1.0
const MIN_ATTACK_COOLDOWN := 0.2
const ATTACK_RANGE := 1.6
const GRAVITY := 20.0

const RANGED_PREFERRED := 8.0
const RANGED_MAX := 10.0
const RANGED_PROJECTILE_SPEED := 13.0

const DETECT_RANGE := 20.0
const DETECT_RANGE_RANGED := 16.0

const ProjectileScene := preload("res://scenes/Projectile.tscn")
const EnemyArchetypes := preload("res://scripts/enemy_archetypes.gd")

# Un modello Kenney diverso per ogni tipo di nemico (stesso stile/rig/
# animazioni del player, solo silhouette diversa), così si distinguono anche
# senza guardare il colore. Tutti condividono un unico set di animazioni
# (idle/walk/attack-melee-left/right) e la stessa scala/rotazione del player.
const CHARACTER_MODELS := {
	"character-male-b": preload("res://assets/models/characters/character-male-b.glb"),
	"character-male-c": preload("res://assets/models/characters/character-male-c.glb"),
	"character-male-d": preload("res://assets/models/characters/character-male-d.glb"),
	"character-male-e": preload("res://assets/models/characters/character-male-e.glb"),
	"character-male-f": preload("res://assets/models/characters/character-male-f.glb"),
	"character-female-a": preload("res://assets/models/characters/character-female-a.glb"),
	"character-female-b": preload("res://assets/models/characters/character-female-b.glb"),
	"character-female-c": preload("res://assets/models/characters/character-female-c.glb"),
	"character-female-d": preload("res://assets/models/characters/character-female-d.glb"),
	"character-female-f": preload("res://assets/models/characters/character-female-f.glb"),
}
const ARCHETYPE_MODEL := {
	"balordo": "character-male-f",
	"nervoso": "character-female-b",
	"imprevedibile": "character-female-a",
	"bruto": "character-male-b",
	"tiratore": "character-female-c",
}
# Nello scenario indicato, l'archetipo "balordo" (il più comune, sempre
# presente) usa un altro personaggio dello stesso pacchetto Mini
# Characters invece di quello di default, per dare un colpo d'occhio
# diverso zona per zona oltre al semplice ricolorare (vedi
# apply_scenario_model, chiamata da main.gd dopo configure()). Gli altri
# archetipi restano invariati in ogni scenario.
const SCENARIO_MODEL_OVERRIDE := {
	1: {"balordo": "character-male-d"},
	2: {"balordo": "character-female-d"},
	3: {"balordo": "character-male-e"},
	4: {"balordo": "character-female-f"},
	5: {"balordo": "character-male-c"},
}
const MODEL_ROTATION_Y := 180.0
const MODEL_SCALE := 1.8
const ATTACK_ANIMS := ["attack-melee-left", "attack-melee-right"]

signal died

@onready var facing_pivot: Node3D = $FacingPivot
@onready var visual_root: Node3D = $FacingPivot/VisualRoot
var anim_player: AnimationPlayer = null
var body_mesh: MeshInstance3D = null

var speed := BASE_SPEED
var max_hp := BASE_MAX_HP
var hp := BASE_MAX_HP
var attack_damage := BASE_ATTACK_DAMAGE
var attack_cooldown := BASE_ATTACK_COOLDOWN
var radius_mult := 1.0
var behavior := "steady"

var attack_cooldown_timer := 0.0
var dead := false
var player: Node3D = null

var erratic_state := "charge"
var erratic_timer := 0.0
# Verso di "sidestep" scelto una volta sola all'inizio dello stato (non ad
# ogni frame, vedi _compute_move_dir): un tiro a sorte ripetuto ogni frame
# farebbe rimbalzare la direzione desiderata da un lato all'altro decine di
# volte al secondo, facendo vibrare il nemico invece di scartare di lato in
# modo pulito.
var erratic_sidestep_sign := 1.0

var aware := false
var wander_dir := Vector3.ZERO
var wander_timer := 0.0

var stun_timer := 0.0
var blind_timer := 0.0

# -1 = usa il raggio di rilevamento normale (DETECT_RANGE/DETECT_RANGE_RANGED);
# usato dal tutorial per far restare "addormentati" i nemici isolati finché
# il player non gli arriva davvero vicino, invece di farli scattare da lontano.
var detect_range_override := -1.0

# Rilevamento "incastrato": senza un vero pathfinding, un nemico che punta
# dritto verso il player può restare bloccato contro un ostacolo sottile
# lungo il percorso diretto (es. il palo di un lampione) — se dopo
# STUCK_CHECK_INTERVAL secondi di tentativo di movimento la posizione non è
# avanzata a sufficienza, si spinge di lato per qualche istante finché non
# si libera, invece di restarci incollato per sempre.
const STUCK_CHECK_INTERVAL := 0.5
const STUCK_MOVE_THRESHOLD := 0.35
const UNSTUCK_DURATION := 0.7
var _stuck_check_timer := STUCK_CHECK_INTERVAL
var _stuck_check_pos := Vector3.ZERO
# Direzione desiderata registrata insieme a _stuck_check_pos: serve a capire
# se la mancata distanza percorsa è colpa di un vero ostacolo o solo del
# comportamento "erratic" che inverte volontariamente rotta (inseguimento
# poi ritirata) — vedi _resolve_move_dir().
var _stuck_check_dir := Vector3.ZERO
var _unstuck_timer := 0.0
var _unstuck_dir := Vector3.ZERO
# Quanti tentativi di sblocco consecutivi sono già falliti (si azzera appena
# il nemico torna a muoversi normalmente): usato per allungare il tempo
# concesso al tentativo successivo e per alternare la rotazione della
# direzione di fuga, così un angolo stretto (es. tra il muro della casa e
# il palo di un lampione) non fa ripetere in loop la stessa mossa già
# fallita.
var _stuck_attempts := 0

# Spinta temporanea dalle armi bianche più pesanti (vedi
# MeleeWeapons.KNOCKBACK_CATEGORIES): un vettore che si aggiunge alla
# velocità normale e si esaurisce da solo per attrito, invece di sostituire
# del tutto il comportamento dell'IA (il nemico continua a inseguire/
# attaccare, solo spinto all'indietro nel frattempo).
const KNOCKBACK_FRICTION := 12.0
var knockback_velocity := Vector3.ZERO

func apply_knockback(direction: Vector3, force: float) -> void:
	if force <= 0.0 or dead:
		return
	var dir := direction
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
	knockback_velocity = dir * force

func _consume_knockback(delta: float) -> void:
	if knockback_velocity.length() > 0.01:
		velocity.x += knockback_velocity.x
		velocity.z += knockback_velocity.z
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, KNOCKBACK_FRICTION * delta)
	else:
		knockback_velocity = Vector3.ZERO

func apply_stun(duration: float) -> void:
	stun_timer = max(stun_timer, duration)

func apply_blind(duration: float) -> void:
	blind_timer = max(blind_timer, duration)

func _ready() -> void:
	add_to_group("enemies")
	call_deferred("_find_player")

func configure(hp_mult: float, dmg_mult: float, speed_mult: float, cooldown_seconds: float, archetype_id: String = "balordo") -> void:
	var arch: Dictionary = EnemyArchetypes.DATA.get(archetype_id, EnemyArchetypes.DATA["balordo"])
	behavior = arch.behavior
	radius_mult = arch.radius_mult
	scale = Vector3.ONE * radius_mult
	max_hp = BASE_MAX_HP * arch.hp_mult * hp_mult
	hp = max_hp
	attack_damage = BASE_ATTACK_DAMAGE * arch.damage_mult * dmg_mult
	speed = BASE_SPEED * arch.speed_mult * speed_mult
	attack_cooldown = max(cooldown_seconds * arch.cooldown_mult, MIN_ATTACK_COOLDOWN)
	_instantiate_model(ARCHETYPE_MODEL.get(archetype_id, "character-male-f"))
	_apply_color(arch.color)

func _instantiate_model(model_name: String) -> void:
	for c in visual_root.get_children():
		c.queue_free()
	var inst: Node3D = CHARACTER_MODELS[model_name].instantiate()
	visual_root.add_child(inst)
	# Stessa correzione del player: il modello glTF ha "avanti" a +Z, Godot
	# a -Z, e la scala nativa Kenney va ingrandita per riempire la capsula di
	# collisione del nemico (identica a quella del player: raggio 0.5, altezza
	# 1.8).
	inst.rotation_degrees = Vector3(0, MODEL_ROTATION_Y, 0)
	inst.scale = Vector3.ONE * MODEL_SCALE
	anim_player = inst.get_node("AnimationPlayer")
	# Il nome del nodo con lo scheletro può differire da model_name (Godot lo
	# rinomina se collide con un altro nodo già esistente nell'albero, es.
	# istanziando due volte lo stesso personaggio): lo cerchiamo per struttura
	# (ha un figlio Skeleton3D) invece che per nome esatto.
	var char_node: Node = null
	for c in inst.get_children():
		if c.has_node("Skeleton3D"):
			char_node = c
			break
	body_mesh = char_node.get_node("Skeleton3D/body-mesh")

# Usata da main.gd per applicare il colore dello scenario attuale (o, in
# transizione, di quello successivo) al posto del colore fisso
# dell'archetipo: va chiamata dopo configure(), che la sovrascriverebbe.
func apply_color_override(color: Color) -> void:
	_apply_color(color)

# Usata da main.gd subito dopo configure(): se lo scenario indicato
# sostituisce il modello di questo archetipo, ri-istanzia col personaggio
# giusto (altrimenti non tocca nulla, resta quello di configure()). Va
# chiamata PRIMA di apply_color_override(), perché ri-istanziare cambia
# body_mesh: applicare il colore prima colorerebbe il modello vecchio,
# appena sostituito.
func apply_scenario_model(scenario_idx: int, archetype_id: String) -> void:
	var override_model: String = SCENARIO_MODEL_OVERRIDE.get(scenario_idx, {}).get(archetype_id, "")
	if override_model == "":
		return
	_instantiate_model(override_model)

# Solo il mesh del corpo (non della testa, che condivide la stessa texture
# "colormap" del modello Kenney): un duplicato del materiale originale così
# la texture resta intatta e il colore scelto si moltiplica sopra, invece di
# sostituirla con un colore piatto. Stesso approccio di player.gd.
func _apply_color(color: Color) -> void:
	if body_mesh == null:
		return
	var base_mat: StandardMaterial3D = body_mesh.mesh.surface_get_material(0)
	var mat: StandardMaterial3D = base_mat.duplicate()
	mat.albedo_color = color
	body_mesh.set_surface_override_material(0, mat)

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if dead or player == null or not is_instance_valid(player):
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		_consume_knockback(delta)
		move_and_slide()
		return

	if stun_timer > 0.0:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y -= GRAVITY * delta
		_consume_knockback(delta)
		move_and_slide()
		return

	if blind_timer > 0.0:
		blind_timer -= delta

	if not aware:
		var to_player_raw := player.global_position - global_position
		to_player_raw.y = 0.0
		var detect_range := DETECT_RANGE_RANGED if behavior == "ranged" else DETECT_RANGE
		if detect_range_override > 0.0:
			detect_range = detect_range_override
		if to_player_raw.length() <= detect_range and blind_timer <= 0.0:
			aware = true
		else:
			_process_wander(delta)
			if is_on_floor():
				velocity.y = 0.0
			else:
				velocity.y -= GRAVITY * delta
			_consume_knockback(delta)
			move_and_slide()
			_animate_body(delta)
			return

	if blind_timer > 0.0:
		_process_wander(delta)
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y -= GRAVITY * delta
		_consume_knockback(delta)
		move_and_slide()
		_animate_body(delta)
		return

	attack_cooldown_timer -= delta

	if behavior == "ranged":
		_process_ranged(delta)
	else:
		_process_melee(delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	_consume_knockback(delta)
	move_and_slide()
	_animate_body(delta)

func _process_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		if randf() < 0.25:
			wander_dir = Vector3.ZERO
			wander_timer = randf_range(0.8, 1.8)
		else:
			var angle := randf() * TAU
			wander_dir = Vector3(cos(angle), 0.0, sin(angle))
			wander_timer = randf_range(1.5, 3.5)

	var wander_speed := speed * 0.6
	if wander_dir.length() > 0.01:
		velocity.x = wander_dir.x * wander_speed
		velocity.z = wander_dir.z * wander_speed
		facing_pivot.look_at(facing_pivot.global_position + wander_dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)

func _resolve_move_dir(desired_dir: Vector3, delta: float) -> Vector3:
	if _unstuck_timer > 0.0:
		_unstuck_timer -= delta
		return _unstuck_dir
	_stuck_check_timer -= delta
	if _stuck_check_timer > 0.0:
		return desired_dir
	_stuck_check_timer = STUCK_CHECK_INTERVAL
	# Se la direzione desiderata è cambiata parecchio rispetto all'ultima
	# misurazione (es. il comportamento "erratic" che passa da inseguimento a
	# ritirata), la distanza percorsa non è un buon indicatore di blocco: è
	# la voluta inversione di rotta a "mangiarsi" lo spostamento netto, non
	# un ostacolo. In quel caso si riparte a misurare da qui invece di
	# scambiarlo per un incastro (che spingerebbe il nemico di lato a caso,
	# sommandosi all'oscillazione già voluta e facendolo sembrare rotto).
	var same_direction: bool = _stuck_check_dir.length() > 0.01 and desired_dir.length() > 0.01 and desired_dir.normalized().dot(_stuck_check_dir.normalized()) > 0.3
	# Poco progresso da solo non basta: capita anche senza alcun ostacolo
	# vero, es. orbitando proprio al limite del raggio d'attacco (si avvicina,
	# entra in "attacco", decelera, esce di nuovo). Richiediamo anche una
	# collisione reale nell'ultimo move_and_slide(), altrimenti non è un
	# incastro da sbloccare con una fuga laterale forzata.
	var stuck: bool = same_direction and get_slide_collision_count() > 0 and global_position.distance_to(_stuck_check_pos) < STUCK_MOVE_THRESHOLD
	_stuck_check_pos = global_position
	_stuck_check_dir = desired_dir
	if not stuck:
		_stuck_attempts = 0
		return desired_dir
	_stuck_attempts += 1
	_unstuck_dir = _compute_escape_dir(desired_dir)
	# Più tentativi falliti di fila, più a lungo si insiste nella direzione
	# scelta: dà il tempo di superare del tutto l'ostacolo invece di
	# ritornare subito a sbattere nello stesso punto.
	_unstuck_timer = UNSTUCK_DURATION * (1.0 + 0.5 * minf(float(_stuck_attempts - 1), 3.0))
	return _unstuck_dir

# Si allontana nella direzione delle normali di collisione reali dell'ultimo
# move_and_slide() invece di indovinare alla cieca un lato perpendicolare al
# bersaglio: molto più affidabile negli angoli stretti (es. tra il muro
# della casa e il palo di un lampione), dove un'unica ipotesi casuale può
# restare bloccata a sua volta. Se già un tentativo precedente non è
# bastato, ruota leggermente la direzione (alternando verso) invece di
# ripetere esattamente la stessa traiettoria appena fallita.
func _compute_escape_dir(desired_dir: Vector3) -> Vector3:
	var away := Vector3.ZERO
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var n: Vector3 = col.get_normal()
		n.y = 0.0
		away += n
	if away.length() > 0.01:
		away = away.normalized()
		if _stuck_attempts > 1:
			var angle := deg_to_rad(35.0 * float(_stuck_attempts - 1))
			away = away.rotated(Vector3.UP, angle if _stuck_attempts % 2 == 0 else -angle)
		return away
	# Nessuna collisione registrata nell'ultimo frame (raro): ripiega sulla
	# vecchia euristica, un passo laterale rispetto al bersaglio.
	var side := Vector3(-desired_dir.z, 0, desired_dir.x)
	return (side if randf() < 0.5 else -side).normalized()

func _process_melee(delta: float) -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var effective_range := ATTACK_RANGE * radius_mult

	if dist > effective_range:
		var move_dir := _resolve_move_dir(_compute_move_dir(to_player, delta), delta)
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		if move_dir.length() > 0.01:
			facing_pivot.look_at(facing_pivot.global_position + move_dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		facing_pivot.look_at(facing_pivot.global_position + to_player.normalized(), Vector3.UP)
		if attack_cooldown_timer <= 0.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
			attack_cooldown_timer = attack_cooldown
			_play_attack_swing()

func _compute_move_dir(to_player: Vector3, delta: float) -> Vector3:
	if behavior != "erratic":
		return to_player.normalized()

	erratic_timer -= delta
	if erratic_timer <= 0.0:
		var states := ["charge", "charge", "sidestep", "retreat"]
		erratic_state = states[randi() % states.size()]
		erratic_timer = randf_range(0.6, 1.4)
		if erratic_state == "sidestep":
			erratic_sidestep_sign = 1.0 if randi() % 2 == 0 else -1.0

	var to_player_dir := to_player.normalized()
	match erratic_state:
		"sidestep":
			var side := Vector3(-to_player_dir.z, 0, to_player_dir.x)
			return side * erratic_sidestep_sign
		"retreat":
			return -to_player_dir
		_:
			return to_player_dir

func _process_ranged(delta: float) -> void:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.01 else Vector3.FORWARD

	var move_dir := Vector3.ZERO
	if dist < RANGED_PREFERRED * 0.7:
		move_dir = -dir
	elif dist > RANGED_PREFERRED * 1.15:
		move_dir = dir
	if move_dir.length() > 0.01:
		move_dir = _resolve_move_dir(move_dir, delta)

	if move_dir.length() > 0.01:
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)

	facing_pivot.look_at(facing_pivot.global_position + dir, Vector3.UP)

	if attack_cooldown_timer <= 0.0 and dist <= RANGED_MAX and player.has_method("take_damage"):
		_fire_projectile(dir)
		attack_cooldown_timer = attack_cooldown
		_play_attack_swing()

func _fire_projectile(dir: Vector3) -> void:
	var proj = ProjectileScene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.2, 0) + dir * (0.8 * radius_mult)
	proj.travel = dir * RANGED_PROJECTILE_SPEED
	proj.damage = attack_damage
	proj.source = self

func _play_attack_swing() -> void:
	anim_player.play(ATTACK_ANIMS[randi() % ATTACK_ANIMS.size()])

# Un solo AnimationPlayer guida tutto lo scheletro: mentre un'animazione di
# attacco è in corso non va interrotta per tornare a cammino/riposo, che
# riprende da solo non appena l'attacco finisce (le clip di attacco non sono
# in loop, vedi ATTACK_ANIMS). Stesso approccio di player.gd.
func _animate_body(_delta: float) -> void:
	if anim_player.current_animation in ATTACK_ANIMS and anim_player.is_playing():
		return
	var horiz := Vector2(velocity.x, velocity.z).length()
	anim_player.play("walk" if horiz > 0.3 else "idle")

func take_damage(amount: float, _source = null) -> void:
	if dead:
		return
	hp = max(hp - amount, 0.0)
	if hp <= 0.0:
		dead = true
		died.emit()
		queue_free()
