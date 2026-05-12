## BoardView.gd
## Visual representation of the game board — listens to GameState signals
## Agent 8 owns this file.
class_name BoardView
extends Node2D

signal card_clicked(card: CardInstance, zone: int)
signal end_turn_pressed()
signal zone_clicked(zone: int, player_idx: int)

func _ready() -> void:
	pass  ## TODO: Agent 8 — connect GameState signals, build zone nodes

func show_card_played(player_idx: int, card_id: String, zone_index: int) -> void:
	pass  ## TODO: Agent 8

func update_phase_indicator(phase: int) -> void:
	pass  ## TODO: Agent 8

func show_power_compare(attacker_power: int, defender_power: int) -> void:
	pass  ## TODO: Agent 8

func log_action(text: String) -> void:
	pass  ## TODO: Agent 8
