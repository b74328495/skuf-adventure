extends Node2D

# Эта функция запустит игру
func _on_play_pressed():
	get_tree().change_scene_to_file("res://level.tscn")

# Эта функция выйдет из игры
func _on_quit_pressed():
	get_tree().quit()
