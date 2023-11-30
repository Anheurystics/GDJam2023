extends Node

const SAVE_LOCATION = "user://zoom.save";
var quick_load_cache = {};

func save_game():
	var save = FileAccess.open(SAVE_LOCATION, FileAccess.WRITE);
	var final_map = {"level": LevelManager.get_current_level_name()};
	for node in get_tree().get_nodes_in_group("persist"):
		if node.has_method("serialize"):
			final_map[node.get_path()] = node.serialize();
	save.store_buffer(var_to_bytes(final_map));
	save.close();
	print("Saved to " + save.get_path_absolute());

func load_game():
	var save = FileAccess.open(SAVE_LOCATION, FileAccess.READ);
	Progress.quick_load_cache = bytes_to_var(save.get_buffer(save.get_length()));
	save.close();
	LevelManager.load_level(Progress.quick_load_cache["level"]);
