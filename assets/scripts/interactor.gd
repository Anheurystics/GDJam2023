extends Node3D

func interact():
	var g_basis = global_transform.basis;
	var forward = g_basis.z;
	
	var space_state = get_world_3d().direct_space_state;
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - (forward * 2));
	var result = space_state.intersect_ray(query);	
	if result && result.collider:
		var interactable = result.collider.find_child("Interactable");
		if interactable:
			interactable.interact();
