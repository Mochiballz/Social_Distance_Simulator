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
		
	func add_infected(s : float, n : int, b, f, o : int, sp : Array, st : float, e : float = -1, d : float = 0.0, atp : bool = false):
		var infected_template = EntityTemplate.new()
		infected_template.speed = s
		infected_template.entity_number = n
		infected_template.behavior = b
		infected_template.formation = f
		infected_template.odds = o
		infected_template.spawners = sp
		infected_template.spawn_rate_start = st
		infected_template.spawn_rate_end = st if e == -1 else e
		infected_template.spawn_delay = d
		infected_template.aim_to_player = atp
		
		in_queue.push_back(infected_template)
		
	func add_item(s : float, n : int, b, f, o : int, sp : Array, st: float, e : float = -1, d : float = 0.0, atp : bool = false):
		var item_template = EntityTemplate.new()
		item_template.speed = s
		item_template.entity_number = n
		item_template.behavior = b
		item_template.formation = f
		item_template.odds = o
		item_template.spawners = sp
		item_template.spawn_rate_start = st
		item_template.spawn_rate_end = st if e == -1 else e
		item_template.spawn_delay = d
		item_template.aim_to_player = atp
		
		it_queue.push_back(item_template)
		
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

func _ready():
	var spawnpoint_range = range(0, get_node("/root/World/Spawners").get_child_count() - 1)
	var reduced_spawnpoints = spawnpoint_range.slice(spawnpoint_range[1], spawnpoint_range[spawnpoint_range.size() - 1])
	
	var round_0 = Round.new(80.0)
	var round_1 = Round.new(30.0, 1)
	var round_2 = Round.new(10.0)
	var round_3 = Round.new()
	
	# Round 0 + Item
	var round_0_infected = [
#        Speed   Number   Behavior               Formation                 Odds   Spawners             Rate Start   Rate End   Delay   AtP
		[300,    1,       single_state.LINEAR,   group_state.WAVE_RANDOM,  4,     reduced_spawnpoints, 0.2,         0.6,       0.0,    false],
		[400,    1,       single_state.LINEAR,   group_state.WAVE_STATIC,  4,     reduced_spawnpoints, 1.0,         2.0,       0.0,    true],
	]
	var item = [
		[0,      1,       single_state.LINEAR,   group_state.WAVE_STATIC,  1,     spawnpoint_range,    2.0,        2.0]
		
	]
	
	var items = [
		[0,      1,       single_state.LINEAR,   group_state.WAVE_STATIC,  1,     spawnpoint_range,    2.0,        2.0],
		[0,      1,       single_state.LINEAR,   group_state.WAVE_STATIC,  1,     spawnpoint_range,    5.0,        5.0]
		
	]
	
	# Round 1
	var round_1_infected = [
		[300,    1,       single_state.LINEAR,   group_state.WAVE_STATIC,  4,     spawnpoint_range,    1.0,         1.0,       0.0,    true],
		[300,    1,       single_state.CURVE,    group_state.WAVE_STATIC,  3,     spawnpoint_range,    1.0,         1.0,       0.0,    true],
		[220,    1,       single_state.LOOP,     group_state.WAVE_STATIC,  3,     spawnpoint_range,    1.0,         1.0,       0.0,    false],
#		[220,    3,       single_state.LINEAR,   group_state.WAVE_DIVERGE, 2,     spawnpoint_range,    1.0,         1.0,       0.0,    true]
	]
	
	# Round 2
	var round_2_infected = [
		[220,    5,       single_state.SINUSOID, group_state.WAVE_DIVERGE, 1,     spawnpoint_range,    4.0,         4.0,       0.0,    false]
	]
	
	round_queue = [ round_0, round_1, round_2 ]
	var round_infected = [ round_0_infected, round_1_infected, round_2_infected ]
	var round_item = [ item, item, item ]
	
	for i in range(round_queue.size()):
		for j in round_infected[i]:
			round_queue[i].add_infected(j[0], j[1], j[2], j[3], j[4], j[5], j[6], j[7], j[8], j[9])
		for k in round_item[i]:
			round_queue[i].add_item(k[0], k[1], k[2], k[3], k[4], k[5], k[6], k[7])
	
