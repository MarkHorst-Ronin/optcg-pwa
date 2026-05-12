## BattleResolver.gd
## 4-step combat sequence
## Agent 4 owns this file. Depends on GameState (Agent 2) + TurnManager (Agent 3).
class_name BattleResolver
extends Node

signal battle_complete(attacker: CardInstance, defender: CardInstance, attacker_won: bool)

var _current_attacker: CardInstance = null
var _current_defender: CardInstance = null
var _current_controller: int = 0

## TODO: Agent 4 implements all steps below

## Step 1: Attack Declaration
func declare_attack(attacker: CardInstance, target: CardInstance, controller: int) -> void:
	_current_attacker    = attacker
	_current_defender    = target
	_current_controller  = controller
	# Rest the attacker
	# Fire [When Attacking] effects
	# Await EffectQueue
	pass

## Step 2: Block Step (defender's choice, 30s timeout)
func _block_step() -> void:
	pass

## Step 3: Counter Step (defender may discard/play, hand only)
func _counter_step() -> void:
	pass

## Step 4: Damage Step
func _damage_step() -> void:
	## attacker.get_total_power() vs defender.get_total_power()
	## Ties go to attacker (>=)
	## vs Leader: DamageHandler.deal_damage()
	## vs Character: GameState.send_to_trash()
	## If attacker loses: nothing happens
	pass
