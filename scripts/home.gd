extends Node3D

const PlayerUpgrades := preload("res://scripts/player_upgrades.gd")
const WORKBENCH_POS := Vector3(1.3, 0.0, -2.2)
const INTERACT_RANGE := 2.2
const MATERIAL_LABELS := {"legno": "Legno", "metallo": "Metallo", "cablaggi": "Cablaggi"}

@onready var player: Node3D = $Player
@onready var interact_button: Button = $HUD/InteractButton
@onready var workbench_menu: Control = $HUD/WorkbenchMenu
@onready var money_materials_label: Label = $HUD/WorkbenchMenu/Scroll/Box/MoneyMaterialsLabel

func _ready() -> void:
	interact_button.visible = false
	workbench_menu.visible = false
	interact_button.pressed.connect(_open_workbench_menu)
	$HUD/WorkbenchMenu/Scroll/Box/CloseButton.pressed.connect(_close_workbench_menu)
	for id in PlayerUpgrades.ORDER:
		var btn: Button = get_node("HUD/WorkbenchMenu/Scroll/Box/Row_%s/BuyButton" % id)
		btn.pressed.connect(_on_buy_pressed.bind(id))
	$DoorTrigger.body_entered.connect(_on_door_entered)
	_refresh_workbench_menu()

func _process(_delta: float) -> void:
	if workbench_menu.visible:
		interact_button.visible = false
		return
	var dist := player.global_position.distance_to(WORKBENCH_POS)
	interact_button.visible = dist <= INTERACT_RANGE

func _open_workbench_menu() -> void:
	workbench_menu.visible = true
	interact_button.visible = false
	_refresh_workbench_menu()

func _close_workbench_menu() -> void:
	workbench_menu.visible = false

func _refresh_workbench_menu() -> void:
	money_materials_label.text = "Soldi: %d€   Legno: %d   Metallo: %d   Cablaggi: %d" % [
		CheckpointData.money, CheckpointData.materials.get("legno", 0),
		CheckpointData.materials.get("metallo", 0), CheckpointData.materials.get("cablaggi", 0),
	]
	for id in PlayerUpgrades.ORDER:
		var level: int = CheckpointData.upgrades.get(id, 0)
		var def: Dictionary = PlayerUpgrades.DEFS[id]
		var row := get_node("HUD/WorkbenchMenu/Scroll/Box/Row_%s" % id)
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

func _on_buy_pressed(id: String) -> void:
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

func _on_door_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	CheckpointData.zone += 1
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
