## WinConditionChecker.gd
## Win/loss detection per Comprehensive Rules v1.2.0
## Agent 11 owns this file.
## CRITICAL: Loss from KO is triggered INSIDE damage processing (rule 1-2-1-1-1)
## NOT as a passive state check. Called by DamageHandler before popping Life card.
class_name WinConditionChecker
extends RefCounted

const NAMI_LEADER_ID: String = "OP01-016"

## Called INSIDE DamageHandler BEFORE popping Life card
## Returns true if player_idx loses (i.e. life_count == 0 at time of damage)
func check_damage_loss(player_idx: int) -> bool:
	return GameState.get_life_count(player_idx) == 0

## Called at start of Draw Phase
## Returns true if player_idx loses due to empty deck
## EXCEPTION: Nami (OP01-016) WINS on own deck-out
func check_deckout(player_idx: int) -> Dictionary:
	if GameState.get_deck_size(player_idx) == 0:
		var leader: CardInstance = GameState.get_leader(player_idx)
		var is_nami: bool = leader != null and leader.card_data.card_id == NAMI_LEADER_ID
		return {
			"triggered": true,
			"winner": player_idx if is_nami else (1 - player_idx)
		}
	return {"triggered": false}

## Given a losing player index, return the winner
func get_winner_from_loser(loser_idx: int) -> int:
	return 1 - loser_idx
