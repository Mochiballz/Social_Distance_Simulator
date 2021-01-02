extends Area2D

var overlapping_infected = false
var repel_enabled = true
var overlapping_infected_ids = {} # 

# Exerts force on itself from overlapping 'Infected' instances, has 'cushion' 
# behavior from 'mag' variable
func repel_force(enabled):
	if enabled:
		var net_force = Vector2.ZERO
	#	var max_force_length = 0
		
		if overlapping_infected:
			for area in get_overlapping_areas():
				
				if area.get_parent() is Infected:
					var direction = area.global_position.direction_to(global_position)
					var distance = global_position.distance_to(area.global_position) / get_parent().scale.length()
					var distance_max = min($CollisionShape2D.shape.radius, area.get_node("CollisionShape2D").shape.radius) * 2
		
					var area_force = distance * direction
		#			if(area_force.length() > max_force_length):
		#				max_force_length = area_force.length()
					
					var mag = get_parent().magnitude * ease(1 - (area_force.length() / distance_max), 6)
					net_force = net_force + (area_force * mag)
					
				elif area.get_parent() is Player:
					pass
					
				else:
					continue
	#		net_force = net_force.clamped(max_force_length)
			
		else:
			net_force = Vector2.ZERO
	
		get_parent().acceleration = net_force
	else:
		get_parent().acceleration = Vector2.ZERO

# Draws line of where the overlap of two infection ranges exist (DEBUG)
func draw_overlap_line():
	if overlapping_infected:
		
		for area in get_overlapping_areas():
			if area.get_parent() is Infected:
				var area_id = area.get_instance_id()
				
				var direction = global_position.direction_to(area.global_position)
				var distance_vector = (direction * global_position.distance_to(area.global_position)) / get_parent().scale
				
				var overlap_start = distance_vector - (direction * area.get_node("CollisionShape2D").shape.radius)
				var overlap_end = direction * $CollisionShape2D.shape.radius
				
				if overlapping_infected_ids.has(area_id):
					var overlap_line = instance_from_id(overlapping_infected_ids[area_id])
					
					overlap_line.points[0] = overlap_start
					overlap_line.points[1] = overlap_end
					
					continue
				else:
					var new_line = Line2D.new()
					var new_line_id = new_line.get_instance_id()
					
					new_line.width = 2.0
					new_line.default_color = Color(0,1,0,1)
		
					new_line.add_point(overlap_start)
					new_line.add_point(overlap_end)
		
					overlapping_infected_ids[area_id] = new_line_id
		
					$OverlapLines.add_child(new_line)
					
			else:
				continue
			

func _ready():
	set_physics_process(true)
	
func _physics_process(delta):
#	draw_overlap_line()
	repel_force(repel_enabled)
	pass


func _on_InfectionRange_area_entered(area):
	if area.get_parent() is Infected:
		overlapping_infected = true

func _on_InfectionRange_area_exited(area):
	# Deletes Line2D in InfectionRange and erases instance id from overlapping_infected_ids
	var area_id = area.get_instance_id()
	if area_id in overlapping_infected_ids:
		instance_from_id(overlapping_infected_ids[area_id]).queue_free()
		overlapping_infected_ids.erase(area_id)
	
	if get_overlapping_areas().size() == 0:
		overlapping_infected = false

func _on_InfectionRange_body_entered(body):
	if body is Player:
		print(name + " has detected the player")



