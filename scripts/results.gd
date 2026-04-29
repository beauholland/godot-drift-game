extends Control

@onready var summary_label: Label = $Panel/VBox/Summary

func _ready() -> void:
	var t: float = GameState.last_run_time
	var minutes := int(t) / 60
	var seconds := t - minutes * 60
	summary_label.text = "Time: %02d:%05.2f\nDrift Score: %d" % [minutes, seconds, GameState.last_run_score]

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file(GameState.selected_stage.scene_path)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_on_menu_pressed()
