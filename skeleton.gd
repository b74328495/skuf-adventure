extends CharacterBody2D

# Исправлен путь: 2d вместо 2D. Добавлено значение 980 как запасное.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980)
var speed = 150 
@onready var anim = $AnimatedSprite2D
var player = null 

func _physics_process(delta):
	# 1. Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 2. Логика преследования
	if player != null:
		# Вычисляем направление к игроку
		var direction = (player.global_position - self.global_position).normalized()
		
		velocity.x = direction.x * speed
		
		# Анимация и разворот
		anim.play("Run")
		if direction.x < 0:
			anim.flip_h = true
		elif direction.x > 0:
			anim.flip_h = false
	else:
		# Остановка, если игрока нет
		velocity.x = move_toward(velocity.x, 0, speed)
		anim.play("Idle")
			
	move_and_slide()

# Когда игрок входит в зону детектора
func _on_detector_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body != self:
		player = body

# Когда игрок выходит из зоны
func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
