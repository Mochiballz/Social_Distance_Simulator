extends KinematicBody2D

class_name Infected

enum single_state {LINEAR, CURVE, LOOP, STOP, SINUSOID}
var distance = 0.0 # Measurement of distance traveled

export(Vector2) var velocity = Vector2.DOWN
export(Vector2) var acceleration = Vector2.ZERO

export(float) var speed = 200.0 # Velocity usage only
export(float) var magnitude = 200.0 # Acceleration usage only, repel function

# FORCES
export(Vector2) var repel_force = Vector2.ZERO
export(Vector2) var avoidance_force = Vector2.ZERO

var behavior_array
var behavior_function = funcref(self, "default")

# NOTE: Overall "movement speed" MUST remain under speed variable

# COUGH VARIABLES
var coughing = false
export(float) var cough_wait_time = 1.0
export(float) var cough_duration_time = 0.05

# BEHAVIOR VARIABLES
var behavior_index = 0
var behavior_active = true
var behavior_delay = 0
var behavior_time = 3 # In seconds

var seek_player = false
var curve_direction = Vector2.LEFT

var old_velocity
var new_velocity
var old_speed

# BEHAVIOR FUNCTIONS - Correspond to enumeration definitions in SpawnPoint.gd
func default(t): # LINEAR
	pass

func set_curve(t): # CURVE
	if behavior_active:
		if seek_player:
			if global_position.distance_to(get_node("/root/World/Entities/Player").global_position) < $InfectionRange/CollisionShape2D.shape.radius:
				velocity = Vector2.ZERO
			else:
				velocity = global_position.direction_to(get_node("/root/World/Entities/Player").global_position)
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

# BEHAVIOR ITERATION: Function that switches to the next behavior in behavior array
func set_behavior():
	behavior_time = behavior_array[behavior_index]["duration"]
	match int(behavior_array[behavior_index]["behavior"]):
		single_state.LINEAR:
			pass
		single_state.CURVE:
			new_velocity = curve_direction
			behavior_function = funcref(self, "set_curve")
		single_state.LOOP:
			behavior_function = funcref(self, "set_loop")
		single_state.STOP:
			behavior_function = funcref(self, "set_stop")
		single_state.SINUSOID:
			behavior_function = funcref(self, "set_sinusoid")
		_:
			pass
	if "direction" in behavior_array[behavior_index]:
		velocity = Vector2(behavior_array[behavior_index]["direction"]["x"], 
						   behavior_array[behavior_index]["direction"]["y"])
	behavior_index += 1

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
	old_velocity = velocity
	old_speed = speed
	set_behavior()
	
	$CoughTimer.set_wait_time(cough_wait_time)
	$CoughDuration.set_wait_time(cough_duration_time)
	$BehaviorDuration.set_wait_time(behavior_time)
	
	$CoughTimer.start()
	$BehaviorDuration.start()
	
	set_physics_process(true)


func _physics_process(delta):
	acceleration = (repel_force + avoidance_force).clamped(1.0)
	var move_vector = (velocity * speed) + (acceleration * magnitude)
	
	if velocity == Vector2.ZERO:
		var map = get_node("/root/World/Map")
		var map_direction = polar2cartesian(1, -map.direction)
		move_and_slide(map_direction * map.scroll_speed / delta)
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

func _on_BehaviorDuration_timeout():
	if behavior_index < behavior_array.size():
		set_behavior()
		$BehaviorDuration.set_wait_time(behavior_time)
		$BehaviorDuration.start()
	else:
		behavior_active = false



