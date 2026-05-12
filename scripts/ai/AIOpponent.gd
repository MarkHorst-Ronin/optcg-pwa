## AIOpponent.gd
## Three-tier AI opponent (Easy / Medium / Hard)
## Agent 10 owns this file. Depends on GameState (Agent 2) + BattleResolver (Agent 4).
class_name AIOpponent
extends Node

enum Difficulty { EASY, MEDIUM, HARD }

@export_group("Difficulty")
@export var difficulty: Difficulty = Difficulty.MEDIUM

@export_group("Heuristic Weights (Medium)")
@export var weight_life_diff:    float = 15.0
@export var weight_board_power:  float = 0.001
@export var weight_card_count:   float = 8.0
@export var weight_blocker:      float = 12.0
@export var weight_rush_bonus:   float = 6.0
@export var weight_double_atk:   float = 10.0
@export var weight_field_full:   float = -8.0

const AI_PLAYER: int = 1
const HUMAN_PLAYER: int = 0

signal action_complete()

# ── Main Phase Decision ───────────────────────────────────────────────────────

func decide_main_phase() -> void:
	match difficulty:
		Difficulty.EASY:   await _easy_main()
		Difficulty.MEDIUM: await _medium_main()
		Difficulty.HARD:   await _hard_main()
	action_complete.emit()

func _easy_main() -> void:
	## Play highest-cost affordable card, always attack Leader
	## TODO: Agent 10
	pass

func _medium_main() -> void:
	## Heuristic scoring
	## TODO: Agent 10
	pass

func _hard_main() -> void:
	## MCTS-lite (simulate top 20 sequences)
	## TODO: Agent 10
	pass

# ── Block Decision ────────────────────────────────────────────────────────────

func decide_block(_attack: Dictionary) -> CardInstance:
	## Returns a Blocker CardInstance or null
	## TODO: Agent 10
	return null

# ── Counter Decision ──────────────────────────────────────────────────────────

func decide_counter(_attack: Dictionary) -> Array:
	## Returns array of card_ids to discard as counters
	## TODO: Agent 10
	return []

# ── Trigger Decision ──────────────────────────────────────────────────────────

func decide_trigger(_card: CardInstance) -> bool:
	## Returns true if AI should activate the Trigger
	## Easy/Medium: always activate
	## Hard: evaluate board state first
	return true

# ── Scoring helpers (Medium) ──────────────────────────────────────────────────

func _score_play(card: CardInstance, _state: GameState) -> float:
	var score: float = 0.0
	score += card.card_data.power * weight_board_power
	score += card.card_data.cost * 2.0
	if card.has_keyword(CardData.Keyword.RUSH):          score += weight_rush_bonus
	if card.has_keyword(CardData.Keyword.BLOCKER):       score += weight_blocker
	if card.has_keyword(CardData.Keyword.DOUBLE_ATTACK): score += weight_double_atk
	if GameState.get_characters(AI_PLAYER).size() >= 5:  score += weight_field_full
	return score

func _decide_don_reserve() -> int:
	## Keep 2 DON!! if opponent has 6000+ attacker and we have a Counter Event
	## TODO: Agent 10
	return 0
