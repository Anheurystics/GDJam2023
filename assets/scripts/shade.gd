class_name Shade extends Enemy

func get_speed():
	if player_target:
		return 2;
	else:
		return 1;

func reward_on_death(player: Player):
	player.modify_battery(10, true);
