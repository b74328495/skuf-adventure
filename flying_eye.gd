extends CharacterBody2D

# --- НАСТРОЙКИ ---
@export var speed = 180.0
@export var attack_speed = 400.0
@export var health = 30
@export var damage = 10

# --- СОСТОЯНИЯ ---
var player = null
var is_dead = false
var is_taking_damage = false
var is_attacking = false
var attack_cooldown = false

@onready var anim = $AnimatedSprite2D

func _ready():
	# Глаз на слое 2, ни с чем физически не сталкивается
	collision_layer = 2
	collision_mask = 0

	# --- Detector ---
	if has_node("Detector"):
		var detector = $Detector
		detector.collision_layer = 0
		detector.collision_mask = 1  # ← Видит слой 1 (игрок)
		detector.monitoring = true
		detector.monitorable = true

		# Подключаем только если ещё не подключено
		if not detector.body_entered.is_connected(_on_detector_area_body_entered):
			detector.body_entered.connect(_on_detector_area_body_entered)
		if not detector.body_exited.is_connected(_on_detector_area_body_exited):
			detector.body_exited.connect(_on_detector_area_body_exited)

		print("Detector OK, mask=", detector.collision_mask)
	else:
		push_error("НЕТ УЗЛА Detector!")

	# --- AttackArea ---
	if has_node("AttackArea"):
		var attack = $AttackArea
		attack.collision_layer = 0
		attack.collision_mask = 1  # ← Видит слой 1 (игрок)
		attack.monitoring = true
		attack.monitorable = true

		if not attack.body_entered.is_connected(_on_attack_area_body_entered):
			attack.body_entered.connect(_on_attack_area_body_entered)
		if not attack.body_exited.is_connected(_on_attack_area_body_exited):
			attack.body_exited.connect(_on_attack_area_body_exited)

		print("AttackArea OK, mask=", attack.collision_mask)
	else:
		push_error("НЕТ УЗЛА AttackArea!")

	print("=== ГЛАЗ ГОТОВ ===")
	print("Мой слой: ", collision_layer, " | Моя маска: ", collision_mask)

func _physics_process(delta):
	if is_dead or is_taking_damage:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 10)
		move_and_slide()
		return

	if player:
		var direction = global_position.direction_to(player.global_position)

		if is_attacking:
			anim.play("Attack")
		else:
			anim.play("Flying")
			velocity = direction * speed

		anim.flip_h = direction.x < 0
	else:
		anim.play("Flying")
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 10)

	move_and_slide()

# --- ЗОНА ОБНАРУЖЕНИЯ ---

func _on_detector_area_body_entered(body):
	print("Detector сработал! Тело: ", body.name, " | Группы: ", body.get_groups())
	if body.is_in_group("player"):
		player = body
		modulate = Color.RED
		print("ГЛАЗ: ВИЖУ ИГРОКА!")

func _on_detector_area_body_exited(body):
	if body == player:
		player = null
		is_attacking = false
		attack_cooldown = false
		modulate = Color.WHITE
		print("ГЛАЗ: ПОТЕРЯЛ ИГРОКА")

# --- ЗОНА АТАКИ ---

func _on_attack_area_body_entered(body):
	print("AttackArea сработал! Тело: ", body.name)
	if body.is_in_group("player") and not is_dead and not is_taking_damage and not attack_cooldown:
		attack_cooldown = true
		is_attacking = true
		anim.play("Attack")

		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			print("ВНИМАНИЕ: У игрока нет метода take_damage!")

		var bounce = (global_position - body.global_position).normalized()
		velocity = bounce * 700

		await get_tree().create_timer(1.0).timeout
		if not is_dead:
			attack_cooldown = false
			is_attacking = false

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		is_attacking = false

# --- ПОЛУЧЕНИЕ УРОНА ---

func take_damage(amount):
	if is_dead:
		return

	health -= amount
	is_taking_damage = true
	is_attacking = false

	if health <= 0:
		die()
	else:
		anim.play("TakeHit")
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 400
		await anim.animation_finished
		is_taking_damage = false

# --- СМЕРТЬ ---

func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("Death")
	await anim.animation_finished
	queue_free()
