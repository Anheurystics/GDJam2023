class_name Shade extends Enemy

func get_speed():
	if player_target:
		return 2;
	else:
		return 1;

