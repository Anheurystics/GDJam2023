class_name HUD extends CanvasLayer

@onready var viewmodel: Control = $Root/Viewmodel;
@onready var viewfinder: Sprite2D = $Root/Viewmodel/Viewfinder;

@onready var hp: Label = $Root/HP/Value;
@onready var camera: Label = $Root/Camera/Value;
@onready var flashlight: Label = $Root/Flashlight/Value;
@onready var color_overlay: ColorRect = $Root/ColorOverlay
@onready var log_container: VBoxContainer = $Root/Log;

@onready var log_scene = preload("res://assets/scenes/prefabs/log_text.tscn");

var viewmodel_initial_y: float;

const FLASH_ALPHA = 100.0 / 255.0;
const DAMAGE_COLOR: Color = Color(Color.RED, FLASH_ALPHA);
const HEAL_COLOR: Color = Color(Color.GREEN, FLASH_ALPHA);

var log_text_pool: Array = [];

func _ready():
	viewmodel_initial_y = viewmodel.position.y;
	
	var player: Player = get_node("./../Player");
	player.health_changed.connect(_on_health_changed);
	player.memory_changed.connect(_on_memory_changed);
	player.battery_changed.connect(_on_battery_changed);
	player.message_logged.connect(_on_message_logged);

func _on_health_changed(old_health: float, new_health: float, show_flash: bool):
	hp.text = str(floori(new_health));
	if new_health <= 0:
		flash_death();
	elif show_flash:
		if new_health > old_health:
			flash_overlay(HEAL_COLOR);
		elif new_health < old_health:
			flash_overlay(DAMAGE_COLOR);
		
func flash_overlay(color: Color, duration: float = 0.2):
	color_overlay.visible = true;
	color_overlay.color = color;
	var tween: Tween = create_tween();
	tween.tween_property(color_overlay, "color:a", 0, duration);
	await get_tree().create_timer(duration).timeout;
	color_overlay.visible = false;

func flash_death():
	color_overlay.visible = true;
	color_overlay.color = DAMAGE_COLOR;

func _on_memory_changed(_old_memory: int, new_memory: int):
	camera.text = str(new_memory);
	
func _on_battery_changed(old_battery: float, new_battery: float, pulse: bool):
	flashlight.text = str(floori(new_battery));
	if pulse:
		var tween = flashlight.create_tween();
		tween.tween_property(flashlight, "scale", Vector2(1.2, 1.2), 0.2);
		tween.tween_property(flashlight, "scale", Vector2(1.0, 1.0), 0.05);

func update_camera(raised: bool):
	var tween: Tween = get_tree().create_tween();
	if raised:
		viewmodel.scale = Vector2.ONE;
		viewmodel.position.y = viewmodel_initial_y + 125;
		tween.tween_property(viewmodel, "scale", Vector2.ONE * 2, 0.25)
		tween.parallel().tween_property(viewmodel, "position:y", viewmodel_initial_y - 125, 0.25);
	else:
		viewmodel.scale = Vector2.ONE * 2;
		viewmodel.position.y = viewmodel_initial_y;		
		tween.tween_property(viewmodel, "scale", Vector2.ONE, 0.25);
		tween.parallel().tween_property(viewmodel, "position:y", viewmodel_initial_y, 0.25);

func _on_message_logged(message: String, duration: float = 5.0, color: Color = Color.WHITE):
	var log_node: Label = null;
	for l in log_container.get_children():
		if !l.visible:
			log_node = l;
	
	if !log_node:
		log_node = log_scene.instantiate();
		log_container.add_child(log_node);
	
	log_node.visible = true;
	log_node.text = message;
	log_node.set_modulate(color);
	
	get_tree().create_timer(duration).timeout.connect(hide_log.bind(log_node));

func hide_log(log_node: Label):
	log_node.visible = false;
