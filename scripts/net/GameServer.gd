## GameServer.gd
## Host-authoritative RPC handlers for online multiplayer via Steam P2P
## Agent 12 owns this file.
## CRITICAL: Never send opponent hand card IDs. Never trust client power calcs.
class_name GameServer
extends Node

var _peer_to_player: Dictionary = {}   # peer_id (int) -> player_idx (int)

# ── Client → Host RPCs ────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func request_play_card(card_id: String, zone_index: int) -> void:
	var player_idx: int = _get_player(multiplayer.get_remote_sender_id())
	if not _validate_turn(player_idx): return
	if not GameState.can_play_card(player_idx, card_id): return
	## TODO: Agent 12 — apply play, broadcast
	_broadcast_play_card.rpc(player_idx, card_id, zone_index)

@rpc("any_peer", "reliable")
func request_attack(attacker_id: String, target_id: String) -> void:
	var player_idx: int = _get_player(multiplayer.get_remote_sender_id())
	if not _validate_turn(player_idx): return
	if not GameState.can_attack(player_idx, attacker_id): return
	## TODO: Agent 12 — run battle sequence

@rpc("any_peer", "reliable")
func respond_block(blocker_id: String) -> void:
	## Empty string = no block
	pass  ## TODO: Agent 12

@rpc("any_peer", "reliable")
func respond_counter(card_ids: Array, event_id: String) -> void:
	pass  ## TODO: Agent 12

@rpc("any_peer", "reliable")
func respond_trigger(activate: bool) -> void:
	pass  ## TODO: Agent 12

@rpc("any_peer", "reliable")
func request_end_turn() -> void:
	var player_idx: int = _get_player(multiplayer.get_remote_sender_id())
	if not _validate_turn(player_idx): return
	## TODO: Agent 12

# ── Host → All RPCs ───────────────────────────────────────────────────────────

@rpc("authority", "reliable")
func _broadcast_play_card(player_idx: int, card_id: String, zone_index: int) -> void:
	## All clients update BoardView
	pass  ## TODO: Agent 12

@rpc("authority", "reliable")
func _broadcast_attack(attacker_id: String, target_id: String) -> void:
	pass

@rpc("authority", "reliable")
func _broadcast_damage(player_idx: int, card_id: String, banished: bool) -> void:
	## Life card revealed — broadcast card_id ONLY at moment of damage
	pass

@rpc("authority", "reliable")
func _broadcast_phase_change(new_phase: int) -> void:
	pass

@rpc("authority", "reliable")
func _broadcast_game_over(winner_idx: int) -> void:
	pass

# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_player(peer_id: int) -> int:
	return _peer_to_player.get(peer_id, -1)

func _validate_turn(player_idx: int) -> bool:
	return player_idx == GameState.active_player
