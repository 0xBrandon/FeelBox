extends CharacterBody2D

const MAX_SPEED    := 300.0
const ACCEL        := 2200.0   # how fast you reach top speed on the ground
const FRICTION     := 600.0   # how fast you stop on the ground
const AIR_ACCEL    := 1500.0   # less control in the air...
const AIR_FRICTION := 320.0    # ...and you barely slow down up there

const JUMP_VELOCITY := -520.0
const GRAVITY       := 1400.0


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	var direction := Input.get_axis("move_left", "move_right")
	var accel     := ACCEL if is_on_floor() else AIR_ACCEL
	var friction  := FRICTION if is_on_floor() else AIR_FRICTION

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
