extends Control

const PitchViewScript = preload("res://scripts/ui/pitch_view.gd")
const COLOR_BG := Color("#071522")
const COLOR_PANEL := Color("#0d2232")
const COLOR_PANEL_RAISED := Color("#112c3e")
const COLOR_LINE := Color("#1a3b50")
const COLOR_TEXT := Color("#eef7fb")
const COLOR_MUTED := Color("#91adbc")
const COLOR_CYAN := Color("#43d6e4")
const COLOR_CYAN_SOFT := Color("#173a4a")
const COLOR_GREEN := Color("#52d29a")
const COLOR_GOLD := Color("#ffcb6b")
const COLOR_RED := Color("#ff7884")
const TAB_KEYS: Array[String] = ["home", "training", "team", "schedule", "market"]
const TAB_LABELS: Array[String] = ["BERANDA", "LATIHAN", "TIM", "JADWAL", "BURSA"]
const TAB_MARKS: Array[String] = ["01", "02", "XI", "04", "05"]

var _textures: Dictionary = {}
var _shell: VBoxContainer
var _header_box: VBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _nav_row: HBoxContainer
var _current_tab := "home"
var _feedback_message := ""
var _feedback_success := true
var _setup_layer: Control
var _name_edit: LineEdit
var _position_select: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	custom_minimum_size = Vector2(360, 640)
	_textures = {
		"crest": load("res://assets/football/runtime/club_crest.png"),
		"main": load("res://assets/football/runtime/portrait_main.png"),
		"teammate1": load("res://assets/football/runtime/portrait_teammate1.png"),
		"teammate2": load("res://assets/football/runtime/portrait_teammate2.png"),
		"training": load("res://assets/football/runtime/training_drill.png")
	}
	_build_shell()
	CareerState.state_changed.connect(_on_state_changed)
	_refresh_all()
	if not CareerState.has_started():
		_show_career_setup()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_shell = VBoxContainer.new()
	_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shell.add_theme_constant_override("separation", 0)
	add_child(_shell)

	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_BG, COLOR_LINE, 0, 0))
	_shell.add_child(header_panel)
	var header_margin := MarginContainer.new()
	_set_margins(header_margin, 16, 12, 16, 10)
	header_panel.add_child(header_margin)
	_header_box = VBoxContainer.new()
	_header_box.add_theme_constant_override("separation", 8)
	header_margin.add_child(_header_box)

	var rule := ColorRect.new()
	rule.color = COLOR_LINE
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shell.add_child(rule)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_shell.add_child(_scroll)
	var content_margin := MarginContainer.new()
	_set_margins(content_margin, 14, 14, 14, 18)
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(content_margin)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	content_margin.add_child(_content)

	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size = Vector2(0, 76)
	nav_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0a1b29"), COLOR_LINE, 0, 0))
	_shell.add_child(nav_panel)
	var nav_margin := MarginContainer.new()
	_set_margins(nav_margin, 8, 5, 8, 6)
	nav_panel.add_child(nav_margin)
	_nav_row = HBoxContainer.new()
	_nav_row.add_theme_constant_override("separation", 4)
	nav_margin.add_child(_nav_row)


func _refresh_all() -> void:
	_update_header()
	_build_nav()
	_render_current()


func _on_state_changed() -> void:
	_refresh_all()


func _update_header() -> void:
	if not is_instance_valid(_header_box):
		return
	_clear_children(_header_box)
	var snapshot: Dictionary = CareerState.get_snapshot()
	var player: Dictionary = CareerState.get_player()
	var club: Dictionary = snapshot.get("club", {})
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	_header_box.add_child(top)
	var crest := _image("crest", 42, 50)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(crest)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 1)
	top.add_child(identity)
	_add_label(identity, str(club.get("name", "Bintang Nusantara FC")).to_upper(), 13, COLOR_TEXT, true)
	_add_label(identity, "MUSIM %s  ·  PEKAN %02d/%02d" % [str(snapshot.get("season", 2026)), int(snapshot.get("week", 1)), CareerState.SEASON_LENGTH], 10, COLOR_MUTED, false)
	var wallet := _panel_container()
	wallet.add_theme_stylebox_override("panel", _panel_style(Color("#102d3d"), Color("#1b5263"), 9, 1))
	wallet.custom_minimum_size = Vector2(85, 45)
	top.add_child(wallet)
	var wallet_inner := VBoxContainer.new()
	wallet_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_inner.add_theme_constant_override("separation", 0)
	wallet.add_child(wallet_inner)
	_add_label(wallet_inner, "DANA", 9, COLOR_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(wallet_inner, "%d KOIN" % int(club.get("funds", 0)), 11, COLOR_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)

	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 8)
	_header_box.add_child(energy_row)
	_add_label(energy_row, "ENERGI", 9, COLOR_MUTED, true)
	var energy := ProgressBar.new()
	energy.min_value = 0
	energy.max_value = 100
	energy.value = int(player.get("energy", 0))
	energy.show_percentage = false
	energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy.custom_minimum_size = Vector2(0, 8)
	energy.add_theme_stylebox_override("background", _flat_style(Color("#182f3d"), Color.TRANSPARENT, 5, 0))
	energy.add_theme_stylebox_override("fill", _flat_style(COLOR_CYAN, Color.TRANSPARENT, 5, 0))
	energy_row.add_child(energy)
	_add_label(energy_row, "%d/100" % int(player.get("energy", 0)), 10, COLOR_TEXT, true)


