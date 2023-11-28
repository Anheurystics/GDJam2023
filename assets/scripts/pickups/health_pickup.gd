extends Pickup

@export var health_amount: int = 10;

func on_player_picked_up(player: Player):
	player.modify_health(health_amount);
	super.on_player_picked_up(player);
