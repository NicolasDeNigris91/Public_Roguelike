extends CanvasLayer
# GameOverScreen — shown when Player dies OR when Benedict slays the Demon
# Lord on the final floor. Reads RunStats to build a summary of the run
# and adapts the title between three states:
#   - VITÓRIA FINAL (gold): final boss defeated (run_victory)
#   - VITÓRIA (green): Lich defeated but died later in the descent
#   - VOCÊ MORREU (red): fell short

const TITLE_COLOR_DEATH := Color(0.9, 0.2, 0.2, 1)
const TITLE_COLOR_VICTORY := Color(0.3, 0.8, 0.35, 1)
const TITLE_COLOR_FINAL_VICTORY := Color(1.0, 0.85, 0.35, 1)

@onready var _title_label: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _subtitle_label: Label = $Control/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@onready var _stats_vbox: VBoxContainer = $Control/PanelContainer/MarginContainer/VBoxContainer/StatsPanel/StatsVBox

func show_result() -> void:
	if RunStats.lich_ending:
		_title_label.text = "THE CYCLE CONTINUES"
		_title_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.75, 1))
		_subtitle_label.text = "\"But yet it is...\"\nBenedict falls in the Bastion. The next paladin is already descending."
	elif RunStats.run_victory:
		_title_label.text = "THE END"
		_title_label.add_theme_color_override("font_color", TITLE_COLOR_FINAL_VICTORY)
		_subtitle_label.text = "The shield of iron protects the flesh, but the beads of wood protect the soul.\nOne does not enter the Kingdom of Heaven carrying the weight of hell."
	elif RunStats.lich_defeated:
		_title_label.text = "VITÓRIA"
		_title_label.add_theme_color_override("font_color", TITLE_COLOR_VICTORY)
		_subtitle_label.text = "O Lich foi derrotado. Você desceu mais fundo e caiu, mas deixou marca."
	else:
		_title_label.text = "VOCÊ MORREU"
		_title_label.add_theme_color_override("font_color", TITLE_COLOR_DEATH)
		_subtitle_label.text = "A Bastion venceu desta vez."
	_populate_stats()
	visible = true

func _populate_stats() -> void:
	for child in _stats_vbox.get_children():
		child.queue_free()

	_add_row("Andar alcançado", "%d / %d" % [RunStats.floor_reached, ActConfig.MAX_FLOOR])
	_add_row("Inimigos derrotados", str(RunStats.enemies_killed))
	_add_row("Dano causado", str(RunStats.damage_dealt))
	_add_row("Dano sofrido", str(RunStats.damage_taken))
	_add_row("Turnos jogados", str(RunStats.turns_played))
	_add_row("Melhor arma", RunStats.best_weapon_name)
	_add_row("Fé acumulada", str(RunStats.total_faith_gained))
	_add_row("Lich derrotado", "Sim" if RunStats.lich_defeated else "Não")
	_add_row("Demon Lord derrotado", "Sim" if RunStats.run_victory else "Não")

func _add_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	_stats_vbox.add_child(row)
