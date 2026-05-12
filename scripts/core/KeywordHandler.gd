## KeywordHandler.gd
## Centralised keyword logic — Agent 11 owns this file
class_name KeywordHandler
extends Node

func can_attack_this_turn(card: CardInstance) -> bool:
	if card.has_keyword(CardData.Keyword.RUSH):
		return true
	if card.has_keyword(CardData.Keyword.RUSH_CHARACTER):
		return true  # can attack, but only Characters (checked in BattleResolver)
	return card.turns_on_field > 0

func get_total_power(card: CardInstance) -> int:
	## Delegates to CardInstance — NEVER clamps to 0 (rule 1-3-6-1)
	return card.get_total_power()

func process_blocker(card: CardInstance, attack: Dictionary) -> bool:
	## Must be ACTIVE to block
	if card.is_rested:
		return false
	card.rest()
	attack["target"] = card
	return true

func check_don_threshold(card: CardInstance) -> void:
	## For DON!! ×N effects — enable/disable based on attached_don
	## TODO: Agent 11
	pass

func evaluate_trigger(card: CardInstance, player_idx: int) -> bool:
	## Per rule 2-11-1: Trigger activates INSTEAD of adding to hand
	## Card still goes to hand after activation
	## TODO: Agent 11 — show prompt, enqueue effect
	return false
