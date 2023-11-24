class_name HUD extends CanvasLayer

@onready var viewmodel: Control = $Root/Viewmodel;
@onready var viewfinder: Sprite2D = $Root/Viewmodel/Viewfinder;

@onready var hp: Label = $Root/Stats/HP;
@onready var camera: Label = $Root/Stats/Camera;
@onready var flashlight: Label = $Root/Stats/Flashlight;

var viewmodel_initial_y: float;

func _ready():
	viewmodel_initial_y = viewmodel.position.y;
	
	var player: Player = get_node("./../Player");
	player.health_changed.connect(_on_health_changed);
	player.memory_changed.connect(_on_memory_changed);
	player.battery_changed.connect(_on_battery_changed);

func _on_health_changed(health: int):
	hp.text = "HP: " + str(health);

func _on_memory_changed(memory: int):
	hp.text = "Camera: " + str(memory);
	
func _on_battery_changed(battery: int):
	hp.text = "Flashlight: " + str(battery);

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
