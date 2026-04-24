extends CanvasLayer
# Permanent bottom hotbar. No class_name to avoid autoload-style collisions
# and because the scene-root identity is sufficient for external refs.

signal consumable_used(stack_idx: int)

const HP_BAR_SIZE := Vector2(120, 16)

const HP_COLOR_LOW := Color(0.85, 0.15, 0.15, 1)
const HP_COLOR_MID := Color(0.85, 0.75, 0.15, 1)
const HP_COLOR_HIGH := Color(0.20, 0.75, 0.25, 1)

const EQUIPPED_SLOT_SIZE := Vector2(48, 64)
const BAG_SLOT_SIZE := Vector2(44, 58)
const POTION_SLOT_COUNT: int = 3   # keys 1-3
const BAG_SLOT_COUNT: int = 5      # keys 4-8 (equipables only)
const SLOT_ICON_SIZE: int = 32
const SLOT_BG_FILLED := Color(0.14, 0.14, 0.17, 0.95)
const SLOT_BG_EMPTY := Color(0.10, 0.10, 0.12, 0.95)
const SLOT_BORDER := Color(0.4, 0.4, 0.45, 1)

const FAITH_COLOR := Color(1.0, 0.85, 0.35, 1)
const PIP_EMPTY := Color(0.25, 0.25, 0.28, 1)
const PIP_SIZE := Vector2(6, 6)
const ABILITY_DISABLED_MODULATE := Color(0.4, 0.4, 0.4, 0.55)
const HOLY_SMITE_ICON: Texture2D = preload("res://assets/sprites/abilities/holy_smite.png")

var player: Player
var current_floor: int = 1

var _sacrifice_mode: bool = false
var _sacrifice_prompt: Label

var _hp_bar: ProgressBar
var _hp_label: Label
var _atk_label: Label
var _def_label: Label
var _floor_label: Label

var _smite_slot: Dictionary
var _weapon_ability_slot: Dictionary
var _weapon_slot: Dictionary
var _armor_slot: Dictionary
var _shield_slot: Dictionary
var _ring_slot: Dictionary
var _amulet_slot: Dictionary
var _potion_slots: Array = []
var _bag_slots: Array = []

@onready var portrait_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/PortraitContainer
@onready var status_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/StatusContainer
@onready var abilities_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/AbilitiesContainer
@onready var equipped_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/EquippedContainer
@onready var potions_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/PotionsContainer
@onready var bag_container: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/BagContainer
@onready var tooltip_control: Control = $TooltipControl
@onready var tooltip_label: Label = $TooltipControl/TooltipPanel/TooltipLabel
@onready var _mute_indicator: Label = $PanelContainer/MarginContainer/HBoxContainer/MuteIndicator

func _ready() -> void:
	layer = 5
	_build_portrait()
	_build_status()
	_build_abilities()
	_build_equipped()
	_build_potions()
	_build_bag()
	_build_sacrifice_prompt()
	AudioManager.mute_changed.connect(_on_mute_changed)
	_on_mute_changed(AudioManager.is_muted())

func _on_mute_changed(muted: bool) -> void:
	_mute_indicator.text = "✕" if muted else "♪"

func _build_portrait() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(56, 56)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = SLOT_BG_FILLED
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = SLOT_BORDER
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.content_margin_left = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", stylebox)

	var icon := TextureRect.new()
	icon.texture = preload("res://assets/sprites/ui/player_portrait.png")
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(icon)

	portrait_container.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_on_portrait_hover)
	panel.mouse_exited.connect(_hide_tooltip)

