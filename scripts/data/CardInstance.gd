## CardInstance.gd
## Runtime card with live mutable state — wraps CardData
## Agent 2 owns this file.
class_name CardInstance
extends RefCounted

# ── Static card data (read-only reference) ────────────────────────────────────
var card_data: CardData = null

# ── Runtime state ─────────────────────────────────────────────────────────────
var is_rested:      bool = false
var attached_don:   int  = 0
var turns_on_field: int  = 0          # 0 = played this turn
var owner_id:       int  = 0          # 0 or 1

# Power modifiers — see CLAUDE.md rule 4: power CAN go negative
var temp_power_mods: Array[int] = []  # cleared after each battle ends
var perm_power_mods: Array[int] = []  # cleared at End Phase or as specified

# ── Power calculation ─────────────────────────────────────────────────────────
## ⚠️ NEVER clamp to 0 — per Comprehensive Rules 1-3-6-1
## Power CAN be negative. Card stays on field even at negative power.
func get_total_power() -> int:
	if card_data == null:
		return 0
	var base: int = card_data.power
	var don_bonus: int = attached_don * 1000
	var perm_total: int = 0
	for mod in perm_power_mods:
		perm_total += mod
	var temp_total: int = 0
	for mod in temp_power_mods:
		temp_total += mod
	# Do NOT clamp. Return actual value, which may be negative.
	return base + don_bonus + perm_total + temp_total

func add_battle_mod(amount: int) -> void:
	temp_power_mods.append(amount)

func clear_battle_mods() -> void:
	temp_power_mods.clear()

func clear_eot_mods() -> void:
	# Remove mods that expire at End of Turn
	# TODO: Agent 2 implements duration tracking
	perm_power_mods.clear()

func has_keyword(kw: CardData.Keyword) -> bool:
	if card_data == null:
		return false
	return card_data.has_keyword(kw)

func rest() -> void:
	is_rested = true

func set_active() -> void:
	is_rested = false
