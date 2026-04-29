extends Node

const SAMPLE_RATE: float = 22050.0
const ENGINE_IDLE_FREQ: float = 70.0
const ENGINE_MAX_FREQ: float = 240.0
const TURBO_DURATION: float = 0.7

@onready var engine_player: AudioStreamPlayer = $Engine
@onready var drift_player: AudioStreamPlayer = $Drift
@onready var turbo_player: AudioStreamPlayer = $Turbo

var _engine_pb: AudioStreamGeneratorPlayback
var _drift_pb: AudioStreamGeneratorPlayback
var _turbo_pb: AudioStreamGeneratorPlayback

var _engine_phase: float = 0.0
var _drift_lp1: float = 0.0
var _drift_lp2: float = 0.0
var _turbo_lp: float = 0.0
var _turbo_remaining: float = 0.0

var _engine_speed_target: float = 0.0
var _engine_speed: float = 0.0
var _engine_volume_target: float = 0.0
var _engine_volume: float = 0.0

var _drift_target: float = 0.0
var _drift_volume: float = 0.0

func _ready() -> void:
	_engine_pb = _start_generator(engine_player, 0.06)
	_drift_pb = _start_generator(drift_player, 0.06)
	_turbo_pb = _start_generator(turbo_player, 0.1)

func _start_generator(p: AudioStreamPlayer, buf: float) -> AudioStreamGeneratorPlayback:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = buf
	p.stream = gen
	p.play()
	return p.get_stream_playback() as AudioStreamGeneratorPlayback

func set_engine_state(speed_ratio: float, throttle: float) -> void:
	_engine_speed_target = clampf(speed_ratio, 0.0, 1.0)
	var idle_vol := 0.18
	var rev_vol: float = clampf(throttle, 0.0, 1.0) * 0.55 + _engine_speed_target * 0.35
	_engine_volume_target = clampf(idle_vol + rev_vol, 0.0, 1.0)

func set_drift_intensity(intensity: float) -> void:
	_drift_target = clampf(intensity, 0.0, 1.0)

func trigger_turbo_blowoff() -> void:
	_turbo_remaining = TURBO_DURATION
	_turbo_lp = 0.0

func _process(delta: float) -> void:
	var freq_smooth: float = clampf(delta * 6.0, 0.0, 1.0)
	var vol_smooth: float = clampf(delta * 5.0, 0.0, 1.0)

	_engine_speed = lerpf(_engine_speed, _engine_speed_target, freq_smooth)
	_engine_volume = lerpf(_engine_volume, _engine_volume_target, vol_smooth)
	_drift_volume = lerpf(_drift_volume, _drift_target, vol_smooth)

	_fill_engine()
	_fill_drift()
	if _turbo_remaining > 0.0:
		_fill_turbo()
		_turbo_remaining = maxf(0.0, _turbo_remaining - delta)

func _fill_engine() -> void:
	var n := _engine_pb.get_frames_available()
	if n <= 0:
		return
	var out := PackedVector2Array()
	out.resize(n)
	var freq: float = lerpf(ENGINE_IDLE_FREQ, ENGINE_MAX_FREQ, _engine_speed)
	var inc: float = freq / SAMPLE_RATE
	var vol: float = _engine_volume * 0.32
	for i in n:
		_engine_phase += inc
		if _engine_phase >= 1.0:
			_engine_phase -= 1.0
		var saw: float = _engine_phase * 2.0 - 1.0
		var oct: float = fmod(_engine_phase * 2.0, 1.0) * 2.0 - 1.0
		var s: float = (saw * 0.7 + oct * 0.3) * vol
		out[i] = Vector2(s, s)
	_engine_pb.push_buffer(out)

func _fill_drift() -> void:
	var n := _drift_pb.get_frames_available()
	if n <= 0:
		return
	var out := PackedVector2Array()
	out.resize(n)
	var vol: float = _drift_volume * 0.42
	for i in n:
		var noise: float = randf() * 2.0 - 1.0
		_drift_lp1 = _drift_lp1 * 0.62 + noise * 0.38
		_drift_lp2 = _drift_lp2 * 0.62 + _drift_lp1 * 0.38
		var bp: float = _drift_lp2 - _drift_lp1 * 0.28
		var s: float = bp * vol
		out[i] = Vector2(s, s)
	_drift_pb.push_buffer(out)

func _fill_turbo() -> void:
	var n := _turbo_pb.get_frames_available()
	if n <= 0:
		return
	var out := PackedVector2Array()
	out.resize(n)
	var dt: float = 1.0 / SAMPLE_RATE
	var t_remaining: float = _turbo_remaining
	for i in n:
		var t: float = clampf(t_remaining / TURBO_DURATION, 0.0, 1.0)
		var elapsed: float = 1.0 - t
		var attack: float = clampf(elapsed / 0.05, 0.0, 1.0)
		var decay: float = pow(t, 1.4)
		var env: float = attack * decay
		var noise: float = randf() * 2.0 - 1.0
		var lp_coef: float = lerpf(0.55, 0.82, elapsed)
		_turbo_lp = _turbo_lp * lp_coef + noise * (1.0 - lp_coef)
		var s: float = _turbo_lp * env * 0.55
		out[i] = Vector2(s, s)
		t_remaining -= dt
	_turbo_pb.push_buffer(out)
