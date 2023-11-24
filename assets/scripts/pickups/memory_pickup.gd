extends Pickup

var memory_amount: int = 10;

func on_player_picked_up(player: Player):
	player.modify_battery(memory_amount);
	super.on_player_picked_up(player);
