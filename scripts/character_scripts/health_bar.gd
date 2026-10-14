extends ProgressBar

@onready var golem: CharacterBody2D = $"../.."

func _ready() -> void:
	golem.healthChanged.connect(update)
	update()

func update():
	if golem.maxHealth != null:
		value = golem.currentHealth * 100 / golem.maxHealth
		print("Golem HP CHANGED: ", value)
	
