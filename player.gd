extends CharacterBody2D

const MAX_SPEED    := 300.0
const ACCEL        := 2200.0
const FRICTION     := 2600.0
const AIR_ACCEL    := 1500.0
const AIR_FRICTION := 320.0

const JUMP_VELOCITY := -520.0
const JUMP_CUT      := 0.40

const GRAVITY_RISE      := 1500.0
const GRAVITY_FALL      := 2900.0
const APEX_SPEED        := 110.0
const APEX_GRAVITY_MULT := 0.55
const MAX_FALL          := 1200.0

const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12

const SQUASH_JUMP    := Vector2(0.78, 1.26)
const SQUASH_LAND    := Vector2(1.28, 0.74)
const SQUASH_RECOVER := 16.0

const CAM_LOOKAHEAD := 46.0    # pixels the camera leads in your direction of travel
const CAM_EASE      := 6.0
const SHAKE_DECAY   := 44.0
const HARD_LANDING  := 900.0   # below this, landings are quiet
const DUST_LANDING  := 350.0

@onready var body: Node2D          = $Body
@onready var cam:  Camera2D        = $Camera2D
@onready var dust: CPUParticles2D  = $Dust

var _coyote := 0.0
var _buffer := 0.0
var _squash := Vector2.ONE
var _look   := 0.0
var _shake  := 0.0


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	var direction := Input.get_axis("move_left", "move_right")
	var accel     := ACCEL if is_on_floor() else AIR_ACCEL
	var friction  := FRICTION if is_on_floor() else AIR_FRICTION

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	else:
		_buffer = maxf(_buffer - delta, 0.0)

	if _buffer > 0.0 and _coyote > 0.0:
		_jump()

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	var was_on_floor := is_on_floor()
	var impact := velocity.y

	move_and_slide()

	if is_on_floor() and not was_on_floor:
		_on_land(impact)

	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-SQUASH_RECOVER * delta))
	body.scale = _squash

	_update_camera(delta)


func _update_camera(delta: float) -> void:
	# Lead the camera toward where the player is going, not where they are.
	var target := (velocity.x / MAX_SPEED) * CAM_LOOKAHEAD
	_look = lerpf(_look, target, 1.0 - exp(-CAM_EASE * delta))

	_shake = maxf(_shake - SHAKE_DECAY * delta, 0.0)
	cam.offset = Vector2(
		_look + randf_range(-_shake, _shake),
		randf_range(-_shake, _shake)
	)


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_coyote = 0.0
	_buffer = 0.0
	_squash = SQUASH_JUMP


func _on_land(impact: float) -> void:
	_squash = SQUASH_LAND
	if impact > DUST_LANDING:
		dust.restart()
	if impact > HARD_LANDING:
		_shake = minf(impact / 110.0, 9.0)


func _apply_gravity(delta: float) -> void:
	var g := GRAVITY_RISE if velocity.y < 0.0 else GRAVITY_FALL
	if absf(velocity.y) < APEX_SPEED:
		g *= APEX_GRAVITY_MULT
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)
