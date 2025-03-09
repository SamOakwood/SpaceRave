extends CharacterBody3D
class_name Player

enum DeathReason{DESERTED, DIED}

@export
var max_speed:float = 5.0

@export
var jump_velocity:float = 5.0

@export
var acceleration:float = 1.0

@export
var is_deflecting:bool = false

var attached_platform:Platform
var direction:Vector3
var local_velocity:Vector3 = Vector3.ZERO
var last_velocity:Vector3 = velocity
var charges:int = 3
var dead = false

var was_on_floor = false

var last_inspect := Time.get_ticks_msec()+randi_range(10_000, 60_000)

@onready
var target_rotation:Vector3 = self.rotation

@onready
var animation:AnimationHandler = $Gimbal/CamHead/Camera3D/animation

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	handle_animation()
	if rotation != target_rotation:
		rotation.x = rotate_toward(rotation.x, target_rotation.x, PI*2*delta)
		rotation.y = rotate_toward(rotation.y, target_rotation.y, PI*2*delta)
		rotation.z = rotate_toward(rotation.z, target_rotation.z, PI*2*delta)
	if attached_platform != null:
		if not is_on_floor():
			local_velocity.y -= 16*delta
		else:
			charges = 3
			if Input.is_action_just_pressed("mv_up"):
				local_velocity.y = jump_velocity
	var dash_velocity = Vector3.ZERO
	if charges > 0 and attached_platform == null:
		if Input.is_action_just_pressed("mv_dash_l"):
			dash_velocity.x = -15
			charges -= 1
		if Input.is_action_just_pressed("mv_dash_r"):
			dash_velocity.x = 15
			charges -= 1
		if Input.is_action_just_pressed("mv_dash_fw"):
			dash_velocity.z = -15
			charges -= 1
	if attached_platform != null:
		var input := Input.get_vector("mv_l", "mv_r", "mv_fw", "mv_bw")
	
		var direction:Vector3 =  Vector3(input.x, 0, input.y).normalized()
		if direction and is_on_floor():
			local_velocity.x = move_toward(local_velocity.x, direction.x * max_speed, acceleration)
			local_velocity.z = move_toward(local_velocity.z, direction.z * max_speed, acceleration)
		else:
			if is_on_floor():
				local_velocity.x = move_toward(local_velocity.x, 0, acceleration)
				local_velocity.z = move_toward(local_velocity.z, 0, acceleration)
			else:
				local_velocity.x = move_toward(local_velocity.x, 0, acceleration*0.05)
				local_velocity.z = move_toward(local_velocity.z, 0, acceleration*0.05)
		
		
	
	if attached_platform != null:
		velocity = $Gimbal.global_basis * local_velocity
	if dash_velocity != Vector3.ZERO:
		velocity = (velocity*0.3) + $Gimbal/CamHead.global_basis * dash_velocity
		
	if attached_platform == null:
		velocity = velocity.move_toward(velocity.limit_length(5), acceleration*0.2)
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var rb:RigidBody3D = c.get_collider() as RigidBody3D
			rb.apply_impulse(c.get_normal(), c.get_position())
	if charges >= 3:
		$HUD/Control/ChargeOneFill.show()
		$HUD/Control/ChargeTwoFill.show()
		$HUD/Control/ChargeThreeFill.show()
	elif charges == 2:
		$HUD/Control/ChargeOneFill.show()
		$HUD/Control/ChargeTwoFill.show()
		$HUD/Control/ChargeThreeFill.hide()
	elif charges == 1:
		$HUD/Control/ChargeOneFill.show()
		$HUD/Control/ChargeTwoFill.hide()
		$HUD/Control/ChargeThreeFill.hide()
	elif charges == 0:
		$HUD/Control/ChargeOneFill.hide()
		$HUD/Control/ChargeTwoFill.hide()
		$HUD/Control/ChargeThreeFill.hide()
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$Gimbal.rotate_y(deg_to_rad(-event.relative.x*0.15))
		$Gimbal/CamHead.rotation.x = clamp($Gimbal/CamHead.rotation.x+deg_to_rad(-event.relative.y*0.15), -PI/2, PI/2)

func handle_animation():
	var walking_cond := attached_platform != null and is_on_floor()\
	 and not get_real_velocity().is_zero_approx()\
	 and not Input.is_action_pressed("attack")
	var idling_cond := (attached_platform == null or not is_on_floor()\
	 or get_real_velocity().is_zero_approx())\
	 and not Input.is_action_pressed("attack")
	var attacking_cond = Input.is_action_pressed("attack")
	if Input.is_action_just_pressed("attack"):
		animation.animation_tree.set("parameters/SwingTree/SwingTransition/transition_request", "SwingFW")
	if attacking_cond or walking_cond:
		animation.animation_tree.set("parameters/IdleTree/IdleTransition/transition_request", "Idle")
	animation.animation_tree.set("parameters/conditions/is_walking", walking_cond)
	animation.animation_tree.set("parameters/conditions/is_idling", idling_cond)
	animation.animation_tree.set("parameters/conditions/is_swinging", attacking_cond)
	animation.animation_tree.set("parameters/conditions/has_landed", not was_on_floor and is_on_floor())
	
	if last_inspect < Time.get_ticks_msec():
		last_inspect = Time.get_ticks_msec()+randi_range(10_000, 60_000)
		animation.animation_tree.set("parameters/IdleTree/IdleTransition/transition_request", "IdleInspect")
	
	was_on_floor = is_on_floor()
	
	

func _on_boots_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("EngageGravArea") and area.get_parent_node_3d() and area.get_parent_node_3d() is Platform:
		var platform:Platform = area.get_parent_node_3d() as Platform
		if up_direction != platform.up_direction():
			var rotation_angle := up_direction.angle_to(platform.up_direction())
			var axis := up_direction.cross(platform.up_direction())
			if axis != Vector3.ZERO:
				target_rotation = transform.rotated(axis.normalized(), rotation_angle).basis.get_euler()
			up_direction = platform.up_direction()
		attached_platform = platform
		velocity = (velocity * 0.8) + position.direction_to(platform.position)
		local_velocity = $Gimbal.global_basis.transposed() * velocity
		print("attached")
		$MagnetAudioPlayer.play()


func _on_boots_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("EngageGravArea") and area.get_parent_node_3d() and area.get_parent_node_3d() is Platform:
		var platform:Platform = area.get_parent_node_3d() as Platform
		if attached_platform == platform: #Don't detach if the player seamlessly went to another platform without floating.
			attached_platform = null
			local_velocity.y = max(0, local_velocity.y)
			velocity = $Gimbal.global_basis * local_velocity
			print("detached")


func _on_hit_area_body_entered(body: Node3D) -> void:
	if body is EnemyUFO:
		(body as EnemyUFO).die()


func _on_deflect_area_area_entered(area: Area3D) -> void:
	if is_deflecting and area is Projectile:
		var p:Projectile = area as Projectile
		p.is_hostile = false
		p.global_basis = $Gimbal/CamHead.global_basis

func die(reason:DeathReason):
	$DeathTimer.start()
	$HeartBeatPlayer.play()
	$DeadOL.show()
	dead = true
	if reason == DeathReason.DIED:
		$DeadOL/VBoxContainer/ReasonText.text = "You died in combat."
	else:
		$DeadOL/VBoxContainer/ReasonText.text = "You deserted."
	get_tree().paused = true


func _on_death_timer_timeout() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func win() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer/WinOL.show()
	get_tree().paused = true
	
