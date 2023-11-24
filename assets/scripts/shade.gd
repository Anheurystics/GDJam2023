class_name Shade extends Enemy

func _ready():
	super._ready();
	set_shaded(true);
	walk_random();
