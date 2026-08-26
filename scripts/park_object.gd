extends StaticBody3D

signal destroyed

@export var max_hp: float = 100.0
@export var material_drops: Dictionary = {}
@export var low_object: bool = false

var hp: float
var base_scale: Vector3

# Modello 3D vero (Kenney), mostrato solo nello scenario Parco: gli altri
# scenari (Bosco/Palude) restano con le forme primitive di sempre, non
# ancora rifatte. Un unico nodo "RealModel" (nascosto di default nella
# scena) e le mesh primitive dirette sotto la radice bastano per gestire
# il passaggio, senza bisogno di logica diversa per ogni tipo di oggetto.
@onready var _real_model: Node3D = get_node_or_null("RealModel")
var _primitive_meshes: Array = []

func _ready() -> void:
	hp = max_hp
	base_scale = scale
	add_to_group("park_objects")
	if _real_model:
		_real_model.visible = false
	for c in get_children():
		if c is MeshInstance3D:
			_primitive_meshes.append(c)

# Chiamata da main.gd al momento dello spawn (o al passaggio di scenario):
# mostra il modello vero solo se l'oggetto sta nascendo nello scenario
# Parco, altrimenti resta con le mesh primitive di sempre. Nessun effetto
# sugli oggetti senza un nodo "RealModel" (non ancora "vestiti" per il Parco).
func set_parco_visual(is_parco: bool) -> void:
	if _real_model == null:
		return
	_real_model.visible = is_parco
	for m in _primitive_meshes:
		m.visible = not is_parco

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
