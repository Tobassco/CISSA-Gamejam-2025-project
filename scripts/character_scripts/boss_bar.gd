extends ProgressBar

@onready var boss_new: CharacterBody2D = $"../.."

func _ready() -> void:
	boss_new.healthSignal.connect(update)
	update()

func update():
	print("Health BAR: ", boss_new.currentHealth)
	value = boss_new.currentHealth * 100 / boss_new.maxHealth
