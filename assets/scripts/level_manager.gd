extends Node

var levels = ["e1m1", "e1m2", "e1m3"];
var current_level: int = -1; # -1: menu

var persist_player_stats: bool = false;

func load_next_level(p_persist: bool):
	current_level += 1;
	if current_level < levels.size():
		get_tree().change_scene_to_file("res://assets/scenes/levels/" + levels[current_level] + ".tscn");
	else:
		load_menu();

func load_level(name: String):
	current_level = levels.find(name);
	if current_level > -1:
		get_tree().change_scene_to_file("res://assets/scenes/levels/" + name + ".tscn");

func get_current_level_name():
	return levels[current_level];

func load_menu():
	current_level = -1;
	get_tree().change_scene_to_file("res://assets/scenes/levels/menu.tscn");
	
