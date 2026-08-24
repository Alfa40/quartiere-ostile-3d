extends Node3D

# Seconda parte del tutorial giocabile obbligatorio: un npc aggredito da
# salvare (armi da fuoco), un'orda da fermare con una granata, e
# l'accompagnamento a casa dell'npc, che dona la tenda e il banco della
# casa (già sempre posseduto, quindi solo narrativo).

const EnemyScene := preload("res://scenes/Enemy.tscn")
const Firearms := preload("res://scripts/firearms.gd")
const Throwables := preload("res://scripts/throwables.gd")

const NPC_HOUSE_POS := Vector3(0, 0, -20)
const HORDE_CENTER := Vector3(3, 0, -3)
const HORDE_ARCHETYPES := ["balordo", "nervoso", "balordo", "nervoso"]
const HELP_RANGE := 2.5

# Stesso riscontro visivo del tasto "Lancia" del gioco vero (vedi hud.gd):
# acceso quando l'arma da lancio è armata, spento quando è a riposo.
const THROW_ARM_IDLE_MODULATE := Color(0.65, 0.65, 0.68, 1.0)
const THROW_ARM_ACTIVE_MODULATE := Color(1.25, 1.05, 0.55, 1.0)
const THROW_ARM_DIAMETER := 130.0

@onready var hud = $HUD
@onready var player = $Player
@onready var touch_controls = $HUD/TouchControls
@onready var throw_arm_button: Button = $HUD/ThrowArmButton
@onready var npc = $Npc
@onready var npc_house_door: Area3D = $NpcHouseDoorTrigger

# "rescue" -> "help" -> "horde" -> "escort" -> "arrived" -> "done"
var stage := "rescue"
var _attackers_alive := 0
var _horde_alive := 0

func _ready() -> void:
	player.hp_changed.connect(hud.on_player_hp_changed)
	throw_arm_button.pressed.connect(_on_throw_arm_pressed)
	throw_arm_button.modulate = THROW_ARM_IDLE_MODULATE
	npc_house_door.body_entered.connect(_on_npc_house_entered)
	_apply_firearm()

	hud.set_objective("Un npc è nei guai! Sconfiggi i nemici che lo stanno aggredendo")
	hud.set_progress(1, 5)

	for i in range(2):
		var e = EnemyScene.instantiate()
		e.position = npc.position + Vector3(1.2 if i == 0 else -1.2, 0, 1.2)
		add_child(e)
		e.configure(1.0, 1.0, 1.0, 1.0, "balordo")
		e.died.connect(_on_attacker_died)
		_attackers_alive += 1

func _apply_firearm() -> void:
	touch_controls.aim_enabled = true
	var fid: String = CheckpointData.equipped_firearm
	if fid == "" or not Firearms.WEAPONS.has(fid):
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

# Munizioni infinite durante il tutorial: niente da imparare sulla scorta
# qui, solo su come mirare/sparare/lanciare.
func get_firearm_reserve_ammo(_fid: String) -> int:
	return 999

func consume_firearm_reserve_ammo(_fid: String, _amount: int) -> void:
	pass

func get_throwable_reserve_ammo(_tid: String) -> int:
	return 999

func consume_throwable_reserve_ammo(_tid: String, _amount: int) -> void:
	pass

func _on_attacker_died() -> void:
	_attackers_alive -= 1
	if _attackers_alive <= 0:
		stage = "rescue_pausing"
		# Pausa di 1s a fine passo: lascia il tempo di leggere/ambientarsi.
		await get_tree().create_timer(1.0).timeout
		stage = "help"
		hud.set_objective("Avvicinati all'npc per aiutarlo ad alzarsi")
		hud.set_progress(2, 5)

func _process(_delta: float) -> void:
	if stage == "help" and player.global_position.distance_to(npc.global_position) <= HELP_RANGE:
		stage = "help_pausing"
		_delayed_start_horde()
	if throw_arm_button.visible:
		throw_arm_button.modulate = THROW_ARM_ACTIVE_MODULATE if player.throw_armed else THROW_ARM_IDLE_MODULATE
	_update_throw_arm_button_position()

# Stessa logica di hud.gd: il tasto sta sopra il joystick di mira, centrato
# sul suo asse x, invece che sovrapposto (come accadeva con una posizione
# fissa che non teneva conto di dove il joystick di mira viene disegnato).
func _update_throw_arm_button_position() -> void:
	if not touch_controls.aim_enabled:
		return
	var aim_pos: Vector2 = touch_controls.aim_base_pos
	var gap := 16.0
	var joy_top: float = aim_pos.y - touch_controls.JOY_RADIUS
	throw_arm_button.offset_left = aim_pos.x - THROW_ARM_DIAMETER * 0.5
	throw_arm_button.offset_right = aim_pos.x + THROW_ARM_DIAMETER * 0.5
	throw_arm_button.offset_bottom = joy_top - gap
	throw_arm_button.offset_top = throw_arm_button.offset_bottom - THROW_ARM_DIAMETER

func _delayed_start_horde() -> void:
	await get_tree().create_timer(1.0).timeout
	_start_horde()

func _start_horde() -> void:
	stage = "horde"
	hud.set_objective("L'npc ti dà una granata! Armala col tasto \"Lancia\" e lanciala sull'orda in arrivo")
	hud.set_progress(3, 5)
	_give_grenade()
	throw_arm_button.visible = true
	for i in range(HORDE_ARCHETYPES.size()):
		var e = EnemyScene.instantiate()
		var angle := TAU * float(i) / float(HORDE_ARCHETYPES.size())
		e.position = HORDE_CENTER + Vector3(cos(angle), 0, sin(angle)) * 1.6
		add_child(e)
		e.configure(1.0, 1.0, 1.0, 1.0, HORDE_ARCHETYPES[i])
		e.died.connect(_on_horde_died)
		_horde_alive += 1

func _give_grenade() -> void:
	var tid := "granata"
	var tups := {}
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

func _on_throw_arm_pressed() -> void:
	if player.active_sticky_grenade != null and is_instance_valid(player.active_sticky_grenade):
		player.arm_throw()
		return
	if player.throw_armed:
		player.throw_armed = false
		return
	player.arm_throw()

func _on_horde_died() -> void:
	_horde_alive -= 1
	if _horde_alive <= 0:
		stage = "horde_pausing"
		throw_arm_button.visible = false
		# Pausa di 1s a fine passo: lascia il tempo di leggere/ambientarsi.
		await get_tree().create_timer(1.0).timeout
		_start_escort()

func _start_escort() -> void:
	stage = "escort"
	hud.set_objective("Segui l'npc: state andando verso casa sua")
	hud.set_progress(4, 5)
	npc.reached_target.connect(_on_npc_arrived)
	npc.start_walking_to(NPC_HOUSE_POS)

func _on_npc_arrived() -> void:
	stage = "arriving_pausing"
	hud.set_progress(5, 5)
	hud.set_objective("Siete arrivati!")
	# Pausa di 1s a fine passo: lascia il tempo di leggere/ambientarsi.
	await get_tree().create_timer(1.0).timeout
	stage = "arrived"
	hud.set_objective("Entra in casa con l'npc: là vi aspettano una tenda e un banco tutti per te")

func _on_npc_house_entered(body: Node3D) -> void:
	if stage != "arrived" or not body.is_in_group("player"):
		return
	stage = "done"
	TutorialProgress.set_stage("house2")
	get_tree().change_scene_to_file("res://scenes/IntroHouse2.tscn")
