extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 80       
var health = 60      
var damage = 10      
var attack_range = 60 

var is_attacking = false 
var is_knocked_back = false # НОВОЕ: состояние отбрасывания

@onready var anim = $AnimatedSprite2D
var player = null 

@onready var hp_bar = get_node_or_null("HPBar")

func _ready():
	if hp_bar:
		hp_bar.max_value = health
		hp_bar.value = health
		hp_bar.show_percentage = false 
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.8, 0.1, 0.1) 
		hp_bar.add_theme_stylebox_override("fill", fill_style)
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8) 
		hp_bar.add_theme_stylebox_override("background", bg_style)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if health <= 0: return

	# НОВОЕ: Если скелета отбросило, он просто летит и не может бежать/атаковать
	if is_knocked_back:
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	if player != null:
		var distance = self.global_position.distance_to(player.global_position)
		var direction = (player.global_position - self.global_position).normalized()
		
		if distance > attack_range:
			velocity.x = direction.x * speed
			
			if direction.x < 0: anim.flip_h = true
			else: anim.flip_h = false
			
			if anim.animation != "Run": 
				if anim.sprite_frames.has_animation("Run"): anim.play("Run")
				elif anim.sprite_frames.has_animation("Walk"): anim.play("Walk")
		else:
			velocity.x = 0
			start_attack()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if anim.animation != "Idle": 
			if anim.sprite_frames.has_animation("Idle"): anim.play("Idle")
			
	move_and_slide()

func start_attack():
	is_attacking = true 
	
	if anim.sprite_frames.has_animation("Attack"):
		anim.play("Attack")
	else:
		anim.modulate = Color(1, 0, 0) 
	
	await get_tree().create_timer(0.6).timeout
	
	if player != null and global_position.distance_to(player.global_position) <= attack_range + 20:
		if player.has_method("take_damage"):
			player.take_damage(damage)

	await get_tree().create_timer(0.2).timeout
	
	is_attacking = false 
	anim.play("Idle") 

# НОВОЕ: Функция получения урона теперь принимает направление отбрасывания
func take_damage(amount, knockback_dir = 0.0):
	health -= amount
	
	if hp_bar:
		hp_bar.value = health
		
	# Если пришел крит (направление не 0), отбрасываем
	if knockback_dir != 0.0:
		is_knocked_back = true
		velocity.x = knockback_dir * 300.0  # Сила по горизонтали
		velocity.y = -200.0                 # Сила подбрасывания вверх
		
	anim.modulate = Color(1, 0, 0)
	
	await get_tree().create_timer(0.3).timeout # Ждем пока летит
	
	anim.modulate = Color(1, 1, 1)
	is_knocked_back = false # Возвращаем скелету управление
	
	if health <= 0: die()

func die():
	set_physics_process(false)
	
	if hp_bar:
		hp_bar.hide()
		
	if anim.sprite_frames.has_animation("Death"):
		anim.play("Death")
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "skuf" or body.name == "Player":
		player = body

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
