## EffectData.gd
## Describes a single card effect — timing, type, value, target
## Agent 1 owns this file.
class_name EffectData
extends Resource

@export var timing:           int = 0     # CardData.EffectTiming
@export var effect_type:      int = 0     # CardData.EffectType
@export var value:            int = 0     # amount: draw N, +N power, etc.
@export var don_cost:         int = 0     # for ACTIVATE effects
@export var don_threshold:    int = 0     # for DON_X effects
@export var target:           String = "" # target filter string
@export var optional:         bool = false
@export var independent:      bool = false  # effect resolves even if source leaves field
@export var return_order:     String = "bottom"  # for SEARCH: bottom/top/shuffle
@export var description:      String = ""

func is_trigger() -> bool:
	return timing == CardData.EffectTiming.TRIGGER

func is_counter() -> bool:
	return timing == CardData.EffectTiming.COUNTER
