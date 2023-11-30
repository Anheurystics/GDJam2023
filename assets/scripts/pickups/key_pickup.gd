@tool
extends Pickup

@export var key_id: String = "";

func _ready():
	super._ready();
	
	update_sprite();
	visibility_changed.connect(update_sprite);

func update_sprite():
	if key_id == "":
		return;
	$Sprite.texture = load("res://assets/freedoom/" + key_id + ".png");

func on_player_picked_up(player: Player):
	player.owned_keys.append(key_id);
	player.log_message("Picked up key");
	super.on_player_picked_up(player);
