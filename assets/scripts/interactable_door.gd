extends Interactable

var open: bool = false;

func interact():
	(get_parent() as Door).toggle_open();
