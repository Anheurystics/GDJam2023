extends CanvasLayer

var is_paused: bool = false;

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause();

func toggle_pause():
	is_paused = !is_paused;
	visible = is_paused;
	get_tree().paused = is_paused;
