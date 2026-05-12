## DeckBuilderView.gd
## Deck builder UI controller
## Agent 9 owns this file.
class_name DeckBuilderView
extends Control

var current_deck: DeckData = DeckData.new()
var validator: DeckValidator = DeckValidator.new()

signal deck_saved(deck: DeckData)

func _ready() -> void:
	pass  ## TODO: Agent 9 — load card browser, connect signals

func add_card(card_id: String) -> void:
	## TODO: Agent 9 — add card, run validation, update count display
	pass

func remove_card(card_id: String) -> void:
	## TODO: Agent 9
	pass

func save_deck() -> void:
	var result := validator.validate(current_deck)
	if not result.valid:
		## TODO: Agent 9 — show error messages
		return
	## TODO: Agent 9 — POST to API via AuthManager
	deck_saved.emit(current_deck)

func load_deck(deck_id: String) -> void:
	## TODO: Agent 9 — GET from API via AuthManager
	pass

func apply_filter(filter: CardFilter) -> void:
	## TODO: Agent 9 — refresh card browser with filtered results
	pass
