extends Interactable

var open: bool = false;

func interact(interactor: Interactor):
	(get_parent() as Door).toggle_open(interactor);
