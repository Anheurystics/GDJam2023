class_name Regen extends Enemy

@export var regen_after_seconds: float = 3.0;
@export var regen_per_second: float = 2.0;

var last_damage_ms: int = 0;

func get_speed():
	if should_regen():
		return 1;
	else:
		return 2;

func deal_damage(value: float, player: Player):
	super.deal_damage(value, player);
	last_damage_ms = Time.get_ticks_msec();

func _process(delta: float):
	super._process(delta);
	if should_regen():
		health = min(health + (regen_per_second * delta), max_health);
		dissolve.set_dissolve_amount(1.0 - (float(health) / max_health));

func should_regen():
	return Time.get_ticks_msec() - last_damage_ms > regen_after_seconds * 1000;

func reward_on_death(player: Player):
	player.modify_battery(10);
	player.modify_memory(5);
