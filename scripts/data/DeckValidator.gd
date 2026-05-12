## DeckValidator.gd
## Validates deck construction rules per PRD section 6
## Agent 9 owns this file.
class_name DeckValidator
extends RefCounted

class ValidationResult:
	var valid:  bool = false
	var errors: Array[String] = []

	func _init(is_valid: bool, errs: Array[String]) -> void:
		valid  = is_valid
		errors = errs

func validate(deck: DeckData) -> ValidationResult:
	var errors: Array[String] = []

	# Rule 1: Exactly 50 cards
	if deck.card_list.size() != 50:
		errors.append("Deck must have exactly 50 cards (has %d)" % deck.card_list.size())

	# Rule 2: Exactly 1 Leader
	if deck.leader_id == "":
		errors.append("No Leader card selected")

	var leader: CardData = CardDatabase.get_card(deck.leader_id)
	if leader == null and deck.leader_id != "":
		errors.append("Leader card not found: " + deck.leader_id)

	# Rule 3: Max 4 copies per card_id
	var counts: Dictionary = deck.get_card_counts()
	for card_id in counts:
		if counts[card_id] > 4:
			var card: CardData = CardDatabase.get_card(card_id)
			var name: String = card.card_name if card else card_id
			errors.append("Too many copies of %s (max 4, has %d)" % [name, counts[card_id]])

	# Rule 4: Card colors must match Leader's colors
	if leader != null:
		for card_id in deck.card_list:
			var card: CardData = CardDatabase.get_card(card_id)
			if card == null:
				continue
			var legal := false
			for color in card.colors:
				if color in leader.colors:
					legal = true
					break
			if not legal:
				errors.append("%s has an illegal color for this Leader" % card.card_name)

	# Rule 5: Banned cards (TODO: implement BanList)
	# for card_id in deck.card_list:
	#     if BanList.is_banned(card_id):
	#         errors.append(...)

	return ValidationResult.new(errors.is_empty(), errors)
