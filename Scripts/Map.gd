extends Node2D

const TERRAIN_SCENE = preload("res://Scenes/Terrain.tscn")

export(float) var scroll_speed = 2
export(Vector2) var direction = Vector2.DOWN

func add_terrain():
	var terrain = get_child(0)
	var new_terrain = TERRAIN_SCENE.instance()
	new_terrain.global_position += Vector2(terrain.global_position.x, -(terrain.get_node("Road").get_used_rect().size.y * terrain.get_node("Road").cell_size.y))
	add_child(new_terrain)

func _ready():
	add_terrain()
	pass # Replace with function body.

func _physics_process(delta):
	var terrain = get_child(0)
	if terrain.global_position.y >= terrain.get_node("Road").get_used_rect().size.y * terrain.get_node("Road").cell_size.y:
		terrain.queue_free()
		add_terrain()
		
	for c in get_children():
		c.move_local_y(scroll_speed)