func _build_status() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	status_container.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "Benedict Rosarius"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55, 1))
	vbox.add_child(name_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	vbox.add_child(hp_row)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = HP_BAR_SIZE
	_hp_bar.show_percentage = false
	_hp_bar.min_value = 0
	_hp_bar.max_value = 20
	_hp_bar.value = 20
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_hp_bar.mouse_entered.connect(_on_hp_hover)
	_hp_bar.mouse_exited.connect(_hide_tooltip)
	hp_row.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.text = "0/0"
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_hp_label.mouse_entered.connect(_on_hp_hover)
	_hp_label.mouse_exited.connect(_hide_tooltip)
	hp_row.add_child(_hp_label)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_row)

	_atk_label = Label.new()
	_atk_label.text = "⚔ 0"
	_atk_label.add_theme_font_size_override("font_size", 14)
	_atk_label.add_theme_color_override("font_color", Color(0.95, 0.6, 0.35, 1))
	_atk_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_atk_label.mouse_entered.connect(_on_atk_hover)
	_atk_label.mouse_exited.connect(_hide_tooltip)
	stats_row.add_child(_atk_label)

	_def_label = Label.new()
	_def_label.text = "🛡 0"
	_def_label.add_theme_font_size_override("font_size", 14)
	_def_label.add_theme_color_override("font_color", Color(0.4, 0.75, 0.95, 1))
	_def_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_def_label.mouse_entered.connect(_on_def_hover)
	_def_label.mouse_exited.connect(_hide_tooltip)
	stats_row.add_child(_def_label)

	_floor_label = Label.new()
	_floor_label.text = "Floor 1"
	_floor_label.add_theme_font_size_override("font_size", 14)
	_floor_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65, 1))
	stats_row.add_child(_floor_label)

func _refresh_status() -> void:
	if player == null:
		return
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.hp
	_hp_label.text = "%d/%d" % [player.hp, player.max_hp]

	# HP color: red→yellow→green via two-stage lerp
	var ratio: float = 0.0
	if player.max_hp > 0:
		ratio = float(player.hp) / float(player.max_hp)
	var bar_color: Color
	if ratio < 0.5:
		bar_color = HP_COLOR_LOW.lerp(HP_COLOR_MID, ratio * 2.0)
	else:
		bar_color = HP_COLOR_MID.lerp(HP_COLOR_HIGH, (ratio - 0.5) * 2.0)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	_hp_bar.add_theme_stylebox_override("fill", fill_style)

	_atk_label.text = "⚔ %d" % player.atk
	_def_label.text = "🛡 %d" % player.def
	_floor_label.text = "Floor %d" % current_floor

func on_stat_increased(stat: StringName, _delta: int) -> void:
	var target: Label = null
	match stat:
		&"atk":
			target = _atk_label
		&"def":
			target = _def_label
		&"max_hp":
			target = _hp_label
	if target == null:
		return
	target.pivot_offset = target.size / 2.0
	var tween := create_tween()
	tween.tween_property(target, "scale", Vector2(1.3, 1.3), 0.15)
	tween.parallel().tween_property(target, "modulate", Color(1.3, 1.1, 0.4, 1), 0.15)
	tween.tween_property(target, "scale", Vector2.ONE, 0.25)
	tween.parallel().tween_property(target, "modulate", Color.WHITE, 0.25)

func _build_abilities() -> void:
	_smite_slot = _build_ability_slot(HOLY_SMITE_ICON, "Q")
	_weapon_ability_slot = _build_weapon_ability_slot()

