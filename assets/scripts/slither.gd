class_name Slither extends Enemy

func get_speed():
	if player_target:
		return 5;
	else:
		return 1;
