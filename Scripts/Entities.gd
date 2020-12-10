extends YSort

const INFECTED_SCENE = preload("res://Scenes/Infected.tscn")

var time
var spawn_rng

var infected = INFECTED_SCENE.instance()

var last_spawner_id = -1

export(float) var spawn_time_start_bound = 1.5
export(float) var spawn_time_end_bound = 4

export(float) var difficulty_increase_wait_time = 2
export(float) var time_decrease = 0.99
export(float) var infected_speed = 35.0

func create_spawn_points(n):
	var viewport_size = get_viewport_rect().size
	

func spawn_infected():
	var spawners_instance = get_node("../Spawners")
	var rng = RandomNumberGenerator.new()
	
	rng.randomize()
	var spawner_id = rng.randi_range(0, spawners_instance.get_child_count() - 1)
	if spawner_id == last_spawner_id:
		spawner_id = (spawner_id + 1) % spawners_instance.get_child_count()
		
	var spawn_point = spawners_instance.get_child(spawner_id)
	var player_direction = spawn_point.global_position.direction_to($Player.global_position)
	
	spawn_point.angle_vector = player_direction
	spawn_point.direction = spawn_point.angle_vector
	spawn_point.spacing = infected.get_node("InfectionRange/CollisionShape2D").shape.radius * infected.scale.x
	
	spawn_point.spawn(INFECTED_SCENE)
	last_spawner_id = spawner_id
	
	for e in spawn_point.entities:
		e.speed = infected_speed
		add_child(e)
	


func _ready():
	time = 0
	spawn_rng = RandomNumberGenerator.new()
	
	spawn_rng.randomize()
	$SpawnTimer.set_wait_time(spawn_rng.randf_range(spawn_time_start_bound, spawn_time_end_bound))
	$SpawnTimer.connect("timeout", self, "_on_SpawnTimer_timeout")
	
	$DifficultyTimer.set_wait_time(difficulty_increase_wait_time)
	$DifficultyTimer.connect("timeout", self, "_on_DifficultyTimer_timeout")
	
	spawn_infected()
	$SpawnTimer.start()
	$DifficultyTimer.start()
	
	set_process(true)
	
func _process(delta):
	time += delta
	
func _on_SpawnTimer_timeout():
	spawn_infected()
	$SpawnTimer.set_wait_time(spawn_rng.randf_range(spawn_time_start_bound, spawn_time_end_bound))
	$SpawnTimer.start()
	
func _on_DifficultyTimer_timeout():
	spawn_time_start_bound *= time_decrease
	spawn_time_end_bound *= time_decrease
	
	var k = 0.02480128
	infected_speed = $Player.speed * 2 / (1 + exp(-k * (time - 60)))

	$DifficultyTimer.start()
	

