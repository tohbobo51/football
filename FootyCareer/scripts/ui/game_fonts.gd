extends RefCounted

static func create_theme(regular: Font, medium: Font = null, bold: Font = null) -> Theme:
	assert(regular != null, "A project font is required")
	var theme := Theme.new()
	theme.default_font = regular
	if medium != null:
		for control_type: String in ["Button", "CheckButton", "CheckBox", "OptionButton", "MenuButton"]:
			theme.set_font("font", control_type, medium)
	if bold != null:
		theme.set_font("normal_font", "RichTextLabel", regular)
		theme.set_font("bold_font", "RichTextLabel", bold)
	return theme

static func apply_world_label(label: Label3D, font: Font) -> void:
	assert(font != null, "A project font is required")
	label.font = font
