extends RayCast2D

var infected_reference
var radius

func _ready():
	infected_reference = get_parent()
	radius = infected_reference.get_node("InfectionRange/CollisionShape2D").shape.radius
	
	$DebugLine.add_point(Vector2.ZERO)
	$DebugLine.add_point(cast_to)
	set_physics_process(true)
	
func _physics_process(delta):
	cast_to = infected_reference.velocity * radius * 2
	$DebugLine.clear_points()
	$DebugLine.add_point(Vector2.ZERO)
	$DebugLine.add_point(cast_to)
