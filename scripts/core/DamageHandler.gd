## DamageHandler.gd
## Life card reveal and Trigger processing
## Agent 4 owns this file.
## CRITICAL RULES:
## - Loss checked BEFORE popping Life card (rule 1-2-1-1-1)
## - If damage == 0: do nothing (rule 4-6-2-2)
## - Banish: trash Life card, NO Trigger, NO hand add
## - Trigger activates INSTEAD of hand add (rule 2-11-1) — card still goes to hand
## - Double Attack: hit 1 fully resolves before hit 2
class_name DamageHandler
extends Node

signal damage_resolved(player_idx: int, life_card: CardInstance, banished: bool)

## Main entry point — called by BattleResolver after Damage Step
func deal_damage(target_player: int, attacker: CardInstance) -> void:
	var is_double: bool = attacker.has_keyword(CardData.Keyword.DOUBLE_ATTACK)
	var is_banish: bool = attacker.has_keyword(CardData.Keyword.BANISH)
	var hits: int = 2 if is_double else 1

	# If damage value is 0: do nothing (rule 4-6-2-2)
	if hits == 0:
		return

	for i in hits:
		await _process_one_hit(target_player, is_banish)
		# Double Attack: wait for hit 1 to fully resolve before hit 2
		if is_double and i == 0:
			await get_tree().process_frame

func _process_one_hit(player_idx: int, is_banish: bool) -> void:
	## Check loss BEFORE popping Life card (rule 1-2-1-1-1)
	if GameState.get_life_count(player_idx) == 0:
		# Player loses — emit game_over via TurnManager
		# TODO: Agent 4 wires this to TurnManager.game_over signal
		return

	var life_card: CardInstance = GameState.pop_top_life(player_idx)

	if is_banish:
		## Banish: trash the life card. NO Trigger fires. Card NOT added to hand.
		GameState.send_to_trash(life_card, player_idx)
		damage_resolved.emit(player_idx, life_card, true)
	else:
		## Standard damage
		var trigger_activated := false
		if life_card.card_data.has_trigger():
			## Trigger activates INSTEAD of adding to hand (rule 2-11-1)
			## If player activates: enqueue trigger effect
			## Card still goes to hand after trigger resolution
			trigger_activated = await _prompt_trigger(life_card, player_idx)
		GameState.add_to_hand(player_idx, life_card)
		damage_resolved.emit(player_idx, life_card, false)

func _prompt_trigger(_life_card: CardInstance, _player_idx: int) -> bool:
	## TODO: Agent 4 — show TriggerPrompt UI, await player choice
	## Returns true if player chose to activate
	return false
