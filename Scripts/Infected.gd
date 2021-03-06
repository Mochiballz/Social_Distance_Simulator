extends KinematicBody2D

class_name Infected

enum single_state {LINEAR, CURVE, LOOP, STOP, SINUSOID, DAMPEN}
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

var old_velocity
var new_velocity
var old_speed

var color

# BEHAVIOR FUNCTIONS - Correspond to enumeration definitions in SpawnPoint.gd
func default(t): # LINEAR
	velocity = new_velocity

func set_curve(t): # CURVE
	if behavior_active:
		if seek_player:
			if get_distance_to_player() < $InfectionRange/CollisionShape2D.shape.radius:
				velocity = Vector2.ZERO
			else:
				velocity = get_direction_to_player()
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
		if seek_player:
			if get_distance_to_player() > $InfectionRange/CollisionShape2D.shape.radius * 1.25:
				new_velocity = (new_velocity + get_direction_to_player()).clamped(1.0)
				velocity = new_velocity
#		$InfectionRange.repel_enabled = false
			else:
				velocity = Vector2.ZERO
				seek_player = false
	else:
#		$InfectionRange.repel_enabled = true
		velocity = old_velocity
	
func set_sinusoid(t): # SINUSOID
	if behavior_active:
		if seek_player:
			old_velocity = (old_velocity + (get_direction_to_player() * 0.04)).clamped(1.0)
		var amplitude = sin(t * 12 * PI)
		var sine_vector = old_velocity.tangent() * amplitude
		velocity = (old_velocity + sine_vector).clamped(1.0)

func set_dampen(t):
	if behavior_active:
		if seek_player:
			old_velocity = (old_velocity + (get_direction_to_player() * 0.04)).clamped(1.0)
		var amplitude = sin(t * 12 * PI) * ease(1 - t, 4)
		var sine_vector = old_velocity.tangent() * amplitude
		velocity = (old_velocity + sine_vector).clamped(1.0)

# BEHAVIOR ITERATION: Function that switches to the next behavior in behavior array
func set_behavior():
	behavior_time = behavior_array[behavior_index]["duration"]
	
	var direction
	if "direction" in behavior_array[behavior_index]:
		direction = behavior_array[behavior_index]["direction"]
		
	match int(behavior_array[behavior_index]["behavior"]):
		single_state.LINEAR:
			if typeof(direction) == TYPE_STRING and direction == "diagonal":
				new_velocity = ((get_relative_viewport_side() * -1) + Vector2.DOWN).normalized()
			else:
				new_velocity = velocity
			behavior_function = funcref(self, "default")
		single_state.CURVE:
			if typeof(direction) == TYPE_STRING and direction == "cross":
				new_velocity = Vector2(old_velocity.x * -1, old_velocity.y)
			behavior_function = funcref(self, "set_curve")
		single_state.LOOP:
			behavior_function = funcref(self, "set_loop")
		single_state.STOP:
			new_velocity = old_velocity
			behavior_function = funcref(self, "set_stop")
		single_state.SINUSOID:
			behavior_function = funcref(self, "set_sinusoid")
		single_state.DAMPEN:
			behavior_function = funcref(self, "set_dampen")
		_:
			pass
	behavior_index += 1

func set_color():
	match color:
		"green":
			$SpriteGroup.modulate = Color(0.4,1,0.4,1)
		"blue":
			$SpriteGroup.modulate = Color(0.3,0.3,1,1)
		_:
			pass

# Returns a Vector2 determining what side Infected is on
# Left side would return Vector2.LEFT, right side returns Vector2.RIGHT
func get_relative_viewport_side():
	var viewport_rect = get_viewport_rect()
	var viewport_rect_midpoint = viewport_rect.position.x + (viewport_rect.size.x / 2)
	if global_position.x < viewport_rect_midpoint:
		return Vector2.LEFT
	else:
		return Vector2.RIGHT

func get_distance_to_player():
	return global_position.distance_to(get_node("/root/World/Entities/Player").global_position)

func get_direction_to_player():
	return global_position.direction_to(get_node("/root/World/Entities/Player").global_position)

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
	set_color()
	
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



