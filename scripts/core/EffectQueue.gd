## EffectQueue.gd
## FIFO async effect resolver
## Agent 4 owns this file.
class_name EffectQueue
extends Node

signal all_resolved()

class QueuedEffect:
	var effect:     EffectData
	var source:     CardInstance
	var controller: int

var _queue: Array[QueuedEffect] = []
var _resolving: bool = false

func enqueue(effect: EffectData, source: CardInstance, controller: int) -> void:
	var qe := QueuedEffect.new()
	qe.effect     = effect
	qe.source     = source
	qe.controller = controller
	_queue.push_back(qe)
	if not _resolving:
		_pump()

func _pump() -> void:
	if _queue.is_empty():
		_resolving = false
		all_resolved.emit()
		return
	_resolving = true
	var qe: QueuedEffect = _queue.pop_front()
	# Skip if source left field (unless independent)
	# TODO: Agent 4 implements each effect_type resolution
	await get_tree().process_frame
	_pump()

func is_empty() -> bool:
	return _queue.is_empty()

func clear() -> void:
	_queue.clear()
	_resolving = false
