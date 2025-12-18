class_name LSystem
extends RefCounted

# L-System Variables
var axiom: String = "F"
var rules: Dictionary = {
	"F": "FF+[+F-F-F]-[-F+F+F]" 
}
var iterations: int = 4
var angle: float = 25.0

func generate_sentence() -> String:
	var current = axiom
	for i in range(iterations):
		var next_sentence = ""
		for char in current:
			if rules.has(char):
				next_sentence += rules[char]
			else:
				next_sentence += char
		current = next_sentence
	return current
