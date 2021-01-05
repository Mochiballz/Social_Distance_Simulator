extends Node2D

enum single_state {LINEAR, CURVE, LOOP, STOP, SINUSOID}
enum group_state {WAVE_STATIC, WAVE_DIVERGE, WAVE_CONVERGE, WAVE_RANDOM, BLAST_UNIFORM, BLAST_RANDOM}

# ENTITY/SPAWN POINT VARIABLES
# New instances will be made each "spawn()" call
export var entities = []
export(int) var entity_number
export(Array) var entity_behavior
export(group_state) var formation

export(float) var angle # The angle at which the wave/blast is facing
var angle_vector
export(Vector2) var direction # The direction each individual entity follows
export(Vector2) var offset # The offset relative to the spawn point's position

export(bool) var aim_to_player = false # If true, spawn point will aim entities towards last player location

# FORMATION VARIABLES
export(float) var spacing
export(int) var gap_position # If no gap desired, set to -1

# Wave Ray Variables
export(float) var diverge_speed
export(float) var converge_speed

# Random Variables
export(float) var random_speed_bound # Value should be under 1

# Blast Variables
export(float) var blast_arc
export(int) var blast_layers

func _ready():
	entity_behavior = single_state.LINEAR
	formation = group_state.WAVE_STATIC
	
	angle = 3 * PI / 2
	angle_vector = polar2cartesian(1, -angle)

	direction = angle_vector
	offset = Vector2.ZERO
	
	gap_position = -1
	
	diverge_speed = 0.2
	converge_speed = -0.2
	
	random_speed_bound = 0.05
	
	blast_arc = PI / 3
	blast_layers = 1

	
func load_template(temp):
	entity_behavior = temp.behavior
	formation = temp.formation
	aim_to_player = temp.aim_to_player
	entity_number = temp.entity_number
	

func set_angle_vec_to_player():
	angle_vector = global_position.direction_to(get_node("/root/World/Entities/Player").global_position)

func spawn(entity_type):
	entities.clear()
	
	# Set/Reset Direction for Entities to Player/Default
	if aim_to_player:
		set_angle_vec_to_player()
		direction = angle_vector
	else:
		angle_vector = polar2cartesian(1, -angle)
		direction = angle_vector
	
	match formation:
		group_state.WAVE_STATIC:
			entities = create_wave_static(entity_type)
		group_state.WAVE_DIVERGE:
			entities = create_wave_ray(entity_type, diverge_speed)
		group_state.WAVE_CONVERGE:
			entities = create_wave_ray(entity_type, converge_speed)
		group_state.WAVE_RANDOM:
			entities = create_wave_random(entity_type)
		group_state.BLAST_UNIFORM:
			entities = create_blast_uniform(entity_type)
		group_state.BLAST_RANDOM:
			entities = create_blast_random(entity_type)
		_:
			print("No enumeration found")
			pass
			
	

func wave_alignment(i): # Creates the entity offset for wave formations
	var alignment
	if i == gap_position:
		i += 1
	
	# Proportion that will distribute each entity evenly, floating number
	var distribution = i - ((entity_number - 1) / 2.0)
	var space = spacing * distribution
	
	alignment = (angle_vector.tangent() * space) + offset
	
	return alignment
	
func blast_alignment(i, layer, num):
	var alignment
	var arc = blast_arc - (blast_arc / num)
	if i == gap_position:
		i += 1
		
	var percentage = 1 - ((2.0 * i) / (num - 1))
	var blast_angle = (arc / 2.0) * percentage
	var blast_angle_vector = angle_vector.rotated(blast_angle)
	
	# Offsets each layer in blast backwards
	var layer_offset = spacing * layer
	var arc_alignment = (blast_angle_vector - angle_vector) * spacing
	var dir_alignment = blast_angle_vector * layer_offset * 2
	alignment = arc_alignment - dir_alignment
	
	return alignment

func create_wave_static(entity_type) -> Array:
	var entity_group = []
	
	for i in entity_number:
		var entity = entity_type.instance()
		var entity_alignment = wave_alignment(i)
		
		entity.position = global_position + entity_alignment
		entity.velocity = direction
		entity.behavior_array = entity_behavior
		entity_group.push_back(entity)
		
	return entity_group


func create_wave_ray(entity_type, speed) -> Array:
	var entity_group = []
	
	for i in entity_number:
		var entity = entity_type.instance()
		var entity_alignment = wave_alignment(i)
		
		# Creates a vector for convergence/divergence 
		# Proportionate to the entity's position in the wave * speed
		# Positive speed = divergence, negative speed = convergence
		var distribution = i - ((entity_number - 1) / 2.0)
		var ray_vector = angle_vector.tangent() * distribution * speed
		
		entity.position = global_position + entity_alignment
		entity.velocity = direction + ray_vector
		entity.behavior_array = entity_behavior
		
		entity_group.push_back(entity)
		
	return entity_group


func create_wave_random(entity_type) -> Array:
	var entity_group = []
	
	for i in entity_number:
		var entity = entity_type.instance()
		var entity_alignment = wave_alignment(i)
		
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var random_speed = rng.randf_range(-random_speed_bound, random_speed_bound)
		var random_vector = angle_vector.tangent() * random_speed
		
		entity.position = global_position + entity_alignment
		entity.velocity = (direction + random_vector).clamped(1.0)
		entity.behavior_array = entity_behavior
		
		entity_group.push_back(entity)
	
	return entity_group
	
func create_blast_uniform(entity_type) -> Array:
	var entity_group = []
	var arc = blast_arc
	
	for layer in blast_layers:
		var layer_entities = entity_number - layer
		
		for i in layer_entities:
			var entity = entity_type.instance()
			var entity_alignment = blast_alignment(i, layer, layer_entities)
			
			var percentage = 1 - ((2.0 * i) / (layer_entities - 1))
			var blast_angle = (arc / 2.0) * percentage
			
			entity.position = global_position + entity_alignment
			entity.velocity = direction.rotated(blast_angle)
			entity.behavior_array = entity_behavior
			
			entity_group.push_back(entity)
		
		arc -= arc / layer_entities
		
	return entity_group
	
func create_blast_random(entity_type) -> Array:
	var entity_group = []
	var arc = blast_arc
	
	for layer in blast_layers:
		var layer_entities = entity_number - layer
		
		for i in layer_entities:
			var entity = entity_type.instance()
			var entity_alignment = blast_alignment(i, layer, layer_entities)
			
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			var random_angle = rng.randf_range(-(arc / 2.0), (arc / 2.0))
			
			entity.position = global_position + entity_alignment
			entity.velocity = direction.rotated(random_angle)
			entity.behavior_array = entity_behavior
			
			entity_group.push_back(entity)
			
		arc -= arc / layer_entities
		
	return entity_group
	


