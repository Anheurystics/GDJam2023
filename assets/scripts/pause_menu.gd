extends CanvasLayer

var is_paused: bool = false;

@onready var exit_button = $ColorRect/ExitButton;

func _ready():
	exit_button.pressed.connect(LevelManager.load_menu);

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
	if event.is_action_pressed("quick_save"):
		Progress.save_game();
		get_parent().find_child("Player").log_message("Game saved");
	if event.is_action_pressed("quick_load"):
		Progress.load_game();
		get_parent().find_child("Player").log_message("Game loaded");

func toggle_pause():
	is_paused = !is_paused;
	visible = is_paused;
	get_tree().paused = is_paused;
