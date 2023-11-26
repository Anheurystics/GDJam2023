extends CanvasLayer

var is_paused: bool = false;

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
	if event.is_action_pressed("quick_save"):
		Progress.save_game();
	if event.is_action_pressed("quick_load"):
		Progress.load_game();

func toggle_pause():
	is_paused = !is_paused;
	visible = is_paused;
	get_tree().paused = is_paused;
