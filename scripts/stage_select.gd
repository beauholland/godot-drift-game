extends Control

@onready var stage_list: ItemList = $Panel/VBox/StageList

func _ready() -> void:
	stage_list.clear()
	for stage in GameState.available_stages:
		stage_list.add_item(stage.display_name)
	var idx := GameState.available_stages.find(GameState.selected_stage)
	if idx < 0:
		idx = 0
	stage_list.select(idx)
	GameState.selected_stage = GameState.available_stages[idx]

func _on_stage_list_item_selected(index: int) -> void:
	if index < 0 or index >= GameState.available_stages.size():
		return
	GameState.selected_stage = GameState.available_stages[index]

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GameState.selected_stage.scene_path)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/car_select.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_on_back_pressed()
