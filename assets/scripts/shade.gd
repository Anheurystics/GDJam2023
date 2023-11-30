class_name Shade extends Enemy

var attack_timer: Timer;

func _ready():
	await super._ready();
	
	attack_timer = Timer.new();
	attack_timer.one_shot = false;
	attack_timer.timeout.connect(attack_target);
	add_child(attack_timer);

func _process(delta):
	super._process(delta);

	if is_following_player:
		if not player_target:
			attack_timer.stop();
			is_following_player = false;
		else:
			if attack_timer and attack_timer.is_stopped():
				attack_timer.start(1.0);

	if attack_timer and not attack_timer.is_stopped():
		var diff = player_target.global_position - global_position;
		diff.y = 0; 
		attack_timer.paused = diff.length() > 2.0

func attack_target():
	if player_target:
		attack(player_target);

func _on_nav_agent_navigation_finished():
	if is_following_player:
		navigate_to(player_target.global_position);
	else:
		super._on_nav_agent_navigation_finished()

func get_speed():
	if player_target:
		return 2;
	else:
		return 1;

func on_death():
	attack_timer.stop();
	super.on_death();

