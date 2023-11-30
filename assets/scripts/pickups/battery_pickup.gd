extends Pickup

@export var battery_amount: int = 10;

func on_player_picked_up(player: Player):
	if player.can_pickup_battery():
		player.modify_battery(battery_amount, true);
		player.log_message("Picked up " + str(battery_amount) + " Flashlight battery");
		super.on_player_picked_up(player);
