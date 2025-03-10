extends StaticBody3D
class_name EnemyUFO




var player_inside:Player = null

@onready
var bullet_scene = preload("res://Resources/Scenes/world/enemy/projectile.tscn")



func die():
	collision_layer = 0
	collision_mask = 0
	$Ufo.hide()
	$Fractures.show()
	for c in $Fractures.get_children():
		if c is RigidBody3D:
			var rb3d := c as RigidBody3D
			rb3d.freeze = false
			var aabb_center:Vector3 = Vector3.ZERO
			for m in rb3d.get_children():
				if m is MeshInstance3D:
					var mi := m as MeshInstance3D
					aabb_center = mi.get_aabb().get_center()
			rb3d.apply_impulse(aabb_center.normalized()*15)
	$PostDeathTimer.start()
	
	$AnimationPlayer.play("charged", -1, -1, false)
	$ChargeSound.stop()
	player_inside = null
	

func _on_post_death_timer_timeout() -> void:
	queue_free()

func shoot():
	if not $Ufo.visible:
		return
	$ShootSound.play()
	$AnimationPlayer.play("RESET")
	if player_inside != null:
		var bullet:Projectile = bullet_scene.instantiate()
		add_sibling(bullet)
		var intercept := calculate_intercept_position(player_inside.global_position, player_inside.get_real_velocity(), 100)
		print(intercept)
		bullet.look_at_from_position($Marker3D.global_position, intercept, global_basis.y)
		
		$AnimationPlayer.play("charged")
		$ChargeSound.play()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body is Player:
		$AnimationPlayer.play("charged")
		$ChargeSound.play()
		player_inside = body as Player
		


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body is Player:
		$AnimationPlayer.play("charged", -1, -1, false)
		$ChargeSound.stop()
		player_inside = null
		
func calculate_intercept_position(player_pos: Vector3, player_vel: Vector3, bullet_vel: float) -> Vector3:
	# Calculate the relative velocity between the bullet and the player
	var relative_velocity = bullet_vel - player_vel.length()
	
	# Calculate the vector from the bullet's starting point to the player's position
	var target_to_player = player_pos - $Marker3D.global_position
	
	# Use a simple equation to solve for the time it takes for the bullet to intersect the player
	var t = target_to_player.length() / relative_velocity
	
	# Calculate where the player will be at the time of intercept
	var intercept_position = player_pos + player_vel * t
	
	return intercept_position
