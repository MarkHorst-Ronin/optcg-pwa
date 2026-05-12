## CardDatabase.gd
## Autoload singleton — loads all card JSON on startup, serves card data
## Agent 1 owns this file. Do not modify until Agent 1 is complete.
class_name CardDatabase
extends Node

# Populated by _load_set() on _ready()
var _cards: Dictionary = {}          # card_id (String) -> CardData
var _sets: Dictionary = {}           # set_id (String) -> Array[String] card_ids

const CARD_DATA_PATH: String = "res://data/cards/"
const SETS: Array[String] = ["OP01"]

func _ready() -> void:
	for set_id in SETS:
		_load_set(set_id)
	print("[CardDatabase] Loaded %d cards across %d sets." % [_cards.size(), _sets.size()])

func _load_set(set_id: String) -> void:
	var path := CARD_DATA_PATH + set_id + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[CardDatabase] Could not open: " + path)
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Array:
		push_error("[CardDatabase] Invalid JSON in: " + path)
		return
	_sets[set_id] = []
	for card_dict in parsed:
		var card: CardData = _parse_card(card_dict)
		_cards[card.card_id] = card
		_sets[set_id].append(card.card_id)

func _parse_card(_dict: Dictionary) -> CardData:
	# TODO: Agent 1 implements this fully
	var card := CardData.new()
	return card

# ── Public API ────────────────────────────────────────────────────────────────

func get_card(card_id: String) -> CardData:
	return _cards.get(card_id, null)

func get_set(set_id: String) -> Array:
	var ids: Array = _sets.get(set_id, [])
	var result: Array = []
	for id in ids:
		result.append(_cards[id])
	return result

func get_all_cards() -> Array:
	return _cards.values()

func search(filter: CardFilter) -> Array:
	return get_all_cards().filter(func(c: CardData) -> bool: return filter.matches(c))
