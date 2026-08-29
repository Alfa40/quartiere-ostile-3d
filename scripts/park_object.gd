extends StaticBody3D

signal destroyed

@export var max_hp: float = 100.0
@export var material_drops: Dictionary = {}
@export var low_object: bool = false

var hp: float
var base_scale: Vector3

# Modello 3D vero (Kenney), uno per ogni scenario che ne ha già uno dedicato:
# gli scenari non ancora "vestiti" restano con le forme primitive di sempre.
# Ogni variante è un figlio "RealModel_<indice scenario>" (nascosto di
# default nella scena, vedi Scenarios.DATA per gli indici); le mesh
# primitive dirette sotto la radice restano il fallback. Un'unica scansione
# dei figli basta per gestire il passaggio, senza bisogno di logica diversa
# per ogni tipo di oggetto o per quanti scenari sono già stati "vestiti".
var _real_models := {}
var _primitive_meshes: Array = []

func _ready() -> void:
	hp = max_hp
	base_scale = scale
	add_to_group("park_objects")
	for c in get_children():
		if c is MeshInstance3D:
			_primitive_meshes.append(c)
		elif c.name.begins_with("RealModel_"):
			var idx := int(c.name.trim_prefix("RealModel_"))
			_real_models[idx] = c
			c.visible = false

# Chiamata da main.gd al momento dello spawn (o al passaggio di scenario):
# mostra il modello vero dello scenario attuale se questo tipo di oggetto ne
# ha uno dedicato, altrimenti resta con le mesh primitive di sempre.
func apply_scenario_visual(scenario_idx: int) -> void:
	for idx in _real_models:
		_real_models[idx].visible = (idx == scenario_idx)
	var use_primitive: bool = not _real_models.has(scenario_idx)
	for m in _primitive_meshes:
		m.visible = use_primitive

func take_damage(amount: float, _source = null) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	if hp <= 0.0:
		hp = 0.0
		destroyed.emit()
		_play_destroy_and_free()
	else:
		_flash_hit()

func _flash_hit() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", base_scale * 1.08, 0.05)
	tw.tween_property(self, "scale", base_scale, 0.08)

func _play_destroy_and_free() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", base_scale * 0.05, 0.25)
	tw.tween_callback(queue_free)