func _build_ability_slot(icon_tex: Texture2D, hotkey: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = EQUIPPED_SLOT_SIZE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	var key_label := Label.new()
	key_label.text = hotkey
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	key_label.position = Vector2(0, 0)
	stack.add_child(key_label)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_left = 0.5
	icon.anchor_top = 0.0
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.0
	icon.offset_left = -16.0
	icon.offset_top = 2.0
	icon.offset_right = 16.0
	icon.offset_bottom = 34.0
	stack.add_child(icon)

	var pips_row := HBoxContainer.new()
	pips_row.add_theme_constant_override("separation", 3)
	pips_row.anchor_left = 0.5
	pips_row.anchor_top = 1.0
	pips_row.anchor_right = 0.5
	pips_row.anchor_bottom = 1.0
	pips_row.offset_left = -12.0
	pips_row.offset_top = -8.0
	pips_row.offset_right = 12.0
	pips_row.offset_bottom = 0.0
	stack.add_child(pips_row)

	var pips: Array = []
	for i in range(Player.MAX_FAITH):
		var pip := ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		pip.color = PIP_EMPTY
		pips_row.add_child(pip)
		pips.append(pip)

	abilities_container.add_child(panel)

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var slot_data := {"panel": panel, "icon": icon, "pips": pips, "key_label": key_label}
	panel.mouse_entered.connect(_on_smite_hover)
	panel.mouse_exited.connect(_hide_tooltip)
	return slot_data

func _refresh_abilities() -> void:
	if player == null:
		return
	var panel: PanelContainer = _smite_slot["panel"]
	var icon: TextureRect = _smite_slot["icon"]
	var pips: Array = _smite_slot["pips"]

	var available: bool = player.faith > 0

	icon.modulate = Color.WHITE if available else ABILITY_DISABLED_MODULATE

	for i in range(pips.size()):
		var pip: ColorRect = pips[i]
		pip.color = FAITH_COLOR if i < player.faith else PIP_EMPTY

	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = FAITH_COLOR if available else SLOT_BORDER
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.content_margin_left = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_bottom = 4
	stylebox.bg_color = SLOT_BG_FILLED if available else SLOT_BG_EMPTY
	panel.add_theme_stylebox_override("panel", stylebox)

	_refresh_weapon_ability()

# Builds the E-slot shell. Icon texture is assigned per-refresh based on the
# currently equipped weapon; a bottom-center label doubles as the cooldown
# readout when the ability is on cooldown.
func _build_weapon_ability_slot() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = EQUIPPED_SLOT_SIZE

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	var key_label := Label.new()
	key_label.text = "E"
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	key_label.position = Vector2(0, 0)
	stack.add_child(key_label)

	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_left = 0.5
	icon.anchor_top = 0.0
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.0
	icon.offset_left = -16.0
	icon.offset_top = 2.0
	icon.offset_right = 16.0
	icon.offset_bottom = 34.0
	stack.add_child(icon)

	# Big cooldown readout centered over the icon when on cooldown.
	var cd_label := Label.new()
	cd_label.text = ""
	cd_label.add_theme_font_size_override("font_size", 22)
	cd_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	cd_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	cd_label.add_theme_constant_override("outline_size", 4)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.anchor_left = 0.0
	cd_label.anchor_top = 0.0
	cd_label.anchor_right = 1.0
	cd_label.anchor_bottom = 1.0
	stack.add_child(cd_label)

	abilities_container.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var slot_data := {"panel": panel, "icon": icon, "cd_label": cd_label, "key_label": key_label}
	panel.mouse_entered.connect(_on_weapon_ability_hover)
	panel.mouse_exited.connect(_hide_tooltip)
	return slot_data

func _refresh_weapon_ability() -> void:
	var panel: PanelContainer = _weapon_ability_slot["panel"]
	var icon: TextureRect = _weapon_ability_slot["icon"]
	var cd_label: Label = _weapon_ability_slot["cd_label"]

	var weapon: Weapon = player.inventory.weapon if player.inventory != null else null
	var has_ability: bool = weapon != null and weapon.ability != Weapon.Ability.NONE
	var cd: int = player.weapon_ability_cooldown
	var is_ready: bool = has_ability and cd <= 0

	if has_ability:
		icon.visible = true
		icon.texture = weapon.ability_icon
		icon.modulate = Color.WHITE if is_ready else ABILITY_DISABLED_MODULATE
	else:
		icon.visible = false

	cd_label.text = str(cd) if cd > 0 else ""

	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = FAITH_COLOR if is_ready else SLOT_BORDER
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.content_margin_left = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_bottom = 4
	stylebox.bg_color = SLOT_BG_FILLED if has_ability else SLOT_BG_EMPTY
	panel.add_theme_stylebox_override("panel", stylebox)

func _on_weapon_ability_hover() -> void:
	if player == null:
		return
	var weapon: Weapon = player.inventory.weapon if player.inventory != null else null
	if weapon == null or weapon.ability == Weapon.Ability.NONE:
		_show_tooltip("Weapon Ability (E)\nEquipe uma arma lendária para desbloquear.")
		return
	var status: String
	if player.weapon_ability_cooldown > 0:
		status = "Recarga: %d turnos" % player.weapon_ability_cooldown
	else:
		status = "Pronto (recarga %d turnos)" % Player.WEAPON_ABILITY_COOLDOWN
	_show_tooltip("%s (E)\n%s\n%s" % [weapon.ability_name, weapon.ability_description, status])

func _on_portrait_hover() -> void:
	_show_tooltip("Benedict Rosarius, Paladino\nClasse de combate corpo-a-corpo com Holy Smite (Q) e fé renovável ao matar inimigos.")

func _on_hp_hover() -> void:
	if player == null:
		_show_tooltip("Vida")
		return
	_show_tooltip("Vida: %d / %d\nMate inimigos ou use poções para recuperar." % [player.hp, player.max_hp])

func _on_atk_hover() -> void:
	if player == null:
		_show_tooltip("Ataque")
		return
	var weapon_bonus: int = 0
	if player.inventory.weapon != null:
		weapon_bonus = player.inventory.weapon.atk_bonus
	_show_tooltip("Ataque: %d\nBase %d + Arma %d + Altar %d" % [player.atk, Player.BASE_ATK, weapon_bonus, player.bonus_atk])

func _on_def_hover() -> void:
	if player == null:
		_show_tooltip("Defesa")
		return
	var armor_bonus: int = 0
	if player.inventory.armor != null:
		armor_bonus = player.inventory.armor.def_bonus
	_show_tooltip("Defesa: %d\nBase %d + Armadura %d + Altar %d" % [player.def, Player.BASE_DEF, armor_bonus, player.bonus_def])

func _on_smite_hover() -> void:
	if player == null:
		_show_tooltip("Holy Smite (Q)")
		return
	var body: String
	if player.faith > 0:
		body = "Atira na última direção andada (%d casas). Custa 1 fé." % Player.SMITE_RANGE
	else:
		body = "Sem fé. Mate inimigos para recarregar (máx %d)." % Player.MAX_FAITH
	_show_tooltip("Holy Smite (Q)\n%s" % body)

func _build_equipped_slot() -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = EQUIPPED_SLOT_SIZE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var label := Label.new()
	label.text = "—"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	vbox.add_child(label)

	equipped_container.add_child(panel)

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var slot_data := {"panel": panel, "icon": icon, "label": label, "kind": ""}
	panel.mouse_entered.connect(_on_equipped_hover.bind(slot_data))
	panel.mouse_exited.connect(_hide_tooltip)
	return slot_data

func _build_equipped() -> void:
	_weapon_slot = _build_equipped_slot()
	_weapon_slot["kind"] = "weapon"
	_armor_slot = _build_equipped_slot()
	_armor_slot["kind"] = "armor"
	_shield_slot = _build_equipped_slot()
	_shield_slot["kind"] = "shield"
	_ring_slot = _build_equipped_slot()
	_ring_slot["kind"] = "ring"
	_amulet_slot = _build_equipped_slot()
	_amulet_slot["kind"] = "amulet"

func _refresh_equipped() -> void:
	if player == null:
		return
	var inv := player.inventory
	_set_equipped_slot(_weapon_slot, inv.weapon, "ATK")
	_set_equipped_slot(_armor_slot, inv.armor, "DEF")
	_set_equipped_slot(_shield_slot, inv.shield, "DEF")
	_set_equipped_slot(_ring_slot, inv.ring, "HP")
	_set_equipped_slot(_amulet_slot, inv.amulet, "HP")

# Produces a "+N STAT" label for an item, inspecting its actual bonus so rings
# with varied primary stats read correctly ("+2 ATK" vs "+15 HP").
func _item_bonus_label(item: Item, default_stat_name: String) -> String:
	if item is Weapon:
		return "+%d ATK" % (item as Weapon).atk_bonus
	if item is Armor:
		return "+%d DEF" % (item as Armor).def_bonus
	if item is Shield:
		return "+%d DEF" % (item as Shield).def_bonus
	if item is Ring:
		var r := item as Ring
		if r.atk_bonus > 0:
			return "+%d ATK" % r.atk_bonus
		if r.def_bonus > 0:
			return "+%d DEF" % r.def_bonus
		return "+%d HP" % r.max_hp_bonus
	if item is Amulet:
		var a := item as Amulet
		# Amulets can stack multiple bonuses (e.g. faith has atk+def). Show them all.
		var parts: Array = []
		if a.atk_bonus > 0:
			parts.append("+%d ATK" % a.atk_bonus)
		if a.def_bonus > 0:
			parts.append("+%d DEF" % a.def_bonus)
		if a.max_hp_bonus > 0:
			parts.append("+%d HP" % a.max_hp_bonus)
		return " ".join(parts) if not parts.is_empty() else "—"
	return "+0 %s" % default_stat_name

func _set_equipped_slot(slot: Dictionary, item: Item, stat_name: String) -> void:
	var panel: PanelContainer = slot["panel"]
	var icon: TextureRect = slot["icon"]
	var label: Label = slot["label"]

	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.border_color = SLOT_BORDER
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.content_margin_left = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_bottom = 4

	if item == null:
		stylebox.bg_color = SLOT_BG_EMPTY
		icon.visible = false
		label.text = "—"
	else:
		stylebox.bg_color = SLOT_BG_FILLED
		icon.visible = true
		icon.texture = item.texture
		label.text = _item_bonus_label(item, stat_name)

	panel.add_theme_stylebox_override("panel", stylebox)

func _build_bag() -> void:
	for i in range(BAG_SLOT_COUNT):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = BAG_SLOT_SIZE

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)

		var stack := Control.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(stack)

		var number_label := Label.new()
		# Bag slots start at keyboard 4, since keys 1-3 are potion slots.
		number_label.text = str(POTION_SLOT_COUNT + i + 1)
		number_label.add_theme_font_size_override("font_size", 10)
		number_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		number_label.position = Vector2(0, 0)
		stack.add_child(number_label)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -16.0
		icon.offset_top = -16.0
		icon.offset_right = 16.0
		icon.offset_bottom = 16.0
		stack.add_child(icon)

		bag_container.add_child(panel)

		var slot_data := {"panel": panel, "icon": icon, "number_label": number_label, "index": i}
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_entered.connect(_on_bag_hover.bind(slot_data))
		panel.mouse_exited.connect(_hide_tooltip)

		_bag_slots.append(slot_data)

