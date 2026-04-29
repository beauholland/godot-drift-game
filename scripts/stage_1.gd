extends Node2D

@onready var player_car: PlayerCar = $PlayerCar
@onready var hud: CanvasLayer = $HUD
@onready var speed_label: Label = $HUD/HUDRoot/TopBar/SpeedLabel
@onready var drift_label: Label = $HUD/HUDRoot/TopBar/DriftLabel
@onready var score_label: Label = $HUD/HUDRoot/TopBar/ScoreLabel
@onready var time_label: Label = $HUD/HUDRoot/TopBar/TimeLabel
@onready var lap_label: Label = $HUD/HUDRoot/TopBar/LapLabel
@onready var finish_area: Area2D = $FinishLine
@onready var checkpoint_area: Area2D = $Checkpoint
@onready var camera: Camera2D = $Camera2D

const SCORE_PER_SECOND: float = 120.0
const COMBO_BONUS_PER_SECOND: float = 0.25
const SLIP_ANGLE_THRESHOLD: float = 0.18

var run_time: float = 0.0
var drift_score: float = 0.0
var combo_seconds: float = 0.0
var run_finished: bool = false
var checkpoint_reached: bool = false

func _ready() -> void:
	player_car.setup(GameState.selected_car)
	player_car.drift_state_changed.connect(_on_drift_state_changed)
	finish_area.body_entered.connect(_on_finish_body_entered)
	checkpoint_area.body_entered.connect(_on_checkpoint_body_entered)
	_update_drift_label(false)
	_update_lap_label()

func _process(delta: float) -> void:
	camera.global_position = player_car.global_position
	if run_finished:
		return
	run_time += delta
	_update_score(delta)
	_update_hud()

func _update_score(delta: float) -> void:
	var slip := player_car.get_slip_angle()
	var valid := player_car.is_drifting and slip > SLIP_ANGLE_THRESHOLD
	if valid:
		combo_seconds += delta
		var combo_mult: float = 1.0 + combo_seconds * COMBO_BONUS_PER_SECOND
		drift_score += SCORE_PER_SECOND * delta * combo_mult
	else:
		combo_seconds = 0.0

func _update_hud() -> void:
	speed_label.text = "Speed: %d" % int(player_car.get_speed())
	score_label.text = "Score: %d" % int(drift_score)
	var minutes := int(run_time) / 60
	var seconds := run_time - minutes * 60
	time_label.text = "Time: %02d:%05.2f" % [minutes, seconds]

func _on_drift_state_changed(is_drifting: bool) -> void:
	_update_drift_label(is_drifting)

func _update_drift_label(is_drifting: bool) -> void:
	if is_drifting:
		drift_label.text = "DRIFT"
		drift_label.modulate = Color(1, 0.7, 0.2, 1)
	else:
		drift_label.text = ""
		drift_label.modulate = Color(1, 1, 1, 1)

func _update_lap_label() -> void:
	lap_label.text = "Checkpoint: %s" % ("OK" if checkpoint_reached else "—")

func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body == player_car and not checkpoint_reached:
		checkpoint_reached = true
		_update_lap_label()

func _on_finish_body_entered(body: Node2D) -> void:
	if body == player_car and checkpoint_reached:
		finish_run()

func finish_run() -> void:
	if run_finished:
		return
	run_finished = true
	GameState.record_run(run_time, int(drift_score))
	get_tree().change_scene_to_file("res://scenes/results.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
