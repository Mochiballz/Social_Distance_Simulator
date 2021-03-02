extends Area2D

var infected_reference
var radius

func _ready():
	infected_reference = get_parent()
	radius = infected_reference.get_node("InfectionRange/CollisionShape2D").shape.radius
	
	$CollisionShape2D.shape.radius = radius
