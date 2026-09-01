@tool extends EditorScript


enum AlphaA {ABC, DEF}
enum AlphaB {GHI, JKL}


func _run() -> void:
	pass
	
	var alpha = AlphaB.JKL
	
	if alpha is AlphaA:
		print("YES A")
	elif alpha is AlphaB:
		print("YES B")
	else: print("NULL")
	
	
