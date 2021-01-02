extends RayCast2D

var avoidance_enabled = false

func avoidance_force(enabled):
	if enabled and is_colliding():
		var ahead = global_position + cast_to
		var force = ahead - get_collider().global_position
		force = force.normalized()
		
		get_parent().infected_reference.avoidance_force = get_collision_normal() * get_parent().radius
	else:
		get_parent().infected_reference.avoidance_force = Vector2.ZERO
		avoidance_enabled = false

func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
	cast_to = get_parent().infected_reference.velocity * get_parent().radius
	avoidance_force(avoidance_enabled)
	
	$DebugLine.clear_points()
	$DebugLine.add_point(Vector2.ZERO)
	$DebugLine.add_point(get_parent().infected_reference.acceleration * get_parent().radius)


func _on_AvoidanceRange_area_entered(area):
	avoidance_enabled = true

