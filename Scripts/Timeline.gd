extends Node

enum single_state {LINEAR, CURVE, LOOP, STOP, SINUSOID}
enum group_state {WAVE_STATIC, WAVE_DIVERGE, WAVE_CONVERGE, WAVE_RANDOM, BLAST_UNIFORM, BLAST_RANDOM}

# --- ENTITY TEMPLATE ---
# Determines individual enemy/item stats when spawned
# 
class EntityTemplate:
	var speed : float
	var entity_number : int
	
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
		
		template.behavior = json["behavior_array"]
		template.formation = int(json["formation_array"])
		
		template.odds = json["odds"]
		template.spawners = json["spawners"]
		
		template.spawn_rate_start = json["spawner_rate_start"]
		template.spawn_rate_end = json["spawner_rate_end"]
		template.spawn_delay = json["spawner_delay"]
		
		template.aim_to_player = json["aim_to_player"]
		template.seek_to_player = json["seek_to_player"]
		
		if json["entity_type"] == "infected":
			in_queue.push_back(template)
		elif json["entity_type"] == "item":
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
		

func _ready():
	var spawnpoints_range = range(0, get_node("/root/World/Spawners").get_child_count() - 1)
	var spawnpoints_size = spawnpoints_range.size()
	
	var spawnpoints_left = spawnpoints_range.slice(0, (spawnpoints_size / 2))
	var spawnpoints_right = spawnpoints_range.slice((spawnpoints_size / 2), spawnpoints_size - 1)
	var spawnpoints_ends = [0, 1, spawnpoints_size - 2, spawnpoints_size - 1]
	var spawnpoints_no_ends = spawnpoints_range.slice(1, spawnpoints_range.size() - 2)
	var spawnpoints_center = [spawnpoints_size / 2]
	
	var round_0 = Round.new(60.0)
	var round_1 = Round.new(30.0)
	var round_2 = Round.new(80.0, 1)
	var round_3 = Round.new()
	
	# IMPORT JSON DATA - Infected/Item Types
	# Infected Default
	var file_infected_default = File.new()
	var file_infected_karen = File.new()
	var file_item_revive = File.new()
	var file_infected_loop_atp = File.new()
	
	file_infected_default.open("res://Data/infected_default.json", file_infected_default.READ)
	file_infected_karen.open("res://Data/infected_karen.json", file_infected_karen.READ)
	file_item_revive.open("res://Data/item_revive.json", file_item_revive.READ)
	file_infected_loop_atp.open("res://Data/infected_loop_atp.json", file_item_revive.READ)
	
	var json_infected_default = file_infected_default.get_as_text()
	var json_infected_karen = file_infected_karen.get_as_text()
	var json_item_revive = file_item_revive.get_as_text()
	var json_infected_loop_atp = file_infected_loop_atp.get_as_text()
	
	var infected_default = parse_json(json_infected_default)
	var infected_karen = parse_json(json_infected_karen)
	var item_revive = parse_json(json_item_revive)
	var infected_loop_atp = parse_json(json_infected_loop_atp)
	
	file_infected_default.close()
	file_infected_karen.close()
	file_item_revive.close()
	file_infected_loop_atp.close()
	
	# CREATE ROUND ARRAYS
	
	# Modify template variables
	
	# Set spawnpoints
	infected_default["spawners"] = spawnpoints_range
	infected_karen["spawners"] = spawnpoints_range
	item_revive["spawners"] = spawnpoints_range
	infected_loop_atp["spawners"] = spawnpoints_no_ends

	var entity_list_0 = [infected_karen, item_revive]

	round_0.add_entities(entity_list_0)
	round_queue = [ round_0 ]

