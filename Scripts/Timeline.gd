extends Node

enum single_state {LINEAR, CURVE, LOOP, STOP, SINUSOID, DAMPEN}
enum group_state {WAVE_STATIC, WAVE_DIVERGE, WAVE_CONVERGE, WAVE_RANDOM, BLAST_UNIFORM, BLAST_RANDOM}

# --- ENTITY TEMPLATE ---
# Determines individual enemy/item stats when spawned
# 
class EntityTemplate:
	var speed : float
	var entity_number : int
	var entity_color : String
	var type : String
	
	var behavior
	var formation
	
	var odds : int
	var spawners : Array
	var spawn_rate_start : float # Starting bound for how often entity spawns
	var spawn_rate_end : float # End bound for entity spawning, constant rate if start = end
	var spawn_delay : float # Wait time before spawning begins
	
	var aim_to_player : bool # AtP
	var seek_to_player : bool

var round_queue : Array = []

# --- ROUND CLASS ---
# Parameters that determine attributes for spawning enemies and items, 
# entity spawn direction, etc.

class Round:
	var duration : float # Duration of time for round
	var ordered : int # 0: Not ordered, 1: Infected/items ordered separately, 2: Together
	var index = 0 # Records position of order in which entities are spawned, infected only at the moment
	
	# Infected/Item Templates
	var in_queue : Array = []
	var it_queue : Array = []

	func _init(d : float = 0.0, o : int = 0):
		duration = d
		ordered = o
	
	func add_entity(json):
		var template = EntityTemplate.new()
		
		template.speed = json["speed"]
		template.entity_number = json["entity_number"]
		if "entity_color" in json:
			template.entity_color = json["entity_color"]
		template.type = json["entity_type"]
		
		template.behavior = json["behavior_array"]
		template.formation = int(json["formation_array"])
		
		template.odds = json["odds"]
		template.spawners = json["spawners"]
		
		template.spawn_rate_start = json["spawner_rate_start"]
		template.spawn_rate_end = json["spawner_rate_end"]
		template.spawn_delay = json["spawner_delay"]
		
		template.aim_to_player = json["aim_to_player"]
		template.seek_to_player = json["seek_to_player"]
		
		if template.type == "infected":
			in_queue.push_back(template)
		elif template.type == "item":
			it_queue.push_back(template)
		else:
			pass
			
	func add_entities(list):
		for e in list:
			self.add_entity(e)
		
	func infected_odds_total():
		var odds_total = 0
		for e in in_queue:
			odds_total += e.odds
		return odds_total
	
	func item_odds_total():
		var odds_total = 0
		for e in it_queue:
			odds_total += e.odds
		return odds_total
	
	func select_ordered_infected():
		var count = 0
		for e in in_queue:
			e.spawn_delay = count
			count += e.spawn_rate_end
			
	
	func select_rand_infected():
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		
		var draw = rng.randi_range(1, infected_odds_total())
		var count = 0
		for e in in_queue:
			count += e.odds
			if draw <= count:
				return e
				
				
	func select_rand_item():
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		
		var draw = rng.randi_range(1, item_odds_total())
		var count = 0
		for e in it_queue:
			count += e.odds
			if draw <= count:
				return e
				
	func select_infected():
		if ordered:
			return select_ordered_infected()
		else:
			return select_rand_infected()
			
	func change_difficulty(n): # n = the magnitude of difficulty increase (n = 1 does nothing)
		for i in in_queue:
			i.spawn_rate_start = i.spawn_rate_start * n
			i.spawn_rate_end = i.spawn_rate_end * n
		

func parse_template(filename):
	var file = File.new()
	file.open(filename, file.READ)
	var json_text = file.get_as_text()
	file.close()
	return parse_json(json_text)

