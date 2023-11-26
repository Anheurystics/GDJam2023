extends Node3D

func _ready():
	if Progress.quick_load_cache:
		for node_path in Progress.quick_load_cache:
			var node = get_node(node_path);
			if node and node.has_method("deserialize"):
				node.deserialize(Progress.quick_load_cache[node_path]);
		Progress.quick_load_cache = {};
