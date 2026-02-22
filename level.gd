extends Node2D
@onready var light = $DirectionalLight2D
enum {
	MORNING,
	DAY,
	EVENING,
	NIGHT
}

var state = MORNING

func _ready():
	change_light()

func morning_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.5, 20)
	
func day_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 1.0, 20)
	
func evening_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.5, 20)
	
func night_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.2, 20)

func change_light():
	match state:
		MORNING:
			morning_state()
		DAY:
			day_state()
		EVENING:
			evening_state()
		NIGHT:
			night_state()
	
func _on_day_night_timeout():
	if state < 3:
		state += 1
	else:
		state = MORNING
	change_light()  # Вызываем смену освещения при смене состояния	\1Ч
