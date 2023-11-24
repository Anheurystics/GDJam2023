class_name HUD extends CanvasLayer

@onready var viewmodel: Control = $Root/Viewmodel;
@onready var viewfinder: Sprite2D = $Root/Viewmodel/Viewfinder;

@onready var hp: Label = $Root/Stats/HP;
@onready var camera: Label = $Root/Stats/Camera;
@onready var flashlight: Label = $Root/Stats/Flashlight;
@onready var color_overlay: ColorRect = $Root/ColorOverlay

var viewmodel_initial_y: float;

const FLASH_ALPHA = 100.0 / 255.0;
const DAMAGE_COLOR: Color = Color(Color.RED, FLASH_ALPHA);
const HEAL_COLOR: Color = Color(Color.GREEN, FLASH_ALPHA);

func _ready():
	viewmodel_initial_y = viewmodel.position.y;
	
	var player: Player = get_node("./../Player");
	player.health_changed.connect(_on_health_changed);
	player.memory_changed.connect(_on_memory_changed);
	player.battery_changed.connect(_on_battery_changed);

func _on_health_changed(old_health: float, new_health: float):
	hp.text = "HP: " + str(floori(new_health));
	if new_health > old_health:
		flash_damage(HEAL_COLOR);
	elif new_health < old_health:
		flash_damage(DAMAGE_COLOR);

func flash_damage(color: Color, duration: float = 0.2):
	color_overlay.visible = true;
	color_overlay.color = color;
	var tween: Tween = create_tween();
	tween.tween_property(color_overlay, "color:a", 0, duration);
	await get_tree().create_timer(duration).timeout;
	color_overlay.visible = false;

func _on_memory_changed(_old_memory: int, new_memory: int):
	camera.text = "Camera: " + str(new_memory);
	
func _on_battery_changed(_old_battery: float, new_battery: float):
	flashlight.text = "Flashlight: " + str(floori(new_battery));

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
