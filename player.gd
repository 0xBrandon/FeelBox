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

const SQUASH_JUMP   := Vector2(0.78, 1.26)   # tall and thin, launching
const SQUASH_LAND   := Vector2(1.28, 0.74)   # short and wide, absorbing
const SQUASH_RECOVER := 16.0                 # how fast it springs back

@onready var body: Node2D = $Body

var _coyote := 0.0
var _buffer := 0.0
var _squash := Vector2.ONE


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

	# Remember these BEFORE move_and_slide — it zeroes velocity.y on impact.
	var was_on_floor := is_on_floor()
	var impact := velocity.y

	move_and_slide()

	if is_on_floor() and not was_on_floor:
		_on_land(impact)

	# Ease the squash back to normal. Frame-rate independent, unlike a plain lerp.
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-SQUASH_RECOVER * delta))
	body.scale = _squash


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_coyote = 0.0
	_buffer = 0.0
	_squash = SQUASH_JUMP


func _on_land(impact: float) -> void:
	_squash = SQUASH_LAND


func _apply_gravity(delta: float) -> void:
	var g := GRAVITY_RISE if velocity.y < 0.0 else GRAVITY_FALL
	if absf(velocity.y) < APEX_SPEED:
		g *= APEX_GRAVITY_MULT
	velocity.y = minf(velocity.y + g * delta, MAX_FALL)
