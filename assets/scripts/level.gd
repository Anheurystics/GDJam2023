extends Node3D

func _ready():
	if Progress.quick_load_cache:
		for node in get_tree().get_nodes_in_group("persist"):
			var path = node.get_path();
			if Progress.quick_load_cache.has(path):
				if node.has_method("deserialize"):
					node.deserialize(Progress.quick_load_cache[path]);
			else:
				node.queue_free();
		Progress.quick_load_cache = {};
