extends Interactable

var open: bool = false;

func interact():
	open = !open;
	
	var tween = get_tree().create_tween();
	var parent: StaticBody3D = get_parent();
	var visual = parent.find_child("Visual");
	if open:
		tween.tween_property(visual, "position:y", 5, .5);
		await tween.finished
		parent.set_collision_layer_value(1, false);
		parent.set_collision_layer_value(2, true);
	else:
		tween.tween_property(visual, "position:y", 0, .5);
		await tween.finished
		parent.set_collision_layer_value(1, true);
		parent.set_collision_layer_value(2, false);
