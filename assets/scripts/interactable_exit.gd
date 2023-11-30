extends Interactable

func interact(interactor: Interactor):
	LevelManager.load_next_level(true);
