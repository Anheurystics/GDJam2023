extends VBoxContainer

@onready var new_game_button: Button = $NewGameButton;
@onready var continue_button: Button = $ContinueButton;

func _ready():
	LevelManager.current_level = -1;
	new_game_button.pressed.connect(_on_new_game_button_pressed);
	continue_button.pressed.connect(_on_continue_button_pressed);

func _on_new_game_button_pressed():
	LevelManager.load_next_level(false);

func _on_continue_button_pressed():
	Progress.load_game();
