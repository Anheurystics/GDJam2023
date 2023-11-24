class_name Shade extends Enemy

var is_following_player: bool = false;

var attack_interval;

func _ready():
	super._ready();
	set_shaded(false);
	walk_random();

func _process(delta):
	super._process(delta);
	if player_target and not is_following_player:
		is_following_player = true;
		navigate_to(player_target.global_position);
		
	if is_following_player:
		if not player_target:
			is_following_player = false;
		else:
			var diff = player_target.global_position - global_position;
			diff.y = 0;
			if diff.length() < 2.0 and not is_attacking:
				attack(player_target);

func _on_nav_agent_navigation_finished():
	if is_following_player:
		navigate_to(player_target.global_position);
	else:
		super._on_nav_agent_navigation_finished()
	
