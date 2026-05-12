## CardView.gd
## Visual card component — all 8 visual states
## Agent 5 owns this file. Depends on CardData (Agent 1).
class_name CardView
extends Node2D

enum CardState {
	ACTIVE,
	RESTED,
	TARGETED,
	HOVERABLE,
	PLAYABLE,
	UNPLAYABLE,
	FACE_DOWN,
	ATTACKING
}

var card_data: CardData = null
var current_state: CardState = CardState.ACTIVE

func load_card(data: CardData) -> void:
	card_data = data
	## TODO: Agent 5 — render art, name, cost, power, counter

func set_state(state: CardState) -> void:
	current_state = state
	## TODO: Agent 5 — apply visual for each state
	match state:
		CardState.ACTIVE:     _apply_active()
		CardState.RESTED:     _apply_rested()
		CardState.TARGETED:   _apply_targeted()
		CardState.HOVERABLE:  _apply_hover()
		CardState.PLAYABLE:   _apply_playable()
		CardState.UNPLAYABLE: _apply_unplayable()
		CardState.FACE_DOWN:  _apply_face_down()
		CardState.ATTACKING:  _apply_attacking()

func flip_to_face_up(animate: bool) -> void:
	pass  ## TODO: Agent 5

func attach_don_visual(count: int) -> void:
	pass  ## TODO: Agent 5

func _apply_active() -> void:     pass
func _apply_rested() -> void:     pass  ## 90° rotation tween
func _apply_targeted() -> void:   pass  ## glow shader
func _apply_hover() -> void:      pass  ## scale 1.1, detail panel
func _apply_playable() -> void:   pass  ## pulse animation
func _apply_unplayable() -> void: pass  ## desaturate + 0.5 alpha
func _apply_face_down() -> void:  pass  ## show card back, hide all text
func _apply_attacking() -> void:  pass  ## forward push
