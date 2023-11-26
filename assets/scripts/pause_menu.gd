extends CanvasLayer

var is_paused: bool = false;

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
	if event.is_action_pressed("quick_save"):
		quick_save();
	if event.is_action_pressed("quick_load"):
		quick_load();

func toggle_pause():
	is_paused = !is_paused;
	visible = is_paused;
	get_tree().paused = is_paused;

func quick_save():
	var save = FileAccess.open("user://zoom.save", FileAccess.WRITE);
	var final_map = {};
	for node in get_tree().get_nodes_in_group("persist"):
		if node.has_method("serialize"):
			final_map[node.get_path()] = node.serialize();
	save.store_buffer(var_to_bytes(final_map));
	save.close();
	print("Saved to " + save.get_path_absolute());

func quick_load():
	var save = FileAccess.open("user://zoom.save", FileAccess.READ);
	get_tree().reload_current_scene();
	var data = bytes_to_var(save.get_buffer(save.get_length()));
	for node_path in data:
		var node = get_node(node_path);
		if node and node.has_method("deserialize"):
			node.deserialize(data[node_path]);
	save.close();