# Three fixed slots for consumables (healing potion, buff potions, scrolls).
# Each slot stacks one item_id with a count badge. Keys 1-3 use them.
func _build_potions() -> void:
	for i in range(POTION_SLOT_COUNT):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = BAG_SLOT_SIZE

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)

		var stack := Control.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(stack)

		var number_label := Label.new()
		number_label.text = str(i + 1)
		number_label.add_theme_font_size_override("font_size", 10)
		number_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		number_label.position = Vector2(0, 0)
		stack.add_child(number_label)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(SLOT_ICON_SIZE, SLOT_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -16.0
		icon.offset_top = -16.0
		icon.offset_right = 16.0
		icon.offset_bottom = 16.0
		stack.add_child(icon)

		var count_label := Label.new()
		count_label.text = ""
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.anchor_left = 1.0
		count_label.anchor_top = 1.0
		count_label.anchor_right = 1.0
		count_label.anchor_bottom = 1.0
		count_label.offset_left = -22.0
		count_label.offset_top = -16.0
		count_label.offset_right = -2.0
		count_label.offset_bottom = 0.0
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stack.add_child(count_label)

		potions_container.add_child(panel)

		var slot_data := {"panel": panel, "icon": icon, "count_label": count_label, "index": i}
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_entered.connect(_on_potion_hover.bind(slot_data))
		panel.mouse_exited.connect(_hide_tooltip)

		_potion_slots.append(slot_data)

func _refresh_potions() -> void:
	if player == null:
		return
	var stacks: Array = player.inventory.potion_stacks
	for i in range(POTION_SLOT_COUNT):
		var slot: Dictionary = _potion_slots[i]
		var panel: PanelContainer = slot["panel"]
		var icon: TextureRect = slot["icon"]
		var count_label: Label = slot["count_label"]

		var stylebox := StyleBoxFlat.new()
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = SLOT_BORDER
		stylebox.corner_radius_top_left = 3
		stylebox.corner_radius_top_right = 3
		stylebox.corner_radius_bottom_right = 3
		stylebox.corner_radius_bottom_left = 3

		if i < stacks.size():
			var stack: Dictionary = stacks[i]
			var tpl := ItemDB.from_id(String(stack["item_id"]))
			stylebox.bg_color = SLOT_BG_FILLED
			icon.visible = true
			if tpl != null:
				icon.texture = tpl.texture
			var c: int = int(stack["count"])
			count_label.text = ("×%d" % c) if c > 1 else ""
		else:
			stylebox.bg_color = SLOT_BG_EMPTY
			icon.visible = false
			count_label.text = ""

		panel.add_theme_stylebox_override("panel", stylebox)

func _on_potion_hover(slot_data: Dictionary) -> void:
	if player == null:
		return
	var idx: int = slot_data["index"]
	var stacks: Array = player.inventory.potion_stacks
	if idx >= stacks.size():
		_show_tooltip("Vazio")
		return
	var stack: Dictionary = stacks[idx]
	var tpl := ItemDB.from_id(String(stack["item_id"]))
	if tpl == null:
		_show_tooltip("Vazio")
		return
	var detail: String = ""
	if tpl is Consumable:
		detail = tpl.description
	_show_tooltip("%s ×%d\n%s" % [tpl.display_name, int(stack["count"]), detail])

# Called by main.gd when keys 1-3 are pressed outside of sacrifice mode.
func use_potion_slot(idx: int) -> void:
	if player == null:
		return
	var stacks: Array = player.inventory.potion_stacks
	if idx < 0 or idx >= stacks.size():
		return
	consumable_used.emit(idx)

func _refresh_bag() -> void:
	if player == null:
		return
	var bag := player.inventory.bag

	for i in range(BAG_SLOT_COUNT):
		var slot: Dictionary = _bag_slots[i]
		var panel: PanelContainer = slot["panel"]
		var icon: TextureRect = slot["icon"]

		var stylebox := StyleBoxFlat.new()
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = SLOT_BORDER
		stylebox.corner_radius_top_left = 3
		stylebox.corner_radius_top_right = 3
		stylebox.corner_radius_bottom_right = 3
		stylebox.corner_radius_bottom_left = 3

		if i < bag.size():
			var item: Item = bag[i]
			stylebox.bg_color = SLOT_BG_FILLED
			icon.visible = true
			icon.texture = item.texture
		else:
			stylebox.bg_color = SLOT_BG_EMPTY
			icon.visible = false

		panel.add_theme_stylebox_override("panel", stylebox)

func refresh() -> void:
	_refresh_status()
	_refresh_abilities()
	_refresh_equipped()
	_refresh_potions()
	_refresh_bag()

func _on_equipped_hover(slot_data: Dictionary) -> void:
	if player == null:
		return
	var kind: String = slot_data["kind"]
	var inv := player.inventory
	var item: Item = null
	var stat_text: String = ""
	match kind:
		"weapon":
			item = inv.weapon
			if item != null:
				stat_text = "+%d ATK" % (item as Weapon).atk_bonus
		"armor":
			item = inv.armor
			if item != null:
				stat_text = "+%d DEF" % (item as Armor).def_bonus
		"shield":
			item = inv.shield
			if item != null:
				stat_text = "+%d DEF" % (item as Shield).def_bonus
		"ring":
			item = inv.ring
			if item != null:
				stat_text = _item_bonus_label(item, "HP")
		"amulet":
			item = inv.amulet
			if item != null:
				stat_text = _item_bonus_label(item, "HP")
	if item == null:
		_show_tooltip("Vazio")
	else:
		_show_tooltip("%s\n%s" % [item.display_name, stat_text])

func _on_bag_hover(slot_data: Dictionary) -> void:
	if player == null:
		return
	var idx: int = slot_data["index"]
	var bag := player.inventory.bag
	if idx >= bag.size():
		_show_tooltip("Vazio")
		return
	var item: Item = bag[idx]
	var detail: String = ""
	if item is Consumable:
		detail = item.description
	elif item is Weapon:
		detail = "+%d ATK" % (item as Weapon).atk_bonus
	elif item is Armor:
		detail = "+%d DEF" % (item as Armor).def_bonus
	elif item is Shield:
		detail = "+%d DEF" % (item as Shield).def_bonus
	elif item is Ring:
		detail = _item_bonus_label(item, "HP")
	elif item is Amulet:
		detail = _item_bonus_label(item, "HP")
	if detail != "":
		_show_tooltip("%s\n%s" % [item.display_name, detail])
	else:
		_show_tooltip(item.display_name)

func _show_tooltip(text: String) -> void:
	tooltip_label.text = text
	tooltip_control.visible = true
	_reposition_tooltip()

func _hide_tooltip() -> void:
	tooltip_control.visible = false

func _reposition_tooltip() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var panel := tooltip_control.get_child(0) as PanelContainer
	var panel_size: Vector2 = panel.get_combined_minimum_size()
	var target: Vector2 = mouse_pos - Vector2(panel_size.x / 2.0, panel_size.y + 10)
	target.x = clampf(target.x, 4.0, viewport_size.x - panel_size.x - 4.0)
	target.y = clampf(target.y, 4.0, viewport_size.y - panel_size.y - 4.0)
	panel.position = target

func _process(_delta: float) -> void:
	if tooltip_control.visible:
		_reposition_tooltip()

func _build_sacrifice_prompt() -> void:
	_sacrifice_prompt = Label.new()
	_sacrifice_prompt.text = "O altar profano clama — consagre um equipamento (1–8)"
	_sacrifice_prompt.add_theme_font_size_override("font_size", 14)
	_sacrifice_prompt.add_theme_color_override("font_color", FAITH_COLOR)
	_sacrifice_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sacrifice_prompt.anchor_left = 0.0
	_sacrifice_prompt.anchor_right = 1.0
	_sacrifice_prompt.anchor_top = 1.0
	_sacrifice_prompt.anchor_bottom = 1.0
	_sacrifice_prompt.offset_top = -130.0
	_sacrifice_prompt.offset_bottom = -110.0
	_sacrifice_prompt.visible = false
	add_child(_sacrifice_prompt)

func set_sacrifice_mode(enabled: bool) -> void:
	_sacrifice_mode = enabled
	if _sacrifice_prompt != null:
		_sacrifice_prompt.visible = enabled
	for slot in _bag_slots:
		var panel: PanelContainer = slot["panel"]
		panel.modulate = Color(1.25, 1.1, 0.55, 1.0) if enabled else Color.WHITE

func flash_slot_invalid(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _bag_slots.size():
		return
	var panel: PanelContainer = _bag_slots[slot_idx]["panel"]
	var base_color: Color = Color(1.25, 1.1, 0.55, 1.0) if _sacrifice_mode else Color.WHITE
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1.5, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(panel, "modulate", base_color, 0.2)
