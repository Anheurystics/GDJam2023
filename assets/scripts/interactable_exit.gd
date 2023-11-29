extends Interactable

func interact(interactor: Interactor):
	get_tree().reload_current_scene();
