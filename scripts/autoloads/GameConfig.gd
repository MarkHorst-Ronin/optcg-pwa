## GameConfig.gd
## Autoload singleton — constants and player settings
## Agent: This file is a stub. Do not modify constants without updating PRD.md.
class_name GameConfig
extends Node

# ── Field limits ────────────────────────────────────────────────────────────
const MAX_CHARACTERS_ON_FIELD: int = 5
const MAX_STAGE_CARDS: int = 1
const MAX_COPIES_PER_DECK: int = 4
const DECK_SIZE: int = 50
const DON_DECK_SIZE: int = 10
const STARTING_HAND_SIZE: int = 5
const DON_PER_TURN: int = 2
const DON_FIRST_PLAYER_TURN1: int = 1

# ── Timers (seconds) ─────────────────────────────────────────────────────────
const TURN_TIMER_DEFAULT: int = 90
const BLOCK_STEP_TIMER: int = 30
const COUNTER_STEP_TIMER: int = 30
const TRIGGER_PROMPT_TIMER: int = 20

# ── Player settings (loaded from ConfigFile) ─────────────────────────────────
var animation_speed: float = 1.0       # 0.0 = off, 0.5 = fast, 1.0 = normal
var card_text_size: String = "medium"  # small / medium / large
var colorblind_mode: bool = false
var turn_timer_seconds: int = TURN_TIMER_DEFAULT
var master_volume: float = 1.0

const SETTINGS_PATH: String = "user://settings.cfg"

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		animation_speed  = cfg.get_value("display", "animation_speed", 1.0)
		card_text_size   = cfg.get_value("display", "card_text_size", "medium")
		colorblind_mode  = cfg.get_value("display", "colorblind_mode", false)
		turn_timer_seconds = cfg.get_value("gameplay", "turn_timer", TURN_TIMER_DEFAULT)
		master_volume    = cfg.get_value("audio", "master_volume", 1.0)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display",  "animation_speed",  animation_speed)
	cfg.set_value("display",  "card_text_size",    card_text_size)
	cfg.set_value("display",  "colorblind_mode",   colorblind_mode)
	cfg.set_value("gameplay", "turn_timer",        turn_timer_seconds)
	cfg.set_value("audio",    "master_volume",     master_volume)
	cfg.save(SETTINGS_PATH)
