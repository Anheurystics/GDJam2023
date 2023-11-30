extends Pickup

@export var memory_amount: int = 10;

func on_player_picked_up(player: Player):
	if player.can_pickup_memory():
		player.modify_memory(memory_amount);
		player.log_message("Picked up " + str(memory_amount) + " Camera memory");
		super.on_player_picked_up(player);
