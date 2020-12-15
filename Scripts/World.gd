extends Node2D

# GENERAL CONSTANTS
const TIME_PERIOD = 0.1 # Period of time to earn 'one' point

# ENTITY/ITEM SCENES
const INFECTED_SCENE = preload("res://Scenes/Infected.tscn")
const ITEM_SCENE = preload("res://Scenes/Item.tscn")

# General Variables
export(int) var round_index
export(int) var points
export(bool) var game_over

var current_round
var current_in # Used for ordered rounds
var current_it

# Spawner Variables
var spawn_rng
var last_spawner_id = -1

# Entity Variables
var infected = INFECTED_SCENE.instance()

# Creates spawn timers for entity templates of current round
func create_spawn_timers():
	for i in range(current_round.in_queue.size()):
		var spawn_timer = Timer.new()
		var e = current_round.in_queue[i] # Current entity
		
		if current_round.ordered >= 1:
			if i == current_in:
				spawn_timer.set_paused(false)
			else:
				spawn_timer.set_paused(true)
		
		var rand_wait_time = spawn_rng.randf_range(e.spawn_rate_start, e.spawn_rate_end)
		spawn_timer.set_wait_time(rand_wait_time)
		spawn_timer.connect("timeout", self, "_on_SpawnTimer_timeout", [e, spawn_timer])
		
		$SpawnTimers/InfectedTimers.add_child(spawn_timer)
	
	for i in range(current_round.it_queue.size()):
		var spawn_timer = Timer.new()
		var e = current_round.it_queue[i]
		
		if current_round.ordered == 2:
			if i == current_it:
				spawn_timer.set_paused(false)
			else:
				spawn_timer.set_paused(true)
		
		spawn_timer.set_wait_time(spawn_rng.randf_range(e.spawn_rate_start, e.spawn_rate_end))
		spawn_timer.connect("timeout", self, "_on_SpawnTimer_timeout", [e, spawn_timer])
		
		$SpawnTimers/ItemTimers.add_child(spawn_timer)
	
func start_spawn_timers():
	for t in ($SpawnTimers/InfectedTimers.get_children() + $SpawnTimers/ItemTimers.get_children()):
		t.start()

	
func clear_spawn_timers():
	for t in ($SpawnTimers/InfectedTimers.get_children() + $SpawnTimers/ItemTimers.get_children()):
		t.stop()
		t.queue_free()

func spawn_infected(infected_template):
	var spawners_instance = $Spawners
	
	# Spawnpoint Selection: Picks random index from the infected template's spawner list
	var spawner_index = spawn_rng.randi_range(0, infected_template.spawners.size() - 1) # Index
	var spawner_id = infected_template.spawners[spawner_index] # ID to use for spawners_instance
#	if spawner_id == last_spawner_id:
#		spawner_id = infected_template.spawners[(spawner_index + 1) % infected_template.spawners.size()]
		
	var spawn_point = spawners_instance.get_child(spawner_id)
	
	# Load Template to Spawn Point
	spawn_point.load_template(infected_template)
	
	# Other Spawn Point Parameters
	spawn_point.spacing = infected.get_node("InfectionRange/CollisionShape2D").shape.radius * 2
	
	spawn_point.spawn(INFECTED_SCENE)
#	last_spawner_id = spawner_id
	
	for e in spawn_point.entities:
		e.speed = infected_template.speed
		$Entities.add_child(e)


func spawn_item(item_template):
	var spawners_instance = $Spawners
	var map_scroll_speed = $Map.scroll_speed
	var map_direction = $Map.direction

	var spawner_id = spawn_rng.randi_range(0, item_template.spawners.size() - 1)
	var spawn_point = spawners_instance.get_child(spawner_id)
	
	# Spawn Point Behavior/Formation
	spawn_point.entity_behavior = item_template.behavior
	spawn_point.formation = item_template.formation
	
	# Other Spawn Point Parameters
	spawn_point.entity_number = item_template.entity_number
	spawn_point.angle_vector = map_direction
	spawn_point.direction = spawn_point.angle_vector
	
	spawn_point.spawn(ITEM_SCENE)
	
	for e in spawn_point.entities:
		e.speed = map_scroll_speed
		$Entities.add_child(e)


func infected_timer_update():
	var bar = $Interface/InfectedTimerBar
	var timer = bar.get_node("Timer")
	if timer.time_left != 0:
		bar.value = (timer.time_left / timer.wait_time) * bar.max_value

func pause_check():
	if game_over:
		print("GAME OVER!")
		get_tree().paused = true
		$Interface/GameOver.show()
		


func _ready():
	# General Variable Inits
	round_index = 0
	points = 0
	game_over = false
	current_round = $Timeline.round_queue[round_index]
	current_in = 0
	current_it = 0
	
	spawn_rng = RandomNumberGenerator.new()
	spawn_rng.randomize()
	
	$RoundTimer.set_wait_time(current_round.duration)
	$RoundTimer.connect("timeout", self, "_on_RoundTimer_timeout")
	create_spawn_timers()
	
	$RoundTimer.start()
	start_spawn_timers()
	
	set_physics_process(true)
	

func _physics_process(delta):
	pause_check()
	infected_timer_update()
	if not get_node("Entities/Player").overlapping_infected:
		points += delta / TIME_PERIOD
	
	$Interface/Score/Points.text = String(int(points))

func _on_RoundTimer_timeout():
	clear_spawn_timers()
	round_index = (round_index + 1) % $Timeline.round_queue.size()
	current_round = $Timeline.round_queue[round_index]
	current_in = 0
	current_it = 0
	
	$RoundTimer.set_wait_time(current_round.duration)
	create_spawn_timers()
	
	$RoundTimer.start()
	start_spawn_timers()

# Spawner Signal Functions
func _on_SpawnTimer_timeout(template, timer):
	var is_item = false
	if template.speed > 0:
		spawn_infected(template)
		print("Infected spawned")
	else:
		is_item = true
		spawn_item(template)
		print("Item spawned")
	
	if current_round.ordered > 0:
		var timers
		var current
		if not is_item:
			timers = $SpawnTimers/InfectedTimers
			current = timers.get_child(current_in)
			current.set_paused(true)
		else:
			timers = $SpawnTimers/ItemTimers
			current = timers.get_child(current_it)
			if current_round.ordered == 2:
				current.set_paused(true)
		
		var queue_size = timers.get_children().size()
		var next
		var next_template
		
		if not is_item:
			current_in = (current_in + 1) % queue_size
			next = timers.get_child(current_in)
			next_template = current_round.in_queue[current_in]
		else:
			current_it = (current_it + 1) % queue_size
			next = timers.get_child(current_it)
			next_template = current_round.it_queue[current_it]
		
		next.set_wait_time(spawn_rng.randf_range(next_template.spawn_rate_start, next_template.spawn_rate_end))
		next.set_paused(false)
	
	var rand_wait_time = spawn_rng.randf_range(template.spawn_rate_start, template.spawn_rate_end)
	print(rand_wait_time)
	timer.set_wait_time(rand_wait_time)
	timer.start()
	

func _on_Retry_pressed():
	game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()
	

func _on_Quit_pressed():
	get_tree().quit()


func _on_Timer_timeout():
	game_over = true
