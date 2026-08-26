extends Node3D

# Interno della prima casa del tutorial obbligatorio: la stessa casa in cui
# più avanti (dopo aver salvato l'npc) troveremo il banco della casa e la
# tenda donati dall'npc — qui però c'è già solo il banco delle armi da
# fuoco, con un menu ridotto che regala la Magnum: qui l'acquisto è sempre
# gratuito (non usa def.price_money/price_amount), a prescindere da quanto
# costi nel resto del gioco, così un futuro riequilibrio dei prezzi non può
# più rendere questo passo del tutorial impossibile da completare con i
# pochi soldi/materiali che si raccolgono prima di arrivarci.

const Firearms := preload("res://scripts/firearms.gd")
const FIREARM_ID := "magnum_44"
const INTERACT_RANGE := 2.2

@onready var player: Node3D = $Player
@onready var bench: Node3D = $WorkbenchArmiDaFuoco
@onready var interact_button: Button = $HUD/InteractButton
@onready var buy_panel: Control = $HUD/BuyPanel
@onready var info_label: Label = $HUD/BuyPanel/Box/InfoLabel
@onready var buy_button: Button = $HUD/BuyPanel/Box/BuyButton
@onready var hint_label: Label = $HUD/HintLabel
@onready var door_trigger: Area3D = $DoorTrigger

func _ready() -> void:
	interact_button.visible = false
	buy_panel.visible = false
	interact_button.pressed.connect(_open_buy_panel)
	buy_button.pressed.connect(_on_buy_pressed)
	$HUD/BuyPanel/Box/CloseButton.pressed.connect(_close_buy_panel)
	door_trigger.body_entered.connect(_on_door_entered)
	_refresh_buy_panel()

func _process(_delta: float) -> void:
	if buy_panel.visible:
		interact_button.visible = false
		return
	var near: bool = player.global_position.distance_to(bench.global_position) <= INTERACT_RANGE
	interact_button.visible = near

func _open_buy_panel() -> void:
	buy_panel.visible = true
	interact_button.visible = false
	_refresh_buy_panel()

func _close_buy_panel() -> void:
	buy_panel.visible = false

func _refresh_buy_panel() -> void:
	var def: Dictionary = Firearms.WEAPONS[FIREARM_ID]
	var owned: bool = CheckpointData.owned_firearms.get(FIREARM_ID, false)
	if owned:
		info_label.text = "%s — già acquistata!\nDanno %d · Caricatore %d" % [def.label, int(def.damage), int(def.magazine_size)]
		buy_button.disabled = true
		buy_button.text = "Acquistata"
		hint_label.text = "Hai la tua pistola! Esci dalla porta a sud per proseguire"
	else:
		info_label.text = "%s\nDanno %d · Caricatore %d · Portata %d\nGratis, è un regalo per iniziare!" % [
			def.label, int(def.damage), int(def.magazine_size), int(def.range),
		]
		buy_button.disabled = false
		buy_button.text = "Prendi"

func _on_buy_pressed() -> void:
	if CheckpointData.owned_firearms.get(FIREARM_ID, false):
		return
	var def: Dictionary = Firearms.WEAPONS[FIREARM_ID]
	CheckpointData.owned_firearms[FIREARM_ID] = true
	CheckpointData.firearm_upgrades[FIREARM_ID] = {}
	CheckpointData.firearm_ammo[FIREARM_ID] = int(def.magazine_size)
	CheckpointData.equipped_firearm = FIREARM_ID
	CheckpointData.save_checkpoint(1, int(CheckpointData.money), CheckpointData.materials, CheckpointData.upgrades)
	_refresh_buy_panel()

func _on_door_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	TutorialProgress.set_stage("field2")
	get_tree().change_scene_to_file("res://scenes/IntroField2.tscn")
