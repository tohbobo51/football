extends Control

signal player_selected(roster_index: int)

const FIELD_COLOR := Color("#0b514c")
const STRIPE_A := Color("#0d5b53")
const STRIPE_B := Color("#0c554e")
const LINE_COLOR := Color("#8be4d5")
const HOME_COLOR := Color("#42d5e5")
const CAPTAIN_COLOR := Color("#ffd166")

var _roster: Array[Dictionary] = []
var _formation := "4-3-3"
var _captain := ""
var _positions: Array[Vector2] = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, 294)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func set_lineup(roster: Array[Dictionary], formation: String, captain: String) -> void:
	_roster = roster.duplicate(true)
	_formation = formation
	_captain = captain
	_positions = _formation_positions(_formation)
	queue_redraw()


func _formation_positions(formation: String) -> Array[Vector2]:
	var rows: Array[Vector2] = []
	if formation == "4-2-3-1":
		rows = [
			Vector2(0.50, 0.91), Vector2(0.13, 0.74), Vector2(0.37, 0.76), Vector2(0.63, 0.76), Vector2(0.87, 0.74),
			Vector2(0.35, 0.58), Vector2(0.65, 0.58), Vector2(0.18, 0.39), Vector2(0.50, 0.35), Vector2(0.82, 0.39), Vector2(0.50, 0.19)
		]
	elif formation == "3-5-2":
		rows = [
			Vector2(0.50, 0.91), Vector2(0.22, 0.73), Vector2(0.50, 0.76), Vector2(0.78, 0.73),
			Vector2(0.12, 0.54), Vector2(0.32, 0.56), Vector2(0.50, 0.50), Vector2(0.68, 0.56), Vector2(0.88, 0.54),
			Vector2(0.36, 0.28), Vector2(0.64, 0.28)
		]
	else:
		rows = [
			Vector2(0.50, 0.91), Vector2(0.12, 0.72), Vector2(0.36, 0.75), Vector2(0.64, 0.75), Vector2(0.88, 0.72),
			Vector2(0.24, 0.53), Vector2(0.50, 0.58), Vector2(0.76, 0.53),
			Vector2(0.17, 0.31), Vector2(0.50, 0.25), Vector2(0.83, 0.31)
		]
	return rows


func _draw() -> void:
	var field := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	if field.size.x < 20.0 or field.size.y < 40.0:
		return
	draw_rect(field, FIELD_COLOR, true)
	var band_height := field.size.y / 10.0
	for i in range(10):
		var band := Rect2(field.position.x, field.position.y + float(i) * band_height, field.size.x, band_height)
		draw_rect(band, STRIPE_A if i % 2 == 0 else STRIPE_B, true)
	var inset := 15.0
	var inner := Rect2(field.position + Vector2(inset, inset), field.size - Vector2(inset * 2.0, inset * 2.0))
	var lw := 1.4
	draw_rect(inner, LINE_COLOR, false, lw)
	var mid_y := inner.position.y + inner.size.y * 0.5
	draw_line(Vector2(inner.position.x, mid_y), Vector2(inner.end.x, mid_y), LINE_COLOR, lw)
	draw_arc(Vector2(inner.get_center().x, mid_y), inner.size.x * 0.135, 0.0, TAU, 52, LINE_COLOR, lw)
	draw_circle(Vector2(inner.get_center().x, mid_y), 2.2, LINE_COLOR)
	var box_width := inner.size.x * 0.58
	var box_height := inner.size.y * 0.15
	var box_x := inner.get_center().x - box_width * 0.5
	draw_rect(Rect2(box_x, inner.position.y, box_width, box_height), LINE_COLOR, false, lw)
	draw_rect(Rect2(box_x, inner.end.y - box_height, box_width, box_height), LINE_COLOR, false, lw)
	var small_w := box_width * 0.54
	var small_h := box_height * 0.36
	draw_rect(Rect2(inner.get_center().x - small_w * 0.5, inner.position.y, small_w, small_h), LINE_COLOR, false, lw)
	draw_rect(Rect2(inner.get_center().x - small_w * 0.5, inner.end.y - small_h, small_w, small_h), LINE_COLOR, false, lw)
	draw_arc(Vector2(inner.get_center().x, inner.position.y + box_height * 0.91), inner.size.x * 0.095, 0.0, TAU, 36, LINE_COLOR, lw)
	draw_arc(Vector2(inner.get_center().x, inner.end.y - box_height * 0.91), inner.size.x * 0.095, 0.0, TAU, 36, LINE_COLOR, lw)
	_draw_players(inner)


func _draw_players(field: Rect2) -> void:
	if _positions.is_empty():
		_positions = _formation_positions(_formation)
	var font: Font = ThemeDB.fallback_font
	for index in range(mini(_positions.size(), _roster.size())):
		var point := field.position + Vector2(_positions[index].x * field.size.x, _positions[index].y * field.size.y)
		var player: Dictionary = _roster[index]
		var is_captain := str(player.get("name", "")) == _captain
		var radius := 13.5
		draw_circle(point + Vector2(0, 2), radius + 1.7, Color(0, 0, 0, 0.25))
		draw_circle(point, radius + 2.4, CAPTAIN_COLOR if is_captain else Color("#b9f8f4"))
		draw_circle(point, radius, Color("#0a2635"))
		draw_circle(point, radius - 2.3, CAPTAIN_COLOR if is_captain else HOME_COLOR)
		var number := str(index + 1)
		var font_size := 9 if index + 1 < 10 else 7
		var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, point + Vector2(-text_size.x * 0.5, 3.4), number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#06202a"))


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var touch_position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
		touch_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		touch_position = event.position
	if not pressed:
		return
	var field := Rect2(Vector2(19, 19), size - Vector2(38, 38))
	for index in range(mini(_positions.size(), _roster.size())):
		var point := field.position + Vector2(_positions[index].x * field.size.x, _positions[index].y * field.size.y)
		if point.distance_to(touch_position) <= 25.0:
			player_selected.emit(index)
			accept_event()
			return
