extends VBoxContainer

@onready var new_game_button: Button = $NewGame/NewGameButton;
@onready var continue_button: Button = $Continue/ContinueButton;

func _ready():
	new_game_button.pressed.connect(_on_new_game_button_pressed);
	continue_button.pressed.connect(_on_continue_button_pressed);

func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("res://assets/scenes/levels/e1m1.tscn");

func _on_continue_button_pressed():
	Progress.load_game();
