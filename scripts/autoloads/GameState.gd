## GameState.gd
## Autoload singleton — single source of truth for all live match data
## Agent 2 owns this file. Pure data operations — no rules logic, no rendering.
class_name GameState
extends Node

# ── Per-player state (index 0 = player 1, index 1 = player 2) ────────────────
var leaders:        Array          = [null, null]
var characters:     Array          = [[], []]
var stages:         Array          = [null, null]
var hands:          Array          = [[], []]
var decks:          Array          = [[], []]
var don_cost_areas: Array          = [[], []]
var don_decks:      Array          = [[], []]
var life_areas:     Array          = [[], []]
var trash_piles:    Array          = [[], []]

var active_player:  int            = 0
var turn_number:    int            = 1

# ── Signals ───────────────────────────────────────────────────────────────────
signal card_moved(card, from_zone, to_zone, player_idx)
signal don_attached(card, player_idx)
signal don_returned(count, player_idx, as_active)
signal state_reset()

# ── Setup ─────────────────────────────────────────────────────────────────────

func reset() -> void:
	leaders        = [null, null]
	characters     = [[], []]
	stages         = [null, null]
	hands          = [[], []]
	decks          = [[], []]
	don_cost_areas = [[], []]
	don_decks      = [[], []]
	life_areas     = [[], []]
	trash_piles    = [[], []]
	active_player  = 0
	turn_number    = 1
	state_reset.emit()

# ── Card movement ─────────────────────────────────────────────────────────────
# TODO: Agent 2 implements all methods below

func move_card(_card: CardInstance, _from_zone: int, _to_zone: int, _player_idx: int) -> void:
	pass

func send_to_trash(_card: CardInstance, _player_idx: int) -> void:
	pass

func add_to_hand(_player_idx: int, _card: CardInstance) -> void:
	pass

func pop_top_life(_player_idx: int) -> CardInstance:
	return null

func pop_top_deck(_player_idx: int) -> CardInstance:
	return null

# ── Queries ───────────────────────────────────────────────────────────────────

func get_leader(_player_idx: int) -> CardInstance:
	return leaders[_player_idx]

func get_characters(_player_idx: int) -> Array:
	return characters[_player_idx]

func get_life_count(_player_idx: int) -> int:
	return life_areas[_player_idx].size()

func get_deck_size(_player_idx: int) -> int:
	return decks[_player_idx].size()

func get_hand_size(_player_idx: int) -> int:
	return hands[_player_idx].size()

func get_don_count(_player_idx: int) -> int:
	var count := 0
	for don in don_cost_areas[_player_idx]:
		if not don.is_rested:
			count += 1
	return count

func get_hand(_player_idx: int) -> Array:
	return hands[_player_idx]

# ── DON!! management ──────────────────────────────────────────────────────────

func add_don_to_cost(_player_idx: int, _count: int) -> void:
	pass

func attach_don_to_card(_card: CardInstance, _player_idx: int) -> void:
	pass

func return_attached_don(_card: CardInstance, _as_active: bool) -> void:
	pass

# ── Validation (pure — no side effects) ───────────────────────────────────────

func can_play_card(_player_idx: int, _card_id: String) -> bool:
	return false

func can_attack(_player_idx: int, _card_id: String) -> bool:
	return false

func get_valid_attack_targets(_player_idx: int) -> Array:
	return []

# ── AI simulation ─────────────────────────────────────────────────────────────

func clone() -> GameState:
	# TODO: Agent 2 implements deep copy
	return GameState.new()

func apply_play(_card: CardInstance, _player_idx: int) -> void:
	pass

func get_playable_cards(_player_idx: int, _budget: int) -> Array:
	return []

func get_attackable(_player_idx: int) -> Array:
	return []
