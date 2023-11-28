extends Pickup

@export var battery_amount: int = 10;

func on_player_picked_up(player: Player):
	player.modify_battery(battery_amount);
	super.on_player_picked_up(player);
