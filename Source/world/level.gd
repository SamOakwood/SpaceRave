extends Node3D

@onready
var start_time := Time.get_ticks_msec()

@onready
var level_path:Path3D = $LevelPath

func _on_desertion_checker_timeout() -> void:
	var cp := level_path.curve.get_closest_point(level_path.to_local($Player.global_position))
	var dis:float = $Player.global_position.distance_to(level_path.to_global(cp))
	if dis > 50:
		$Player.die(Player.DeathReason.DESERTED)


func _on_win_area_body_entered(body: Node3D) -> void:
	if body is Player:
		(body as Player).win(Time.get_ticks_msec()-start_time)
