extends CharacterBody3D

const SPEED = 5.0
const ROTATION_SPEED = 2.0


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# -------------------------
	# PILTANGENTER = ROTATION
	# -------------------------

	if Input.is_key_pressed(KEY_LEFT):
		rotation.y += ROTATION_SPEED * delta

	if Input.is_key_pressed(KEY_RIGHT):
		rotation.y -= ROTATION_SPEED * delta


	# -------------------------
	# WASD = MOVEMENT
	# -------------------------

	var move_direction = Vector3.ZERO

	# W = framåt
	if Input.is_key_pressed(KEY_W):
		move_direction -= transform.basis.z

	# S = bakåt
	if Input.is_key_pressed(KEY_S):
		move_direction += transform.basis.z

	# A = sidled vänster
	if Input.is_key_pressed(KEY_A):
		move_direction -= transform.basis.x

	# D = sidled höger
	if Input.is_key_pressed(KEY_D):
		move_direction += transform.basis.x


	# -------------------------
	# FLYTTA SPELAREN
	# -------------------------

	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
