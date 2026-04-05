extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const SLIDE_SPEED = 500.0      # Скорость скольжения
const SLIDE_DURATION = 0.4     # Длительность скольжения (сек)

# === Характеристики ===
var health: int = 100
var damage: int = 20
var attack_cooldown := false
var is_sliding := false
var slide_direction := 1.0     # Направление скольжения

# Ссылки на узлы
@onready var anim = $AnimatedSprite2D
@onready var attack_area = $AttackArea
var gold = 0  
func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	# 1. Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# === Если скользим — двигаемся в направлении и ничего не делаем ===
	if is_sliding:
		velocity.x = slide_direction * SLIDE_SPEED
		move_and_slide()
		return

	# Если атакуем НА ЗЕМЛЕ — стоим на месте
	if attack_cooldown and is_on_floor():
		velocity.x = 0
		move_and_slide()
		return

	# 2. Прыжок
	if is_on_floor():
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE):
			velocity.y = JUMP_VELOCITY

	# 3. Движение
	var direction := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_physical_key_pressed(KEY_D):
		direction = 1.0

	if direction != 0.0:
		velocity.x = direction * SPEED

		if direction < 0:
			anim.flip_h = true
			attack_area.scale.x = -1
		else:
			anim.flip_h = false
			attack_area.scale.x = 1

		if is_on_floor() and not attack_cooldown and anim.sprite_frames.has_animation("Run"):
			anim.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not attack_cooldown and anim.sprite_frames.has_animation("Idle"):
			anim.play("Idle")

	# 4. Атака
	if Input.is_physical_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not attack_cooldown:
			anim.play("Attack")
			attack()

	# 5. Скольжение на Shift (только на земле и не во время атаки)
	if Input.is_physical_key_pressed(KEY_SHIFT) and is_on_floor() and not is_sliding and not attack_cooldown:
		start_slide()

	move_and_slide()

# === Функция Скольжения ===
func start_slide():
	is_sliding = true

	# Определяем направление: куда смотрит персонаж
	if anim.flip_h:
		slide_direction = -1.0
	else:
		slide_direction = 1.0

	if anim.sprite_frames.has_animation("Slide"):
		anim.play("Slide")

	# Ждём окончания скольжения
	await get_tree().create_timer(SLIDE_DURATION).timeout
	is_sliding = false

# === Функция Атаки ===
func attack():
	attack_cooldown = true

	var original_modulate = anim.modulate
	anim.modulate = Color(1, 1, 0)

	await get_tree().create_timer(0.1).timeout

	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body != self and body.has_method("take_damage"):
			body.take_damage(damage)
			print("Попал по: ", body.name)

	anim.modulate = original_modulate

	await get_tree().create_timer(0.4).timeout
	attack_cooldown = false

# === Получение урона ===
func take_damage(amount: int):
	health -= amount
	print("Ай! Здоровье игрока: ", health)

	anim.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	anim.modulate = Color(1, 1, 1)

	if health <= 0:
		die()

# === Смерть ===
func die():
	print("Игрок погиб!")
	set_physics_process(false)

	# Проигрываем анимацию смерти, если она есть
	if anim.sprite_frames.has_animation("Death"):
		anim.play("Death")
		# Ждём, пока анимация полностью доиграет
		await anim.animation_finished
	else:
		# Если анимации нет — просто затемняем
		anim.modulate = Color(0.2, 0.2, 0.2)

	# Небольшая пауза после анимации
	await get_tree().create_timer(1.0).timeout

	get_tree().change_scene_to_file("res://menu.tscn")
