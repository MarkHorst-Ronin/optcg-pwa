## CardData.gd
## Static resource — loaded from JSON, read-only at runtime
## Agent 1 owns this file.
class_name CardData
extends Resource

# ── Enums ─────────────────────────────────────────────────────────────────────

enum CardType {
	LEADER,
	CHARACTER,
	EVENT,
	STAGE,
	DON
}

enum Color {
	RED,
	GREEN,
	BLUE,
	PURPLE,
	BLACK,
	YELLOW
}

enum Keyword {
	RUSH,
	RUSH_CHARACTER,
	DOUBLE_ATTACK,
	BANISH,
	BLOCKER,
	TRIGGER,
	COUNTER,
	DON_X,
	DON_MINUS
}

enum Attribute {
	SLASH,
	STRIKE,
	RANGED,
	SPECIAL,
	WISDOM,
	UNKNOWN
}

enum EffectType {
	DRAW,
	SEARCH,
	DISCARD,
	BOUNCE,
	TRASH,
	POWER_MOD,
	COST_REDUCE,
	REST_TARGET,
	UNREST,
	ADD_LIFE,
	REMOVE_LIFE,
	LOOK_LIFE,
	REORDER_LIFE,
	BANISH_TARGET,
	PLAY_FROM_TRASH,
	GIVE_DON,
	CANNOT_ATTACK,
	CANNOT_BE_KOD
}

enum EffectTiming {
	ON_PLAY,
	ON_KO,
	WHEN_ATTACKING,
	WHEN_ATTACKED,
	MAIN,
	ACTIVATE,
	END_OF_TURN,
	END_OPP_TURN,
	TRIGGER,
	COUNTER,
	DON_X,
	PERMANENT
}

# ── Fields ────────────────────────────────────────────────────────────────────

@export var card_id:        String = ""
@export var card_name:      String = ""
@export var card_type:      CardType = CardType.CHARACTER
@export var colors:         Array[int] = []   # Array of Color enum values
@export var cost:           int = 0
@export var power:          int = 0           # May be modified to negative at runtime
@export var life:           int = 0           # Leaders only
@export var counter:        int = 0           # 0 / 1000 / 2000
@export var attributes:     Array[int] = []   # Array of Attribute enum values
@export var types:          Array[String] = []
@export var keywords:       Array[int] = []   # Array of Keyword enum values
@export var effects:        Array = []        # Array of EffectData
@export var trigger_effect: Resource = null   # EffectData or null
@export var art:            String = ""       # texture path
@export var rarity:         String = ""       # C / U / R / SR / L
@export var set_id:         String = ""       # OP01, OP02, etc.

# ── Helpers ───────────────────────────────────────────────────────────────────

func has_keyword(kw: Keyword) -> bool:
	return kw in keywords

func has_color(c: Color) -> bool:
	return c in colors

func has_trigger() -> bool:
	return trigger_effect != null

func is_leader() -> bool:
	return card_type == CardType.LEADER

func is_character() -> bool:
	return card_type == CardType.CHARACTER