func _build_nav() -> void:
	if not is_instance_valid(_nav_row):
		return
	_clear_children(_nav_row)
	for index in range(TAB_KEYS.size()):
		var key := TAB_KEYS[index]
		var active := _current_tab == key or (_current_tab == "profile" and key == "home")
		var button := Button.new()
		button.flat = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 62)
		button.add_theme_stylebox_override("normal", _nav_style(active, false))
		button.add_theme_stylebox_override("hover", _nav_style(active, true))
		button.add_theme_stylebox_override("pressed", _nav_style(true, true))
		button.add_theme_stylebox_override("focus", _nav_style(true, true))
		button.pressed.connect(_on_nav_pressed.bind(key))
		_nav_row.add_child(button)
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 3)
		button.add_child(stack)
		var mark := _label(TAB_MARKS[index], 10, COLOR_CYAN if active else COLOR_MUTED, true)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(mark)
		var label := _label(TAB_LABELS[index], 8, COLOR_TEXT if active else COLOR_MUTED, active)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(label)


func _on_nav_pressed(key: String) -> void:
	_current_tab = key
	_feedback_message = ""
	_refresh_all()
	_scroll.scroll_vertical = 0


func _render_current() -> void:
	if not is_instance_valid(_content):
		return
	_clear_children(_content)
	match _current_tab:
		"home":
			_render_home()
		"training":
			_render_training()
		"team":
			_render_team()
		"schedule":
			_render_schedule()
		"market":
			_render_market()
		"profile":
			_render_profile()
		_:
			_current_tab = "home"
			_render_home()


func _page_head(section: String, title: String, subtitle: String = "") -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	_content.add_child(wrap)
	_add_label(wrap, section.to_upper(), 9, COLOR_CYAN, true)
	_add_label(wrap, title, 22, COLOR_TEXT, true)
	if not subtitle.is_empty():
		_add_label(wrap, subtitle, 12, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_add_feedback(_content)


func _render_home() -> void:
	var snapshot: Dictionary = CareerState.get_snapshot()
	var player: Dictionary = CareerState.get_player()
	var club: Dictionary = snapshot.get("club", {})
	_page_head("DASHBOARD PEMAIN", "Perjalanan Karier", "Bawa namamu dari akademi hingga menjadi bintang lapangan.")

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	_content.add_child(metrics)
	_metric(metrics, "OVERALL", str(player.get("overall", 60)), "LVL %02d" % int(player.get("level", 1)), COLOR_CYAN)
	_metric(metrics, "POIN KLUB", str(club.get("points", 0)), "MUSIM INI", COLOR_GOLD)
	_metric(metrics, "GOL", str(player.get("goals", 0)), "%d LAGA" % int(player.get("matches", 0)), COLOR_GREEN)

	_render_player_card(player)
	_render_next_match(snapshot)
	_render_season_goal(player, snapshot)
	if not bool(snapshot.get("dismissed_onboarding", false)):
		_render_tip_card()


func _render_player_card(player: Dictionary) -> void:
	var card := _card(_content, 15, 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(104, 150)
	portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color("#102d3c"), Color("#2b7181"), 11, 1))
	portrait_frame.clip_contents = true
	row.add_child(portrait_frame)
	var portrait := _image("main", 100, 147)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_frame.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	row.add_child(details)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	details.add_child(top)
	_add_label(top, str(player.get("position", "ST")), 10, COLOR_CYAN, true)
	_add_label(top, "PEMAIN MUDA  ·  USIA %d" % int(player.get("age", 18)), 9, COLOR_MUTED, true)
	_add_label(details, str(player.get("name", "Arga Pratama")), 17, COLOR_TEXT, true)
	var rating_row := HBoxContainer.new()
	rating_row.add_theme_constant_override("separation", 10)
	details.add_child(rating_row)
	_add_label(rating_row, "%02d" % int(player.get("overall", 60)), 32, COLOR_CYAN, true)
	var rating_note := VBoxContainer.new()
	rating_note.alignment = BoxContainer.ALIGNMENT_CENTER
	rating_note.add_theme_constant_override("separation", 1)
	rating_row.add_child(rating_note)
	_add_label(rating_note, "OVERALL", 9, COLOR_MUTED, true)
	_add_label(rating_note, "LVL %02d" % int(player.get("level", 1)), 10, COLOR_GOLD, true)
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 6)
	details.add_child(xp_row)
	_add_label(xp_row, "XP", 9, COLOR_MUTED, true)
	var xp := ProgressBar.new()
	xp.min_value = 0
	xp.max_value = 100 + (int(player.get("level", 1)) - 1) * 20
	xp.value = int(player.get("xp", 0))
	xp.show_percentage = false
	xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp.custom_minimum_size = Vector2(0, 7)
	xp.add_theme_stylebox_override("background", _flat_style(Color("#1c3441"), Color.TRANSPARENT, 5, 0))
	xp.add_theme_stylebox_override("fill", _flat_style(COLOR_GOLD, Color.TRANSPARENT, 5, 0))
	xp_row.add_child(xp)
	var attributes: Dictionary = player.get("attributes", {})
	_add_label(details, "SH %d    UM %d    DR %d" % [int(attributes.get("shooting", 60)), int(attributes.get("passing", 59)), int(attributes.get("dribble", 56))], 9, COLOR_MUTED, true)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	card.add_child(actions)
	var profile_button := _button("LIHAT PROFIL", false)
	profile_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_button.pressed.connect(_open_profile)
	actions.add_child(profile_button)
	var training_button := _button("KE LATIHAN", true)
	training_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training_button.pressed.connect(_on_nav_pressed.bind("training"))
	actions.add_child(training_button)


