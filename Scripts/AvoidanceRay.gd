extends RayCast2D

var avoidance_enabled = true
var ray_length

func avoidance_force(enabled):
	if enabled and is_colliding():
		if cast_to.length() == 0:
			get_parent().infected_reference.avoidance_force = Vector2.ZERO
			avoidance_enabled = false
			return
		
		var ahead = global_position + cast_to
		var force = (ahead - get_collider().global_position).normalized()
		
		var overlap_length = (ahead - get_collision_point()).length()
		var force_ease = ease(overlap_length / cast_to.length(), 1.8)
		
		get_parent().infected_reference.avoidance_force = force * force_ease
	else:
		get_parent().infected_reference.avoidance_force = Vector2.ZERO

func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	cast_to = get_parent().infected_reference.velocity * get_parent().radius * 2
	avoidance_force(avoidance_enabled)
	
	$DebugLines/Avoidance.clear_points()
	$DebugLines/Avoidance.add_point(Vector2.ZERO)
	$DebugLines/Avoidance.add_point(get_parent().infected_reference.avoidance_force * get_parent().radius)
	
	$DebugLines/Ahead.clear_points()
	$DebugLines/Ahead.add_point(Vector2.ZERO)
	$DebugLines/Ahead.add_point(cast_to)
	
	if is_colliding():
		$DebugPoint.global_position = get_collision_point()
	else:
		$DebugPoint.position = Vector2.ZERO


func _on_AvoidanceRange_area_entered(area):
	avoidance_enabled = true

