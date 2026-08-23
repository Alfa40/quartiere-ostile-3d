extends Node

# Stato globale del tutorial giocabile obbligatorio, indipendente da
# CheckpointData/slot: deve esistere una volta sola per l'intera
# installazione del gioco, non per singola partita.
const SAVE_PATH := "user://intro_tutorial.json"

# "field1" = movimento/albero/nemico1/nemico2 (prima della prima casa)
# "field2" = salvataggio NPC/orda/granata/accompagnamento (dopo la prima casa)
# "done" = tutorial completato, il gioco vero è sbloccato
var intro_stage := "field1"

func _ready() -> void:
	_load()

func is_done() -> bool:
	return intro_stage == "done"

func set_stage(stage: String) -> void:
	intro_stage = stage
	_save()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		intro_stage = String(data.get("intro_stage", "field1"))

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"intro_stage": intro_stage}))
	f.close()
