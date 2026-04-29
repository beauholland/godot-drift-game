extends Node

const CAR_RED := preload("res://data/cars/car_red.tres")
const CAR_BLUE := preload("res://data/cars/car_blue.tres")
const STAGE_1 := preload("res://data/stages/stage_1.tres")

var available_cars: Array[CarData] = [CAR_RED, CAR_BLUE]
var available_stages: Array[StageData] = [STAGE_1]

var selected_car: CarData = CAR_RED
var selected_stage: StageData = STAGE_1

var last_run_time: float = 0.0
var last_run_score: int = 0

func record_run(time_seconds: float, score: int) -> void:
	last_run_time = time_seconds
	last_run_score = score
