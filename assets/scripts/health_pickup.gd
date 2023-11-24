extends Pickup

func on_player_picked_up(player: Player):
	player.modify_health(10);
	super.on_player_picked_up(player);
