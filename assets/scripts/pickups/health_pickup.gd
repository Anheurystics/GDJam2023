extends Pickup

@export var health_amount: int = 10;

func on_player_picked_up(player: Player):
	if player.can_pickup_health():
		player.modify_health(health_amount);
		player.log_message("Picked up " + str(health_amount) + " HP");
		super.on_player_picked_up(player);