func _ready():
	# Spawnpoint Ranges
	var spawnpoints_range = range(0, get_node("/root/World/Spawners").get_child_count() - 1)
	var spawnpoints_size = spawnpoints_range.size()
	
	var spawnpoints_left = spawnpoints_range.slice(0, (spawnpoints_size / 2))
	var spawnpoints_right = spawnpoints_range.slice((spawnpoints_size / 2), spawnpoints_size - 1)
	var spawnpoints_ends = [0, 1, spawnpoints_size - 2, spawnpoints_size - 1]
	var spawnpoints_no_ends = spawnpoints_range.slice(1, spawnpoints_range.size() - 2)
	var spawnpoints_center = [spawnpoints_size / 2]
	
	var round_0 = Round.new(20.0)
	var round_1 = Round.new(20.0)
	var round_2 = Round.new(12.0)
	var round_3 = Round.new(30.0)
	var round_4 = Round.new()
	
	# IMPORT JSON DATA - Infected/Item Types
	# Parse .json files to dictionaries
	var infected_default = parse_template("res://Data/infected_default.json")
	var infected_pair = parse_template("res://Data/infected_default.json")
	var infected_curve = parse_template("res://Data/infected_default.json")
	var infected_stop = parse_template("res://Data/infected_default.json")
	var infected_karen = parse_template("res://Data/infected_karen.json")
	var infected_fast = parse_template("res://Data/infected_default.json")
	var infected_blast = parse_template("res://Data/infected_default.json")
	var item_revive = parse_template("res://Data/item_revive.json")
	
	# Modify variables
	# Pair
	infected_pair["entity_number"] = 2
	
	# Curve
	var curve_behavior = { "behavior" : 1, "duration" : 3.5, "direction" : "cross"}
	infected_curve["behavior_array"][0]["duration"] = 0.2
	infected_curve["behavior_array"].push_back(curve_behavior)
	
	# Stop
	var stop_behavior = { "behavior" : 3, "duration" : 2}
	infected_stop["entity_color"] = "blue"
	infected_stop["behavior_array"].push_back(stop_behavior)
	infected_stop["seek_to_player"] = true
	
	# Fast
	var diag_behavior = { "behavior" : 0, "duration" : 1.0, "direction" : "diagonal"}
	infected_fast["speed"] *= 3
	infected_fast["spawner_rate_start"] = 1
	infected_fast["spawner_rate_end"] = 2
	infected_fast["behavior_array"][0] = diag_behavior
	
	# Blast
	var curve_seek = { "behavior" : 1, "duration" : 2 }
	infected_blast["entity_number"] = 5
	infected_blast["spawner_rate_start"] = 4
	infected_blast["spawner_rate_end"] = 5
	infected_blast["spawner_delay"] = 2
	infected_blast["formation_array"] = 4
	infected_blast["seek_to_player"] = true
	infected_blast["behavior_array"][0]["duration"] = 2.5
	infected_blast["behavior_array"].push_back(curve_seek)
	
	
	for inf in [infected_pair, infected_curve, infected_stop]:
		inf["spawner_rate_start"] = 2.0
		inf["spawner_rate_end"] = 2.5
	
	# Set spawnpoints
	infected_default["spawners"] = spawnpoints_range
	infected_pair["spawners"] = spawnpoints_range
	infected_curve["spawners"] = spawnpoints_ends
	infected_stop["spawners"] = spawnpoints_range
	infected_karen["spawners"] = spawnpoints_range
	infected_fast["spawners"] = spawnpoints_ends
	infected_blast["spawners"] = spawnpoints_center
	item_revive["spawners"] = spawnpoints_range
	
	# CREATE ROUND ARRAYS
	var entity_list_0 = [infected_default, infected_karen, infected_pair]
	var entity_test = [infected_stop]
	var entity_list_1 = [infected_default, infected_pair, infected_fast, item_revive]
	var entity_list_2 = [infected_default, infected_pair, infected_curve, infected_stop]
	var entity_list_3 = [infected_blast]

	round_0.add_entities(entity_list_0)
	round_1.add_entities(entity_list_1)
	round_2.add_entities(entity_list_2)
	round_3.add_entities(entity_list_3)
	round_queue = [ round_3 ]

