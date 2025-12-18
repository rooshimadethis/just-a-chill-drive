extends Node

signal score_updated(new_score)

var harmony_score: int = 0

func add_harmony(amount: int = 1):
	harmony_score += amount
	score_updated.emit(harmony_score)
	print("Harmony increased: ", harmony_score)

func reset_score():
	harmony_score = 0
	score_updated.emit(harmony_score)
