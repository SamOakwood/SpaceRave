extends Area3D
class_name Projectile

var is_hostile:bool = true

func _physics_process(_delta: float) -> void:
	global_position -= global_basis.z

func _on_deletion_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if is_hostile and body is Player:
		(body as Player).die(Player.DeathReason.DIED)
	elif !is_hostile and body is EnemyUFO:
		(body as EnemyUFO).die()
	queue_free()
