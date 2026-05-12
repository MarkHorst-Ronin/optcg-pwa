## DeckData.gd
## Represents a saved deck — leader + 50 cards
## Agent 9 owns this file.
class_name DeckData
extends Resource

@export var deck_id:    String = ""
@export var deck_name:  String = "New Deck"
@export var leader_id:  String = ""
@export var card_list:  Array[String] = []   # Array of card_ids (50 entries, duplicates allowed)
@export var created_at: String = ""
@export var updated_at: String = ""

func get_card_counts() -> Dictionary:
	var counts: Dictionary = {}
	for id in card_list:
		counts[id] = counts.get(id, 0) + 1
	return counts

func get_leader() -> CardData:
	return CardDatabase.get_card(leader_id)
