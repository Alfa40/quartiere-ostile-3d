extends Node

const PASSWORD := "Creator"

var enabled := false

func check(input: String) -> bool:
	return input == PASSWORD
