extends Node
## Global singleton (autoload) that tracks run-wide resources.
## Gold and XP are intentionally kept as separate currencies (design doc).

signal gold_changed(value: int)
signal xp_changed(value: int)
signal wave_changed(value: int)

var gold: int = 0
var xp: int = 0
var wave: int = 0
## Chosen on the character-select screen; read by the player on game start.
var selected_character_id: String = "ssumawang"
## How many times the shop reroll has been used this run (drives reroll price).
var reroll_count: int = 0
var kills: int = 0
var boss_kills: int = 0


func register_kill(is_boss: bool = false) -> void:
	kills += 1
	if is_boss:
		boss_kills += 1


func spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp)


func set_wave(value: int) -> void:
	wave = value
	wave_changed.emit(wave)


func reset() -> void:
	gold = 0
	xp = 0
	wave = 0
	reroll_count = 0
	kills = 0
	boss_kills = 0
	gold_changed.emit(gold)
	xp_changed.emit(xp)
	wave_changed.emit(wave)
