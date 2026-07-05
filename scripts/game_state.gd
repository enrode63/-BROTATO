extends Node
## Global singleton (autoload) that tracks run-wide resources.
## Gold and XP are intentionally kept as separate currencies (design doc).

signal gold_changed(value: int)
signal xp_changed(value: int)
signal wave_changed(value: int)

var gold: int = 0
var xp: int = 0
var wave: int = 0


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
	gold_changed.emit(gold)
	xp_changed.emit(xp)
	wave_changed.emit(wave)
