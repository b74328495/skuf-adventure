extends ProgressBar

# Имя твоего игрока. Проверь, чтобы в дереве сцены было точно так же!
@export var player_node_name: String = "Player"

func _ready() -> void:
	# --- ДЕЛАЕМ ПОЛОСКУ КРАСНОЙ ---
	# Создаем стиль для заполнения
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(1.0, 0.0, 0.0) # Ярко-красный
	sb_fill.set_border_width_all(1)
	
	# Создаем стиль для фона
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8) # Темный фон
	
	# Применяем стили
	add_theme_stylebox_override("fill", sb_fill)
	add_theme_stylebox_override("background", sb_bg)
	
	# Убираем цифры процентов
	show_percentage = false
	
	# Чтобы полоска всегда была поверх всего остального
	z_index = 10

func _process(_delta: float) -> void:
	# Ищем игрока
	var player = get_tree().current_scene.find_child(player_node_name, true, false)
	
	if is_instance_valid(player):
		# Обновляем значения из твоего скрипта игрока
		max_value = player.health
		value = player.health
	else:
		# Если игрок не найден (например, еще не загрузился), полоска пустая
		value = 0
