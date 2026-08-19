extends Node

const SAVE_PATH := "user://best_score.json"

var best_zone := 0
var best_money := 0

func _ready() -> void:
	load_best()

func load_best() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		best_zone = int(data.get("best_zone", 0))
		best_money = int(data.get("best_money", 0))

func report_run(zone: int, money: int) -> void:
	var changed := false
	if zone > best_zone:
		best_zone = zone
		changed = true
	if money > best_money:
		best_money = money
		changed = true
	if changed:
		_save()

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"best_zone": best_zone, "best_money": best_money}))
	f.close()
