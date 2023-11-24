extends StaticBody3D

var open: bool = false;

func set_open():
	open = !open;
	
	var tween = get_tree().create_tween();
	var sprite = find_child("Sprite3D");
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
