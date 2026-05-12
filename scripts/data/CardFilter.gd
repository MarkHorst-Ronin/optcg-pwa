## CardFilter.gd
## Filter criteria for CardDatabase.search()
## Used by Deck Builder UI (Agent 9).
class_name CardFilter
extends RefCounted

var colors:    Array[int] = []    # empty = any color
var card_type: int = -1           # -1 = any type
var min_cost:  int = 0
var max_cost:  int = 99
var keywords:  Array[int] = []    # empty = any keywords
var set_ids:   Array[String] = [] # empty = all sets
var text:      String = ""        # name search

func matches(card: CardData) -> bool:
	if colors.size() > 0:
		var found := false
		for c in colors:
			if card.has_color(c):
				found = true
				break
		if not found:
			return false

	if card_type != -1 and card.card_type != card_type:
		return false

	if card.cost < min_cost or card.cost > max_cost:
		return false

	for kw in keywords:
		if not card.has_keyword(kw):
			return false

	if set_ids.size() > 0 and card.set_id not in set_ids:
		return false

	if text != "" and not card.card_name.to_lower().contains(text.to_lower()):
		return false

	return true
