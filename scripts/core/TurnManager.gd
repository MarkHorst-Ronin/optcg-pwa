## TurnManager.gd
## 5-phase turn state machine
## Agent 3 owns this file. Depends on GameState (Agent 2).
class_name TurnManager
extends Node

enum Phase {
	REFRESH,
	DRAW,
	DON,
	MAIN,
	END
}

# ── Signals ───────────────────────────────────────────────────────────────────
signal phase_changed(new_phase: Phase)
signal turn_ended(player_idx: int)
signal game_over(winner_idx: int)
signal draw_required(player_idx: int)

# ── State ─────────────────────────────────────────────────────────────────────
var current_phase: Phase = Phase.REFRESH
var _first_turn: bool = true

# ── Phase advancement ─────────────────────────────────────────────────────────
## TODO: Agent 3 implements all phase logic below

func start_game() -> void:
	_first_turn = true
	GameState.active_player = 0
	GameState.turn_number = 1
	await _run_phase(Phase.DON)

func advance_phase() -> void:
	match current_phase:
		Phase.REFRESH: await _run_phase(Phase.DRAW)
		Phase.DRAW:    await _run_phase(Phase.DON)
		Phase.DON:     await _run_phase(Phase.MAIN)
		Phase.MAIN:    await _run_phase(Phase.END)
		Phase.END:     _end_turn()

func _run_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)
	match phase:
		Phase.REFRESH: await _do_refresh()
		Phase.DRAW:    await _do_draw()
		Phase.DON:     await _do_don()
		Phase.MAIN:    pass  # Player-driven — awaits UI actions
		Phase.END:     await _do_end()

func _do_refresh() -> void:
	## CRITICAL: Per Rule Manual v1.11:
	## 1. Set ALL rested cards as active
	## 2. Return attached DON!! to cost area AS ACTIVE (not rested)
	pass  # TODO: Agent 3

func _do_draw() -> void:
	## First player skips draw on turn 1
	## Check deck-out BEFORE drawing
	pass  # TODO: Agent 3

func _do_don() -> void:
	## Add 2 DON!! (1 if first player turn 1)
	## If don_deck empty: add nothing
	pass  # TODO: Agent 3

func _do_end() -> void:
	## End Phase — exact 4-step order per Rule Manual v1.11:
	## 1. Turn player [End of Your Turn] effects
	## 2. Non-turn player [End of Your Turn] effects
	## 3. Turn player "during this turn" effects cancelled
	## 4. Non-turn player "during this turn" effects cancelled
	pass  # TODO: Agent 3

func _end_turn() -> void:
	_first_turn = false
	turn_ended.emit(GameState.active_player)
	GameState.active_player = 1 - GameState.active_player
	GameState.turn_number += 1
	await _run_phase(Phase.REFRESH)

func end_main_phase() -> void:
	## Called by player pressing End Turn button
	await _run_phase(Phase.END)
