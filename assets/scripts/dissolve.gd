class_name Dissolve extends GeometryInstance3D

@export var duration: float = 3.0;
var particles: GPUParticles3D;
var material: ShaderMaterial;

var curr_amount: float = 0;
var prev_amount: float = 0;

func initialize(p_material: ShaderMaterial):
	material = p_material;
	material.set_shader_parameter("dissolve_started", false);
	material.set_shader_parameter("is_dissolving", false);
	particles = preload("res://assets/scenes/prefabs/darkness_particles.tscn").instantiate();
	add_child(particles);

# 0 - full black
# 1 - none left
func set_dissolve_amount(amount: float):
	curr_amount = amount;
	material.set_shader_parameter("dissolve_started", amount > 0.0);
	if amount > 0.0:
		particles.position.y = lerpf(1.5, -1.5, amount);
		set_shader_y_offset(amount);

func _process(delta):
	particles.emitting = prev_amount != curr_amount;
	material.set_shader_parameter("is_dissolving", particles.emitting);
	if particles.emitting != $SFX.playing:
		if $SFX.playing:
			$SFX.stop();
		else:
			$SFX.play();
	prev_amount = curr_amount;

func is_emitting():
	return particles.emitting;

func dissolve_animation():
	particles.visible = true;
	particles.position.y = 1.5;
	
	var tween = get_tree().create_tween();
	tween.set_parallel(true);
	tween.tween_method(set_shader_y_offset, 0.0, 1.0, duration);
	tween.tween_property(particles, "position:y", -1.5, duration);

	await get_tree().create_timer(duration - 0.2).timeout;
	particles.emitting = false;

func set_shader_y_offset(value: float):
	material.set_shader_parameter("y_cutoff", value);