func _render_next_match(snapshot: Dictionary) -> void:
	var is_played := bool(snapshot.get("played_this_week", false))
	var opponent := str(snapshot.get("opponent", "Rajawali Metro"))
	var title := "HASIL PEKAN INI" if is_played else "PERTANDINGAN BERIKUTNYA"
	var card := _card(_content, 15, 14)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	card.add_child(heading)
	_add_label(heading, title, 10, COLOR_CYAN, true)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	_add_label(heading, "PEKAN %02d" % int(snapshot.get("week", 1)), 9, COLOR_MUTED, true)
	var faceoff := HBoxContainer.new()
	faceoff.alignment = BoxContainer.ALIGNMENT_CENTER
	faceoff.add_theme_constant_override("separation", 12)
	card.add_child(faceoff)
	var crest_a := _image("crest", 52, 60)
	crest_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	faceoff.add_child(crest_a)
	var teams := VBoxContainer.new()
	teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teams.alignment = BoxContainer.ALIGNMENT_CENTER
	teams.add_theme_constant_override("separation", 3)
	faceoff.add_child(teams)
	var club_name := str(snapshot.get("club", {}).get("name", "Bintang Nusantara FC"))
	_add_label(teams, club_name, 11, COLOR_TEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	if is_played:
		var result: Dictionary = snapshot.get("last_result", {})
		_add_label(teams, "%d  —  %d" % [int(result.get("score_for", 0)), int(result.get("score_against", 0))], 23, COLOR_GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
		_add_label(teams, "RATING %0.1f  ·  %s" % [float(result.get("rating", 0.0)), opponent], 9, COLOR_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_add_label(teams, "VS", 11, COLOR_CYAN, true, HORIZONTAL_ALIGNMENT_CENTER)
		_add_label(teams, opponent, 12, COLOR_TEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	var crest_b := _image("crest", 52, 60)
	crest_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest_b.modulate = Color("#8ca8b6")
	faceoff.add_child(crest_b)
	var play_button := _button("LAGA SELESAI" if is_played else "SIMULASIKAN LAGA", not is_played)
	play_button.disabled = is_played
	play_button.pressed.connect(_play_match)
	card.add_child(play_button)
	_add_label(card, "Energi dan atributmu memengaruhi hasil. Laga menghabiskan 26 energi." if not is_played else "Pekan berikutnya terbuka setelah kamu memajukan kalender.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)


func _render_season_goal(player: Dictionary, snapshot: Dictionary) -> void:
	var card := _card(_content, 15, 13)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	card.add_child(top)
	_add_label(top, "TARGET MUSIM", 10, COLOR_CYAN, true)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_add_label(top, "%d / 8 GOL" % int(player.get("goals", 0)), 10, COLOR_GOLD, true)
	var target := ProgressBar.new()
	target.min_value = 0
	target.max_value = 8
	target.value = mini(int(player.get("goals", 0)), 8)
	target.show_percentage = false
	target.custom_minimum_size = Vector2(0, 8)
	target.add_theme_stylebox_override("background", _flat_style(Color("#1c3441"), Color.TRANSPARENT, 5, 0))
	target.add_theme_stylebox_override("fill", _flat_style(COLOR_GOLD, Color.TRANSPARENT, 5, 0))
	card.add_child(target)
	_add_label(card, "Progres liga: %d poin · musim %s" % [int(snapshot.get("club", {}).get("points", 0)), str(snapshot.get("season", 2026))], 10, COLOR_MUTED, false)


func _render_tip_card() -> void:
	var card := _card(_content, 14, 12, COLOR_CYAN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := _badge("TIP", COLOR_CYAN, COLOR_CYAN_SOFT)
	row.add_child(icon)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stack)
	_add_label(stack, "MULAI DENGAN LATIHAN", 10, COLOR_TEXT, true)
	_add_label(stack, "Pilih fokus latihan, mainkan satu laga, lalu majukan pekan untuk memulihkan energi.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	var button := _button("SIAP", false)
	button.pressed.connect(CareerState.dismiss_onboarding)
	card.add_child(button)


func _render_training() -> void:
	var player: Dictionary = CareerState.get_player()
	_page_head("PUSAT LATIHAN", "Asah Kemampuan", "Setiap sesi mengonsumsi energi dan meningkatkan atribut secara permanen.")
	var overview := _card(_content, 15, 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	overview.add_child(row)
	var portrait := _image("main", 74, 94)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	_add_label(info, "RUTINITAS PEKAN %02d" % int(CareerState.state.get("week", 1)), 10, COLOR_CYAN, true)
	_add_label(info, str(player.get("name", "Arga Pratama")), 15, COLOR_TEXT, true)
	_add_label(info, "Energi tersedia  %d/100" % int(player.get("energy", 0)), 10, COLOR_MUTED, true)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = int(player.get("energy", 0))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", _flat_style(Color("#1c3441"), Color.TRANSPARENT, 5, 0))
	bar.add_theme_stylebox_override("fill", _flat_style(COLOR_CYAN, Color.TRANSPARENT, 5, 0))
	info.add_child(bar)
	var visual_card := _card(_content, 11, 9)
	var visual_row := HBoxContainer.new()
	visual_row.add_theme_constant_override("separation", 10)
	visual_card.add_child(visual_row)
	var illustration := _image("training", 118, 79)
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_row.add_child(illustration)
	var visual_copy := VBoxContainer.new()
	visual_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_copy.add_theme_constant_override("separation", 4)
	visual_row.add_child(visual_copy)
	_add_label(visual_copy, "LATIHAN DI LAPANGAN", 10, COLOR_CYAN, true)
	_add_label(visual_copy, "Cone, bola, dan sesi fokus mengubah atribut serta energi Anda.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	_add_label(_content, "PILIH PROGRAM", 10, COLOR_MUTED, true)
	var programs: Dictionary = CareerState.get_training_programs()
	for program_id in ["finishing", "playmaking", "sprint", "technique"]:
		_render_training_program(str(program_id), programs[str(program_id)], player)
	var note := _card(_content, 14, 12)
	_add_label(note, "PEMULIHAN", 10, COLOR_GOLD, true)
	_add_label(note, "Energi pulih 38 poin saat pekan dilanjutkan. Simpan tenaga untuk jadwal pertandingan.", 11, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)


func _render_training_program(program_id: String, program: Dictionary, player: Dictionary) -> void:
	var card := _card(_content, 13, 11)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mark := _badge(str(program.get("attribute", "FIT")).substr(0, 3).to_upper(), COLOR_CYAN, COLOR_CYAN_SOFT)
	row.add_child(mark)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 3)
	row.add_child(body)
	_add_label(body, str(program.get("label", "Latihan")), 13, COLOR_TEXT, true)
	_add_label(body, str(program.get("hint", "")), 9, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	var attribute: String = str(program.get("attribute", "shooting"))
	var attr_value := int(player.get("attributes", {}).get(attribute, 50))
	_add_label(body, "%s  %d  ·  +%d" % [str(CareerState.ATTRIBUTE_LABELS.get(attribute, attribute)), attr_value, int(program.get("boost", 2))], 9, COLOR_CYAN, true)
	var action := _button("LATIH\n-%d EN" % int(program.get("energy", 0)), true)
	var can_train := int(player.get("energy", 0)) >= int(program.get("energy", 0)) and attr_value < 99
	action.disabled = not can_train
	action.custom_minimum_size = Vector2(88, 50)
	action.pressed.connect(_train_program.bind(program_id))
	row.add_child(action)


func _render_team() -> void:
	var snapshot: Dictionary = CareerState.get_snapshot()
	var roster: Array[Dictionary] = CareerState.get_roster()
	var captain := str(snapshot.get("club", {}).get("captain", ""))
	_page_head("RUANG GANTI", "Skuad & Formasi", "Atur taktik tim dan ketuk pemain di lapangan untuk memilih kapten.")
	var formation_card := _card(_content, 14, 12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	formation_card.add_child(top)
	var description := VBoxContainer.new()
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_constant_override("separation", 3)
	top.add_child(description)
	_add_label(description, "TAKTIK TIM", 9, COLOR_MUTED, true)
	_add_label(description, CareerState.get_formation(), 20, COLOR_CYAN, true)
	var rotate := _button("GANTI\nFORMASI", true)
	rotate.custom_minimum_size = Vector2(102, 52)
	rotate.pressed.connect(_cycle_formation)
	top.add_child(rotate)
	var pitch_panel := PanelContainer.new()
	pitch_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0b2a31"), Color("#226356"), 12, 1))
	pitch_panel.custom_minimum_size = Vector2(0, 300)
	formation_card.add_child(pitch_panel)
	var pitch_margin := MarginContainer.new()
	_set_margins(pitch_margin, 7, 7, 7, 7)
	pitch_panel.add_child(pitch_margin)
	var pitch = PitchViewScript.new()
	pitch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.set_lineup(roster, CareerState.get_formation(), captain)
	pitch.player_selected.connect(_on_pitch_player_selected)
	pitch_margin.add_child(pitch)
	_add_label(formation_card, "KAPTEN: %s  ·  %d PEMAIN" % [captain, roster.size()], 10, COLOR_GOLD, true)
	_add_label(_content, "DAFTAR SKUAD", 10, COLOR_MUTED, true)
	for player_row in roster:
		_render_roster_row(player_row)


func _render_roster_row(player_row: Dictionary) -> void:
	var card := _card(_content, 10, 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	card.add_child(row)
	var texture_key := str(player_row.get("portrait", "teammate1"))
	var portrait := _image(texture_key, 40, 52)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)
	_add_label(body, str(player_row.get("name", "Pemain")), 11, COLOR_TEXT, true)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 5)
	body.add_child(meta)
	meta.add_child(_badge(str(player_row.get("position", "CM")), COLOR_CYAN, COLOR_CYAN_SOFT))
	_add_label(meta, "KAPTEN" if bool(player_row.get("is_captain", false)) else "SKUAD", 9, COLOR_GOLD if bool(player_row.get("is_captain", false)) else COLOR_MUTED, true)
	_add_label(row, "%02d" % int(player_row.get("overall", 60)), 16, COLOR_CYAN, true)
	var captain_button := _button("PILIH" if not bool(player_row.get("is_captain", false)) else "KAPTEN", not bool(player_row.get("is_captain", false)))
	captain_button.custom_minimum_size = Vector2(74, 38)
	captain_button.disabled = bool(player_row.get("is_captain", false))
	captain_button.pressed.connect(_choose_captain.bind(str(player_row.get("name", ""))))
	row.add_child(captain_button)


func _render_schedule() -> void:
	var snapshot: Dictionary = CareerState.get_snapshot()
	var club: Dictionary = snapshot.get("club", {})
	var player: Dictionary = CareerState.get_player()
	_page_head("KALENDER LIGA", "Jadwal & Hasil", "Selesaikan laga pekan ini sebelum melanjutkan musim.")
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 8)
	_content.add_child(metrics)
	_metric(metrics, "POIN", str(club.get("points", 0)), "KLASEMEN", COLOR_GOLD)
	_metric(metrics, "MENANG", str(club.get("wins", 0)), "MUSIM INI", COLOR_GREEN)
	_metric(metrics, "ENERGI", str(player.get("energy", 0)), "TERSEDIA", COLOR_CYAN)
	_render_next_match(snapshot)
	var advance_card := _card(_content, 14, 12)
	_add_label(advance_card, "LANJUTKAN PERJALANAN", 10, COLOR_CYAN, true)
	_add_label(advance_card, "Pekan baru memulihkan 38 energi dan mengurangi dana sebesar gaji mingguan.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	var advance := _button("MAJUKAN PEKAN  →", bool(snapshot.get("played_this_week", false)))
	advance.disabled = not bool(snapshot.get("played_this_week", false))
	advance.pressed.connect(_advance_week)
	advance_card.add_child(advance)
	_add_label(_content, "RIWAYAT PERTANDINGAN", 10, COLOR_MUTED, true)
	var history: Array = snapshot.get("history", [])
	if history.is_empty():
		var empty := _card(_content, 14, 14)
		_add_label(empty, "Belum ada hasil. Mainkan pertandingan pertamamu untuk membuka riwayat.", 11, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		for item in history:
			if item is Dictionary:
				_render_history_row(item)


func _render_history_row(item: Dictionary) -> void:
	var card := _card(_content, 12, 9)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	card.add_child(row)
	var outcome := str(item.get("outcome", "draw"))
	var accent := COLOR_GREEN if outcome == "win" else (COLOR_RED if outcome == "loss" else COLOR_GOLD)
	row.add_child(_badge("M" if outcome == "win" else ("K" if outcome == "loss" else "S"), accent, COLOR_PANEL_RAISED))
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 2)
	row.add_child(details)
	_add_label(details, "PEKAN %02d  ·  %s" % [int(item.get("week", 1)), str(item.get("opponent", "Lawan"))], 10, COLOR_TEXT, true)
	_add_label(details, "%d gol  ·  rating %0.1f" % [int(item.get("goals", 0)), float(item.get("rating", 6.0))], 9, COLOR_MUTED, false)
	_add_label(row, "%d — %d" % [int(item.get("score_for", 0)), int(item.get("score_against", 0))], 15, accent, true)


func _render_market() -> void:
	var player: Dictionary = CareerState.get_player()
	var club: Dictionary = CareerState.state.get("club", {})
	_page_head("BURSA TRANSFER", "Tawaran Kontrak", "Pilih klub berikutnya. Overall pemain menentukan tawaran yang terbuka.")
	var current := _card(_content, 14, 11)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	current.add_child(row)
	var crest := _image("crest", 46, 58)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(crest)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)
	_add_label(body, "KLUB SAAT INI", 9, COLOR_MUTED, true)
	_add_label(body, str(club.get("name", "Bintang Nusantara FC")), 13, COLOR_TEXT, true)
	_add_label(body, "Gaji %d koin/minggu" % int(club.get("weekly_wage", 0)), 9, COLOR_GOLD, true)
	var overall_badge := _badge("OVR %d" % int(player.get("overall", 60)), COLOR_CYAN, COLOR_CYAN_SOFT)
	row.add_child(overall_badge)
	_add_label(_content, "KONTRAK TERSEDIA", 10, COLOR_MUTED, true)
	for offer in CareerState.get_offers():
		_render_offer(offer, int(player.get("overall", 60)))
	var footnote := _card(_content, 14, 11)
	_add_label(footnote, "NEGOSIASI ADIL", 10, COLOR_GOLD, true)
	_add_label(footnote, "Menerima kontrak mengganti klub, memberi bonus tanda tangan, dan menetapkan gaji mingguan baru. Progres pemain tetap tersimpan.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)


func _render_offer(offer: Dictionary, overall: int) -> void:
	var accent: Color = offer.get("accent", COLOR_CYAN)
	var card := _card(_content, 14, 12, accent)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 9)
	card.add_child(top)
	var badge := _badge("FC", accent, COLOR_PANEL_RAISED)
	top.add_child(badge)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	top.add_child(info)
	_add_label(info, str(offer.get("club", "Klub")), 14, COLOR_TEXT, true)
	_add_label(info, str(offer.get("league", "Liga")), 9, COLOR_MUTED, false)
	var threshold := int(offer.get("required", 60))
	var state_text := "KLUB SAAT INI" if bool(offer.get("current", false)) else ("KONTRAK DITERIMA" if bool(offer.get("taken", false)) else ("TERKUNCI · OVR %d" % threshold if bool(offer.get("locked", false)) else "TERBUKA"))
	_add_label(info, state_text, 9, COLOR_GOLD if bool(offer.get("locked", false)) else accent, true)
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	card.add_child(details)
	_add_label(details, "BONUS  %d" % int(offer.get("bonus", 0)), 9, COLOR_GOLD, true)
	_add_label(details, "GAJI  %d/mgg" % int(offer.get("wage", 0)), 9, COLOR_TEXT, true)
	_add_label(details, "DURASI  %s" % str(offer.get("term", "2 musim")), 9, COLOR_MUTED, true)
	var button_text := "SUDAH DI SINI" if bool(offer.get("current", false)) else ("SUDAH DITERIMA" if bool(offer.get("taken", false)) else ("BUTUH OVR %d" % threshold if bool(offer.get("locked", false)) else "TERIMA KONTRAK"))
	var accept := _button(button_text, not bool(offer.get("locked", false)))
	accept.disabled = bool(offer.get("locked", false)) or bool(offer.get("current", false)) or bool(offer.get("taken", false))
	accept.pressed.connect(_accept_offer.bind(str(offer.get("id", ""))))
	card.add_child(accept)


func _render_profile() -> void:
	var player: Dictionary = CareerState.get_player()
	var snapshot: Dictionary = CareerState.get_snapshot()
	var club: Dictionary = snapshot.get("club", {})
	_page_head("PROFIL PEMAIN", "Data Karier", "Performa, perkembangan atribut, dan kontribusimu sepanjang musim.")
	var back := _button("← KEMBALI KE BERANDA", false)
	back.pressed.connect(_on_nav_pressed.bind("home"))
	_content.add_child(back)
	var card := _card(_content, 15, 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	card.add_child(row)
	var portrait := _image("main", 112, 152)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	row.add_child(portrait)
	var data := VBoxContainer.new()
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.alignment = BoxContainer.ALIGNMENT_CENTER
	data.add_theme_constant_override("separation", 5)
	row.add_child(data)
	_add_label(data, str(player.get("name", "Arga Pratama")), 16, COLOR_TEXT, true)
	var player_meta := HBoxContainer.new()
	player_meta.add_theme_constant_override("separation", 7)
	data.add_child(player_meta)
	player_meta.add_child(_badge(str(player.get("position", "ST")), COLOR_CYAN, COLOR_CYAN_SOFT))
	_add_label(player_meta, "USIA %d" % int(player.get("age", 18)), 10, COLOR_MUTED, true)
	_add_label(data, "OVERALL  %d" % int(player.get("overall", 60)), 22, COLOR_GOLD, true)
	_add_label(data, "LEVEL %d  ·  MORALE %d" % [int(player.get("level", 1)), int(player.get("morale", 0))], 9, COLOR_MUTED, true)
	_add_label(data, str(club.get("name", "Bintang Nusantara FC")), 10, COLOR_TEXT, false)
	var achievements := HBoxContainer.new()
	achievements.add_theme_constant_override("separation", 8)
	card.add_child(achievements)
	_metric(achievements, "GOL", str(player.get("goals", 0)), "KARIER", COLOR_GOLD)
	_metric(achievements, "ASSIST", str(player.get("assists", 0)), "KARIER", COLOR_CYAN)
	_metric(achievements, "LAGA", str(player.get("matches", 0)), "DIMAINKAN", COLOR_GREEN)
	_add_label(_content, "ATRIBUT PEMAIN", 10, COLOR_MUTED, true)
	var attributes: Dictionary = player.get("attributes", {})
	for key in CareerState.ATTRIBUTE_KEYS:
		var label_text := str(CareerState.ATTRIBUTE_LABELS.get(key, key.capitalize()))
		var val := int(attributes.get(key, 50))
		var row_stat := HBoxContainer.new()
		row_stat.add_theme_constant_override("separation", 8)
		_content.add_child(row_stat)
		var text := _label(label_text, 10, COLOR_TEXT, true)
		text.custom_minimum_size = Vector2(88, 0)
		row_stat.add_child(text)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 99
		bar.value = val
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 12)
		bar.add_theme_stylebox_override("background", _flat_style(Color("#1b3442"), Color.TRANSPARENT, 5, 0))
		bar.add_theme_stylebox_override("fill", _flat_style(COLOR_CYAN if val >= 60 else COLOR_GOLD, Color.TRANSPARENT, 5, 0))
		row_stat.add_child(bar)
		_add_label(row_stat, "%02d" % val, 11, COLOR_TEXT, true)
	var save_note := _card(_content, 14, 12)
	_add_label(save_note, "PROGRES TERSIMPAN LOKAL", 10, COLOR_GREEN, true)
	_add_label(save_note, "Karier disimpan otomatis di perangkat ini dan tetap ada saat game dibuka kembali.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_LEFT, true)


func _metric(parent: Control, title: String, value: String, caption: String, accent: Color) -> void:
	var box := _card(parent, 9, 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	_add_label(box, title, 8, COLOR_MUTED, true)
	_add_label(box, value, 19, accent, true)
	_add_label(box, caption, 8, COLOR_MUTED, false)


func _add_feedback(parent: Control) -> void:
	if _feedback_message.is_empty():
		return
	var color := COLOR_GREEN if _feedback_success else COLOR_GOLD
	var card := _card(parent, 12, 9, color)
	_add_label(card, "AKSI BERHASIL" if _feedback_success else "INFO", 9, color, true)
	_add_label(card, _feedback_message, 10, COLOR_TEXT, true, HORIZONTAL_ALIGNMENT_LEFT, true)


func _card(parent: Control, padding: int = 14, gap: int = 10, accent: Color = COLOR_LINE) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, accent, 12, 1))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin, padding, padding, padding, padding)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	margin.add_child(box)
	return box


func _panel_container() -> PanelContainer:
	return PanelContainer.new()


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	return style


func _flat_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	return _panel_style(fill, border, radius, border_width)


func _nav_style(active: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#133448") if active else (Color("#102838") if hovered else Color("#0a1b29"))
	style.border_color = COLOR_CYAN if active else COLOR_LINE
	style.set_border_width_all(0)
	style.border_width_top = 2 if active else 0
	style.set_corner_radius_all(8)
	return style


func _set_margins(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _label(text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.16))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _add_label(parent: Control, text: String, font_size: int, color: Color, bold: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var label := _label(text, font_size, color, bold)
	label.horizontal_alignment = align
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _image(key: String, width: int, height: int) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _textures.get(key) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.custom_minimum_size = Vector2(width, height)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.clip_contents = true
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", COLOR_BG if primary else COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_BG if primary else COLOR_CYAN)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(COLOR_CYAN if primary else COLOR_PANEL_RAISED, COLOR_CYAN if primary else COLOR_LINE, 9, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#6ceaf0") if primary else Color("#173d51"), COLOR_CYAN, 9, 1))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#31bdce") if primary else Color("#1a4155"), COLOR_CYAN, 9, 1))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("#162b37"), Color("#213847"), 9, 1))
	button.add_theme_stylebox_override("focus", _panel_style(COLOR_PANEL_RAISED, COLOR_CYAN, 9, 2))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _badge(text: String, accent: Color, fill: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(fill, accent, 8, 1))
	var margin := MarginContainer.new()
	_set_margins(margin, 8, 4, 8, 4)
	panel.add_child(margin)
	var label := _label(text, 9, accent, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(label)
	return panel


func _show_career_setup() -> void:
	_setup_layer = Control.new()
	_setup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_layer.z_index = 100
	add_child(_setup_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.055, 0.09, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_theme_constant_override("margin_left", 14)
	center.add_theme_constant_override("margin_right", 14)
	_setup_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 455)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, Color("#2e8b9a"), 16, 1))
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 22, 18, 22, 18)
	panel.add_child(margin)
	var form := VBoxContainer.new()
	form.alignment = BoxContainer.ALIGNMENT_CENTER
	form.add_theme_constant_override("separation", 10)
	margin.add_child(form)
	var crest := _image("crest", 74, 90)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	form.add_child(crest)
	_add_label(form, "FOOTY CAREER", 20, COLOR_TEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(form, "MULAI PERJALANANMU", 10, COLOR_CYAN, true, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(form, "Nama dan posisi pemain bisa kamu tentukan. Progres karier tersimpan otomatis di perangkat.", 10, COLOR_MUTED, false, HORIZONTAL_ALIGNMENT_CENTER, true)
	_add_label(form, "NAMA PEMAIN", 9, COLOR_MUTED, true)
	_name_edit = LineEdit.new()
	_name_edit.text = "Arga Pratama"
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "Masukkan nama pemain"
	_name_edit.custom_minimum_size = Vector2(0, 44)
	_name_edit.add_theme_font_size_override("font_size", 13)
	_name_edit.add_theme_stylebox_override("normal", _panel_style(Color("#102c3c"), COLOR_LINE, 8, 1))
	_name_edit.add_theme_stylebox_override("focus", _panel_style(Color("#102c3c"), COLOR_CYAN, 8, 2))
	form.add_child(_name_edit)
	_add_label(form, "POSISI FAVORIT", 9, COLOR_MUTED, true)
	_position_select = OptionButton.new()
	_position_select.add_item("Striker  ·  ST")
	_position_select.add_item("Gelandang serang  ·  AM")
	_position_select.add_item("Sayap  ·  WG")
	_position_select.add_item("Gelandang tengah  ·  CM")
	_position_select.add_item("Bek  ·  DF")
	_position_select.custom_minimum_size = Vector2(0, 42)
	_position_select.add_theme_font_size_override("font_size", 11)
	form.add_child(_position_select)
	var start := _button("MULAI KARIER", true)
	start.custom_minimum_size = Vector2(0, 48)
	start.pressed.connect(_start_career)
	form.add_child(start)
	_add_label(form, "BINTANG NUSANTARA FC  ·  AKADEMI PEMAIN MUDA", 8, COLOR_MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)


func _start_career() -> void:
	var player_name := _name_edit.text.strip_edges()
	if player_name.is_empty():
		_name_edit.placeholder_text = "Nama pemain tidak boleh kosong"
		_name_edit.grab_focus()
		return
	var positions: Array[String] = ["ST", "AM", "WG", "CM", "DF"]
	var selected := clampi(_position_select.selected, 0, positions.size() - 1)
	if is_instance_valid(_setup_layer):
		_setup_layer.hide()
	CareerState.start_career(player_name, positions[selected])
	_feedback_message = "Karier %s dimulai di Bintang Nusantara FC." % player_name.left(24)
	_feedback_success = true
	_current_tab = "home"
	_refresh_all()
	if is_instance_valid(_setup_layer):
		_setup_layer.queue_free()


func _set_feedback(message: String, success: bool = true) -> void:
	_feedback_message = message
	_feedback_success = success
	_refresh_all()


func _train_program(program_id: String) -> void:
	var result: Dictionary = CareerState.train(program_id)
	_set_feedback(str(result.get("message", "")), bool(result.get("ok", false)))


func _play_match() -> void:
	var result: Dictionary = CareerState.play_match()
	var message := str(result.get("message", ""))
	if bool(result.get("ok", false)):
		var record: Dictionary = result.get("record", {})
		var level_note := "  ·  LEVEL BARU!" if bool(result.get("levelled", false)) else ""
		message = "%s %d — %d %s · rating %0.1f · hadiah %d koin%s" % [str(CareerState.state["club"]["name"]), int(record.get("score_for", 0)), int(record.get("score_against", 0)), str(record.get("opponent", "")), float(record.get("rating", 6.0)), int(record.get("reward", 0)), level_note]
	_set_feedback(message, bool(result.get("ok", false)))


func _advance_week() -> void:
	var result: Dictionary = CareerState.advance_week()
	_set_feedback(str(result.get("message", "")), bool(result.get("ok", false)))


func _cycle_formation() -> void:
	var formation: String = CareerState.next_formation()
	_set_feedback("Formasi tim diubah menjadi %s." % formation, true)


func _choose_captain(player_name: String) -> void:
	CareerState.set_captain(player_name)
	_set_feedback("%s sekarang menjadi kapten tim." % player_name, true)


func _on_pitch_player_selected(index: int) -> void:
	var roster: Array[Dictionary] = CareerState.get_roster()
	if index < 0 or index >= roster.size():
		return
	_choose_captain(str(roster[index].get("name", "")))


func _accept_offer(offer_id: String) -> void:
	var result: Dictionary = CareerState.accept_offer(offer_id)
	_set_feedback(str(result.get("message", "")), bool(result.get("ok", false)))


func _open_profile() -> void:
	_current_tab = "profile"
	_refresh_all()
	_scroll.scroll_vertical = 0


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
