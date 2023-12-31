@tool
class_name Door extends StaticBody3D

var open: bool = false;
var locked = false;
@export var can_enemy_open: bool = true;
@export var can_only_open: bool = false;
@export var required_key: String = "";

func _ready():
	if required_key != "":
		locked = true;
	update_sprite();
	visibility_changed.connect(update_sprite);

func update_sprite():
	if required_key == "":
		return;
	var tex = load("res://assets/freedoom/" + required_key + ".png");
	$Visual/KeyIconFront.texture = tex;
	$Visual/KeyIconBack.texture = tex;

func toggle_open(interactor: Interactor):
	set_open(!open, interactor);

func set_open(p_open: bool, interactor: Interactor):
	if !p_open && can_only_open:
		return;
	
	if p_open && locked:
		var player: Player = interactor.get_parent() as Player;
		if player:
			var key_index = player.owned_keys.find(required_key);
			if key_index >= 0:
				player.log_message("Door unlocked!");
				player.owned_keys.remove_at(key_index);
				locked = false;
			else:
				player.log_message("Door is locked");
				return;
		else:
			return;

	open = p_open;

	var tween = get_tree().create_tween();
	var sprite = find_child("Visual");
	if open:
		$SFX/Open.play();
		tween.tween_property(sprite, "position:y", 5, .5);
		await tween.finished
		set_collision_layer_value(1, false);
		set_collision_layer_value(2, true);
	else:
		$SFX/Close.play();
		tween.tween_property(sprite, "position:y", 0, .5);
		await tween.finished
		set_collision_layer_value(1, true);
		set_collision_layer_value(2, false);

func serialize():
	return {
		"open": open
	}

func deserialize(data):
	set_open(data.open, null);
