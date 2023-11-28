extends Pickup

@export var key_id: String = "";

func on_player_picked_up(player: Player):
	player.owned_keys.append(key_id);
	player.log_message("Picked up " + key_id);
	super.on_player_picked_up(player);
