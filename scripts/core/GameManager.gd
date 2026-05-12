## GameManager.gd
## Top-level orchestrator — wires all modules, manages game modes
## Agent 13 owns this file.
class_name GameManager
extends Node

enum GameMode {
	VS_AI,
	LOCAL_PVP,
	ONLINE_PVP,
	TUTORIAL
}

var current_mode: GameMode = GameMode.VS_AI
var turn_manager: TurnManager = null
var battle_resolver: BattleResolver = null
var damage_handler: DamageHandler = null
var effect_queue: EffectQueue = null
var keyword_handler: KeywordHandler = null
var win_checker: WinConditionChecker = null
var ai_opponent: AIOpponent = null

signal game_started()
signal game_ended(winner_idx: int, win_condition: String)

func _ready() -> void:
	## TODO: Agent 13 — instantiate all modules, connect signals
	pass

func start_game(mode: GameMode, deck_p1: DeckData, deck_p2: DeckData) -> void:
	current_mode = mode
	GameState.reset()
	## TODO: Agent 13 — deal cards, set life, kick off TurnManager
	game_started.emit()

func _on_game_over(winner_idx: int) -> void:
	## TODO: Agent 13 — show WinLoseScreen, post match result to API
	game_ended.emit(winner_idx, "KO")

func _on_turn_ended(player_idx: int) -> void:
	## TODO: Agent 13 — hand off to AI if vs AI mode
	pass
