extends Control

func _ready():
	pass


func _on_Player_velocity_change(vel, mag):
	var tween = get_node("Tween")
	var last_rect_position = rect_position
	tween.interpolate_property(self, "rect_position",
		rect_position, vel * mag, 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
