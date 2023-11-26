class_name Door extends StaticBody3D

var open: bool = false;
@export var can_enemy_open: bool = true;
@export var can_only_open: bool = false;

func toggle_open():
	if open and can_only_open:
		return;
		
	open = !open;
	
	var tween = get_tree().create_tween();
	var sprite = find_child("Visual");
	if open:
		tween.tween_property(sprite, "position:y", 5, .5);
		await tween.finished
		set_collision_layer_value(1, false);
		set_collision_layer_value(2, true);
	else:
		tween.tween_property(sprite, "position:y", 0, .5);
		await tween.finished
		set_collision_layer_value(1, true);
		set_collision_layer_value(2, false);
