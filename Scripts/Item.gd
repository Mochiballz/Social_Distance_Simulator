extends KinematicBody2D

class_name Item
enum item_type {REVIVE, BOOST}

export(item_type) var type
export(Vector2) var velocity = Vector2.DOWN
export(float) var speed = 1.0

var old_velocity
var old_speed
func _ready():
	pass

func _physics_process(delta):
	move_and_collide(velocity * speed)

func _on_VisibilityNotifier2D_screen_exited():
	print(name + " has left")
	queue_free()
