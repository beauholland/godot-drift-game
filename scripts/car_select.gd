extends Control

@onready var car_list: ItemList = $Panel/VBox/CarList
@onready var preview_box: Control = $Panel/VBox/PreviewBox
@onready var car_preview: Node2D = $Panel/VBox/PreviewBox/CarPreview
@onready var preview_body: Polygon2D = $Panel/VBox/PreviewBox/CarPreview/Body
@onready var stats_label: Label = $Panel/VBox/StatsLabel

func _ready() -> void:
	preview_box.resized.connect(_center_preview)
	_center_preview()
	car_list.clear()
	for car in GameState.available_cars:
		car_list.add_item(car.display_name)
	var idx := GameState.available_cars.find(GameState.selected_car)
	if idx < 0:
		idx = 0
	car_list.select(idx)
	_apply_selection(idx)

func _center_preview() -> void:
	car_preview.position = preview_box.size * 0.5

func _on_car_list_item_selected(index: int) -> void:
	_apply_selection(index)

func _apply_selection(index: int) -> void:
	if index < 0 or index >= GameState.available_cars.size():
		return
	var car: CarData = GameState.available_cars[index]
	GameState.selected_car = car
	preview_body.color = car.color
	stats_label.text = "Top Speed: %d\nAccel: %d\nGrip: %.1f\nDrift Grip: %.1f" % [
		int(car.max_speed), int(car.acceleration), car.grip, car.drift_grip
	]

func _on_next_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_on_back_pressed()
