class_name Pickup extends Area3D

func _ready():
	body_entered.connect(_on_body_entered);

func _on_body_entered(body):
	if body is Player:
		on_player_picked_up(body as Player);

func on_player_picked_up(player: Player):
	queue_free();
