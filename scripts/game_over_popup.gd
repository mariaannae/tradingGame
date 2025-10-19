extends Control

signal restart_requested

@onready var panel = $Panel
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

var final_money: int = 0
var final_turn: int = 0

func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	hide()

func show_game_over(money: int, turn: int) -> void:
	final_money = money
	final_turn = turn
	
	if stats_label:
		stats_label.text = "You survived %d turns!\nFinal money: %d" % [turn, money]
	
	show()
	# Bring to front
	move_to_front()

func _on_restart_pressed() -> void:
	restart_requested.emit()
	hide()
