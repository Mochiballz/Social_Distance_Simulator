extends KinematicBody2D

class_name Player

export(Vector2) onready var velocity
export(float) onready var speed

export(bool) onready var has_revive = false
var overlapping_infected = false

# Screen Shift Player Movement Variables
signal velocity_change(vel, mag)
var shift_magnitude

func motion_input():
	var input = Vector2.ZERO
	
	input.x += float(Input.is_action_pressed('ui_right'))
	input.x -= float(Input.is_action_pressed('ui_left'))
	input.y -= float(Input.is_action_pressed('ui_up'))
	input.y += float(Input.is_action_pressed('ui_down'))

	if input.length() != 0:
		input = input.normalized()
	
	velocity = input
	emit_signal("velocity_change", velocity, shift_magnitude)
	

func gui_input():
	if Input.is_action_just_pressed("ui_action") and has_revive:
		var infected_bar = get_node("/root/World/Interface/InfectedTimerBar")
		if infected_bar.get_node("Timer").time_left != 0:
			has_revive = false
			infected_bar.get_node("Timer").stop()
			infected_bar.visible = false
			

func motion_animation():
	$AnimatedSprite.play("run")
	if velocity.x < 0:
		$AnimatedSprite.flip_h = true
	elif velocity.x > 0:
		$AnimatedSprite.flip_h = false

# Checks if Infected coughs on player when overlapping
func coughing_check():
	if overlapping_infected:
		for area in $DetectionBox.get_overlapping_areas():
			if area.get_parent() is Infected:
				if area.get_parent().coughing:
					var infected_bar = get_node("/root/World/Interface/InfectedTimerBar")
					if infected_bar.get_node("Timer").is_stopped():
						infected_bar.visible = true
						infected_bar.get_node("Timer").start()
					
func revive_check():
	var revive_sprite = get_node("/root/World/Interface/Items/ReviveContainer/Sprite")
	if has_revive:
		revive_sprite.visible = true
	else:
		revive_sprite.visible = false
		
func _input(event):
	if event is InputEventKey:
		motion_input()
		gui_input()

func _ready():
	velocity = Vector2(0,0)
	speed = 400
	shift_magnitude = 24
	set_physics_process(true)
	
func _physics_process(delta):
	coughing_check()
	revive_check()
	
	motion_animation()
	move_and_slide(velocity * speed * scale)



func _on_DetectionBox_area_entered(area):
	if area.get_parent() is Infected:
		overlapping_infected = true
	if area.get_parent() is Item:
		if area.get_parent().type == area.get_parent().item_type.REVIVE:
			if has_revive:
				return
			else:
				has_revive = true
		area.get_parent().queue_free()


func _on_DetectionBox_area_exited(area):
	if area.get_parent() is Infected:
		if $DetectionBox.get_overlapping_areas().size() <= 1 and $DetectionBox.overlaps_area(area):
			overlapping_infected = false
		else:
			pass
