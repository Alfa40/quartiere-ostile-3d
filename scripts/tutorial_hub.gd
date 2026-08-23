extends Control

func _ready() -> void:
	$Scroll/Box/MoveButton.pressed.connect(_on_section_pressed.bind("movement"))
	$Scroll/Box/AttackButton.pressed.connect(_on_section_pressed.bind("attack"))
	$Scroll/Box/MaterialsButton.pressed.connect(_on_section_pressed.bind("materials"))
	$Scroll/Box/ThrowablesButton.pressed.connect(_on_section_pressed.bind("throwables"))
	$Scroll/Box/ExplosivesButton.pressed.connect(_on_section_pressed.bind("explosives"))
	$Scroll/Box/GuideButton.pressed.connect(_on_guide_pressed)
	$Scroll/Box/MenuButton.pressed.connect(_on_menu_pressed)

func _on_section_pressed(section: String) -> void:
	TutorialState.section = section
	get_tree().change_scene_to_file("res://scenes/TutorialPlay.tscn")

func _on_guide_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TutorialGuide.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
