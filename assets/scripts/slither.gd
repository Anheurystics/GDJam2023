class_name Slither extends Enemy

func get_speed():
	if player_target:
		return 5;
	else:
		return 1;

func reward_on_death(player: Player):
	player.modify_health(10);
	player.modify_memory(1);
