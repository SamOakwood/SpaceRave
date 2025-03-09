extends MarginContainer


func _on_button_how_to_play_pressed() -> void:
	$Main.hide()
	$Credits.hide()
	$HowToPlay.show()


func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://Resources/Scenes/world/level.tscn"))


func _on_button_credits_pressed() -> void:
	$Main.hide()
	$Credits.show()
	$HowToPlay.hide()


func _on_button_back_pressed() -> void:
	$Main.show()
	$Credits.hide()
	$HowToPlay.hide()
