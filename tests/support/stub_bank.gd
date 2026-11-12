extends Node

# A stand-in for the Progress autoload: the Pension a shop spends from.
var data := ProgressData.new()


func spend(amount: int) -> bool:
	return data.spend(amount)
