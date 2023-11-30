class_name Pickup extends Area3D

var picked_up: bool = false;

func _ready():
	picked_up = false;
	body_entered.connect(_on_body_entered);

func _on_body_entered(body):
	if body is Player and !picked_up:
		on_player_picked_up(body as Player);

func on_player_picked_up(player: Player):
	picked_up = true;
	visible = false;
	$SFX.play();
	await $SFX.finished;
	queue_free();
