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

@onready var anim = $AnimatedSprite2D

func _ready():
	# 1. Тело глаза на 2-м слое, ни обо что не бьется (чтобы не мешать игроку)
	collision_layer = 2
	collision_mask = 0
	
	# 2. Проверка Группы (выведет ошибку в консоль, если игрока нет в группе)
	print("--- ГЛАЗ ЗАПУЩЕН ---")
	
	# 3. Визуальная проверка: если зон нет, глаз скажет об этом
	if not has_node("DetectorArea") or not has_node("AttackArea"):
		push_error("ОШИБКА: Узлы Area2D должны называться DetectorArea и AttackArea!")

func _physics_process(delta):
	if is_dead or is_taking_damage:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)
		move_and_slide()
		return 

	if player:
		var direction = global_position.direction_to(player.global_position)
		
		if is_attacking:
			anim.play("Attack")
			velocity = direction * attack_speed
		else:
			anim.play("Flying")
			velocity = direction * speed
		
		anim.flip_h = direction.x < 0
	else:
		anim.play("Flying")
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta)

	move_and_slide()

# --- СИГНАЛЫ (ГЛАВНОЕ!) ---

func _on_detector_area_body_entered(body):
	# ВНИМАНИЕ: Если это не срабатывает, проверь ГРУППУ у Игрока!
	if body.is_in_group("player"):
		player = body
		modulate = Color.RED # Глаз станет КРАСНЫМ, когда увидит тебя
		print("ГЛАЗ: ВИЖУ ИГРОКА!")

func _on_detector_area_body_exited(body):
	if body == player:
		player = null
		is_attacking = false
		modulate = Color.WHITE # Снова обычный
		print("ГЛАЗ: ПОТЕРЯЛ ИГРОКА")

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and not is_dead:
		is_attacking = true
		anim.play("Attack")
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Эффект "Укусил и отлетел"
		var bounce = (global_position - body.global_position).normalized()
		velocity = bounce * 700 
		move_and_slide()

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		is_attacking = false

# --- УРОН ---

func take_damage(amount):
	if is_dead: return
	health -= amount
	is_taking_damage = true
	
	if health <= 0:
		die()
	else:
		anim.play("TakeHit")
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 400
		await anim.animation_finished 
		is_taking_damage = false

func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("Death")
	await anim.animation_finished
	queue_free()
