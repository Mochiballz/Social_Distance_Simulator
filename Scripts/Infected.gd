extends KinematicBody2D

class_name Infected

var distance = 0.0 # Measurement of distance traveled

export(Vector2) var velocity = Vector2.DOWN
export(Vector2) var acceleration = Vector2.ZERO

export(float) var speed = 200.0 # Velocity usage only
export(float) var magnitude = 400.0 # Acceleration usage only, repel function

var behavior_function = funcref(self, "default")

# NOTE: Overall "movement speed" MUST remain under speed variable

# COUGH VARIABLES
var coughing = false
export(float) var cough_wait_time = 1.0
export(float) var cough_duration_time = 0.05

# BEHAVIOR VARIABLES
var behavior_active = false
var behavior_delay = 2
var behavior_time = 3 # In seconds

var seek_player = false

var old_velocity
var new_velocity
var old_speed

# BEHAVIOR FUNCTIONS - Correspond to enumeration definitions in SpawnPoint.gd
func default(t): # LINEAR
	pass

func set_curve(t): # CURVE
	if behavior_active:
		if seek_player:
			new_velocity = global_position.direction_to(get_node("/root/World/Entities/Player").global_position)
			if global_position.distance_to(get_node("/root/World/Entities/Player").global_position) < $InfectionRange/CollisionShape2D.shape.radius:
				return
		
		var p0 = Vector2.ZERO
		var p1 = old_velocity
		var p2 = old_velocity + new_velocity

		var q0 = p0.linear_interpolate(p1, t)
		var q1 = p1.linear_interpolate(p2, t)
		velocity = q0.direction_to(q1).clamped(1.0)
	
func set_loop(t): # LOOP
	if behavior_active:
		velocity = old_velocity.rotated((2 * PI) * t)
	
func set_stop(t): # STOP
	if behavior_active:
		$InfectionRange.repel_enabled = false
		velocity = Vector2.ZERO
	else:
		$InfectionRange.repel_enabled = true
		velocity = old_velocity
	
func set_sinusoid(t): # SINUSOID
	if behavior_active:
		var amplitude = sin(t * (4 * PI)) * 2
		var sine_vector = old_velocity.tangent() * amplitude
		velocity = old_velocity + sine_vector

func motion_animation():
	if velocity != Vector2.ZERO:
		$SpriteGroup/AnimatedSprite.play("run")
		if velocity.x < 0:
			$SpriteGroup/AnimatedSprite.flip_h = true
		else:
			$SpriteGroup/AnimatedSprite.flip_h = false
	else:
		$SpriteGroup/AnimatedSprite.play("idle")

func collision_bounce_check():
	if get_slide_count() > 0:
		velocity = velocity.bounce(get_slide_collision(0).normal)

func coughing_animation(cough):
	var cough_percent = (cough_duration_time - $CoughDuration.time_left) / cough_duration_time
	var buildup_percent = $CoughTimer.time_left / cough_wait_time
	
	var cough_color = Color(1, cough_percent, 1, 1)
	var buildup_color = Color(buildup_percent, 1, buildup_percent, 1)
	
	if cough:
		$InfectionRange/CollisionShape2D/InfectionSprite.modulate = cough_color
	else:
		$InfectionRange/CollisionShape2D/InfectionSprite.modulate = buildup_color

func _ready():
	$CoughTimer.set_wait_time(cough_wait_time)
	$CoughDuration.set_wait_time(cough_duration_time)
	
	$BehaviorTimer.set_wait_time(behavior_delay)
	$BehaviorDuration.set_wait_time(behavior_time)
	
	$CoughTimer.start()
	$BehaviorTimer.start()
	set_physics_process(true)


func _physics_process(delta):
	var move_vector = (velocity * speed) + acceleration
	if velocity == Vector2.ZERO:
		var map = get_node("/root/World/Map")
		move_and_slide(map.direction * map.scroll_speed / delta)
	else:
		move_and_slide(move_vector * scale)
	
	var t = ($BehaviorDuration.wait_time - $BehaviorDuration.time_left) / $BehaviorDuration.wait_time
	behavior_function.call_func(t)

	motion_animation()
	coughing_animation(coughing)
	
	distance += move_vector.length() * scale.length() * delta

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

func _on_CoughTimer_timeout():
	coughing = true
	$CoughTimer.start()
	$CoughDuration.start()

func _on_CoughDuration_timeout():
	coughing = false

func _on_BehaviorTimer_timeout():
	behavior_active = true
	$BehaviorDuration.start()

func _on_BehaviorDuration_timeout():
	behavior_active = false



