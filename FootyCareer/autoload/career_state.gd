extends Node

signal state_changed

const SAVE_PATH := "user://footy_career_save.json"
const TEMP_PATH := "user://footy_career_save.tmp"
const SAVE_VERSION := 1
const SEASON_LENGTH := 12
const ATTRIBUTE_KEYS: Array[String] = ["shooting", "passing", "dribble", "pace", "stamina", "tackle", "vision"]
const ATTRIBUTE_LABELS := {
	"shooting": "Tembakan",
	"passing": "Umpan",
	"dribble": "Dribel",
	"pace": "Kecepatan",
	"stamina": "Stamina",
	"tackle": "Tekel",
	"vision": "Visi"
}
const TRAINING_PROGRAMS := {
	"finishing": {"label": "Finishing", "attribute": "shooting", "energy": 18, "xp": 26, "boost": 2, "hint": "Akurasi dan ketenangan di depan gawang"},
	"playmaking": {"label": "Playmaking", "attribute": "passing", "energy": 16, "xp": 24, "boost": 2, "hint": "Umpan, visi, dan kontrol tempo"},
	"sprint": {"label": "Sprint & stamina", "attribute": "pace", "energy": 20, "xp": 30, "boost": 2, "hint": "Ledakan langkah dan daya tahan"},
	"technique": {"label": "Teknik bola", "attribute": "dribble", "energy": 16, "xp": 24, "boost": 2, "hint": "Sentuhan pertama dan kelincahan"}
}
const FORMATIONS: Array[String] = ["4-3-3", "4-2-3-1", "3-5-2"]
const OPPONENTS: Array[String] = ["Rajawali Metro", "Garuda Selatan", "Pesisir United", "Bara Muda FC", "Singa Timur", "Samudra Atletik"]
const TRANSFER_OFFERS: Array[Dictionary] = [
	{"id": "pesisir", "club": "Pesisir United", "league": "Liga Nusantara · posisi 8", "required": 58, "bonus": 120, "wage": 155, "term": "2 musim", "accent": Color("#46d7df")},
	{"id": "mataram", "club": "Mataram Athletic", "league": "Liga Nusantara · posisi 4", "required": 63, "bonus": 260, "wage": 285, "term": "3 musim", "accent": Color("#ffcb6b")},
	{"id": "surya", "club": "Surya Bandung", "league": "Liga Utama · posisi 2", "required": 68, "bonus": 420, "wage": 460, "term": "3 musim", "accent": Color("#91a9ff")}
]

var state: Dictionary = {}


func _ready() -> void:
	state = _default_state()
	_load()


func _default_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"career_started": false,
		"player": {
			"name": "Arga Pratama",
			"age": 18,
			"position": "ST",
			"attributes": {"shooting": 60, "passing": 59, "dribble": 56, "pace": 64, "stamina": 55, "tackle": 60, "vision": 61},
			"energy": 86,
			"morale": 78,
			"xp": 0,
			"level": 1,
			"goals": 0,
			"assists": 0,
			"matches": 0,
			"best_rating": 0.0
		},
		"club": {
			"name": "Bintang Nusantara FC",
			"reputation": 1,
			"funds": 640,
			"weekly_wage": 110,
			"wins": 0,
			"draws": 0,
			"losses": 0,
			"points": 0,
			"captain": "Arga Pratama"
		},
		"week": 1,
		"season": 2026,
		"formation_index": 0,
		"played_this_week": false,
		"opponent": "Rajawali Metro",
		"history": [],
		"last_result": {},
		"dismissed_onboarding": false,
		"offers_taken": []
	}


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var saved: Dictionary = parsed
	if int(saved.get("version", 0)) != SAVE_VERSION:
		return
	state["career_started"] = bool(saved.get("career_started", false))
	state["dismissed_onboarding"] = bool(saved.get("dismissed_onboarding", false))
	state["week"] = clampi(int(saved.get("week", 1)), 1, SEASON_LENGTH)
	state["season"] = clampi(int(saved.get("season", 2026)), 2026, 2100)
	state["formation_index"] = posmod(int(saved.get("formation_index", 0)), FORMATIONS.size())
	state["played_this_week"] = bool(saved.get("played_this_week", false))
	state["opponent"] = str(saved.get("opponent", OPPONENTS[0]))
	state["last_result"] = saved.get("last_result", {}) if saved.get("last_result", {}) is Dictionary else {}
	var player_value: Variant = saved.get("player", {})
	if player_value is Dictionary:
		var player_saved: Dictionary = player_value
		state["player"]["name"] = _safe_name(str(player_saved.get("name", "Arga Pratama")))
		state["player"]["age"] = clampi(int(player_saved.get("age", 18)), 16, 45)
		state["player"]["position"] = str(player_saved.get("position", "ST")) if str(player_saved.get("position", "ST")) in ["ST", "AM", "WG", "CM", "DF"] else "ST"
		state["player"]["energy"] = clampi(int(player_saved.get("energy", 86)), 0, 100)
		state["player"]["morale"] = clampi(int(player_saved.get("morale", 78)), 0, 100)
		state["player"]["xp"] = clampi(int(player_saved.get("xp", 0)), 0, 199)
		state["player"]["level"] = clampi(int(player_saved.get("level", 1)), 1, 50)
		state["player"]["goals"] = clampi(int(player_saved.get("goals", 0)), 0, 9999)
		state["player"]["assists"] = clampi(int(player_saved.get("assists", 0)), 0, 9999)
		state["player"]["matches"] = clampi(int(player_saved.get("matches", 0)), 0, 9999)
		state["player"]["best_rating"] = clampf(float(player_saved.get("best_rating", 0.0)), 0.0, 10.0)
		var attrs_value: Variant = player_saved.get("attributes", {})
		if attrs_value is Dictionary:
			for key in ATTRIBUTE_KEYS:
				state["player"]["attributes"][key] = clampi(int(attrs_value.get(key, state["player"]["attributes"][key])), 1, 99)
	var club_value: Variant = saved.get("club", {})
	if club_value is Dictionary:
		var club_saved: Dictionary = club_value
		state["club"]["name"] = _safe_name(str(club_saved.get("name", "Bintang Nusantara FC")))
		state["club"]["reputation"] = clampi(int(club_saved.get("reputation", 1)), 1, 99)
		state["club"]["funds"] = clampi(int(club_saved.get("funds", 640)), 0, 999999)
		state["club"]["weekly_wage"] = clampi(int(club_saved.get("weekly_wage", 110)), 0, 99999)
		for key in ["wins", "draws", "losses", "points"]:
			state["club"][key] = clampi(int(club_saved.get(key, 0)), 0, 9999)
		state["club"]["captain"] = _safe_name(str(club_saved.get("captain", "Arga Pratama")))
	var history_value: Variant = saved.get("history", [])
	if history_value is Array:
		var clean_history: Array[Dictionary] = []
		for row_value in history_value:
			if row_value is Dictionary:
				clean_history.append(row_value.duplicate(true))
		state["history"] = clean_history.slice(0, 8)
	var offers_value: Variant = saved.get("offers_taken", [])
	if offers_value is Array:
		state["offers_taken"] = offers_value.duplicate()


func _safe_name(value: String) -> String:
	var cleaned := value.replace("\n", " ").replace("\r", " ").strip_edges()
	if cleaned.is_empty():
		return "Arga Pratama"
	return cleaned.left(24)


func save() -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "  "))
	file.close()
	var temporary := ProjectSettings.globalize_path(TEMP_PATH)
	var destination := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(destination)
		if remove_error != OK:
			return false
	return DirAccess.rename_absolute(temporary, destination) == OK


func start_career(player_name: String, position: String) -> void:
	state["player"]["name"] = _safe_name(player_name)
	state["player"]["position"] = position if position in ["ST", "AM", "WG", "CM", "DF"] else "ST"
	state["club"]["captain"] = state["player"]["name"]
	state["career_started"] = true
	state["dismissed_onboarding"] = true
	save()
	state_changed.emit()


func dismiss_onboarding() -> void:
	state["dismissed_onboarding"] = true
	save()
	state_changed.emit()


func has_started() -> bool:
	return bool(state.get("career_started", false))


func get_snapshot() -> Dictionary:
	return state.duplicate(true)


func get_player() -> Dictionary:
	var player: Dictionary = state.get("player", {}).duplicate(true)
	player["overall"] = get_overall()
	return player


func get_overall() -> int:
	var player: Dictionary = state.get("player", {})
	var attributes: Dictionary = player.get("attributes", {})
	var total := 0
	for key in ATTRIBUTE_KEYS:
		total += int(attributes.get(key, 50))
	return roundi(float(total) / float(ATTRIBUTE_KEYS.size()))


func get_formation() -> String:
	return FORMATIONS[posmod(int(state.get("formation_index", 0)), FORMATIONS.size())]


func next_formation() -> String:
	state["formation_index"] = posmod(int(state.get("formation_index", 0)) + 1, FORMATIONS.size())
	save()
	state_changed.emit()
	return get_formation()


func get_roster() -> Array[Dictionary]:
	var player: Dictionary = get_player()
	return [
		{"name": "Dimas Wicaksono", "position": "GK", "overall": 64, "is_captain": state["club"]["captain"] == "Dimas Wicaksono", "portrait": "teammate1"},
		{"name": "Rizky Santoso", "position": "DF", "overall": 63, "is_captain": state["club"]["captain"] == "Rizky Santoso", "portrait": "teammate2"},
		{"name": "Alif Ramadhan", "position": "DF", "overall": 62, "is_captain": state["club"]["captain"] == "Alif Ramadhan", "portrait": "teammate1"},
		{"name": "Galang Prabowo", "position": "DF", "overall": 61, "is_captain": state["club"]["captain"] == "Galang Prabowo", "portrait": "teammate2"},
		{"name": "Fikri Maulana", "position": "DF", "overall": 60, "is_captain": state["club"]["captain"] == "Fikri Maulana", "portrait": "teammate1"},
		{"name": "Fajar Nugraha", "position": "CM", "overall": 62, "is_captain": state["club"]["captain"] == "Fajar Nugraha", "portrait": "teammate2"},
		{"name": "Yoga Prasetyo", "position": "CM", "overall": 60, "is_captain": state["club"]["captain"] == "Yoga Prasetyo", "portrait": "teammate1"},
		{"name": "Rafi Hidayat", "position": "AM", "overall": 61, "is_captain": state["club"]["captain"] == "Rafi Hidayat", "portrait": "teammate2"},
		{"name": "Bima Prakoso", "position": "WG", "overall": 60, "is_captain": state["club"]["captain"] == "Bima Prakoso", "portrait": "teammate1"},
		{"name": player["name"], "position": player["position"], "overall": player["overall"], "is_captain": state["club"]["captain"] == player["name"], "portrait": "main"},
		{"name": "Yuda Firmansyah", "position": "WG", "overall": 59, "is_captain": state["club"]["captain"] == "Yuda Firmansyah", "portrait": "teammate2"}
	]


func set_captain(player_name: String) -> void:
	state["club"]["captain"] = _safe_name(player_name)
	save()
	state_changed.emit()


func get_training_programs() -> Dictionary:
	return TRAINING_PROGRAMS.duplicate(true)


func train(program_id: String) -> Dictionary:
	var program: Dictionary = TRAINING_PROGRAMS.get(program_id, {})
	if program.is_empty():
		return {"ok": false, "message": "Program latihan tidak ditemukan."}
	var energy := int(state["player"].get("energy", 0))
	var cost := int(program["energy"])
	if energy < cost:
		return {"ok": false, "message": "Energi belum cukup. Mainkan laga atau majukan pekan untuk pemulihan."}
	var attribute: String = str(program["attribute"])
	var before := int(state["player"]["attributes"].get(attribute, 50))
	if before >= 99:
		return {"ok": false, "message": "Atribut ini sudah mencapai batas tertinggi."}
	var boost := mini(int(program["boost"]), 99 - before)
	state["player"]["attributes"][attribute] = before + boost
	state["player"]["energy"] = energy - cost
	state["player"]["morale"] = mini(100, int(state["player"]["morale"]) + 3)
	var levelled := _add_xp(int(program["xp"]))
	var attribute_name: String = str(ATTRIBUTE_LABELS.get(attribute, attribute.capitalize()))
	var message := "%s +%d · energi -%d · XP +%d" % [attribute_name, boost, cost, int(program["xp"])]
	if levelled:
		message += " · LEVEL BARU!"
	save()
	state_changed.emit()
	return {"ok": true, "message": message, "levelled": levelled, "attribute": attribute_name, "boost": boost}


func _add_xp(amount: int) -> bool:
	var player: Dictionary = state["player"]
	player["xp"] = int(player["xp"]) + amount
	var threshold := 100 + (int(player["level"]) - 1) * 20
	var levelled := false
	while int(player["xp"]) >= threshold and int(player["level"]) < 50:
		player["xp"] = int(player["xp"]) - threshold
		player["level"] = int(player["level"]) + 1
		player["morale"] = mini(100, int(player["morale"]) + 8)
		levelled = true
		threshold = 100 + (int(player["level"]) - 1) * 20
	return levelled


func play_match() -> Dictionary:
	if not has_started():
		return {"ok": false, "message": "Mulai kariermu terlebih dahulu."}
	if bool(state.get("played_this_week", false)):
		return {"ok": false, "message": "Laga pekan ini sudah selesai. Majukan pekan untuk jadwal berikutnya."}
	var player: Dictionary = state["player"]
	var energy := int(player["energy"])
	if energy < 12:
		return {"ok": false, "message": "Energi terlalu rendah. Pulihkan diri sebelum bermain."}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var attributes: Dictionary = player["attributes"]
	var attacking := (int(attributes["shooting"]) + int(attributes["pace"]) + int(attributes["dribble"])) / 3.0
	var teamwork := (int(attributes["passing"]) + int(attributes["vision"]) + int(attributes["tackle"])) / 3.0
	var formation_bonus := 2.0 if get_formation() == "4-3-3" else (1.0 if get_formation() == "4-2-3-1" else -1.0)
	var strength := (attacking * 0.58) + (teamwork * 0.42) + formation_bonus + (float(energy - 60) * 0.08)
	var rival_strength := 58.0 + float((int(state["week"]) * 7 + int(state["season"])) % 13)
	var gap := strength - rival_strength
	var home_goals := clampi(rng.randi_range(0, 2) + maxi(0, int(floor(gap / 18.0))), 0, 4)
	var away_goals := clampi(rng.randi_range(0, 2) + maxi(0, int(floor(-gap / 20.0))), 0, 4)
	if home_goals == away_goals and absf(gap) > 10.0 and rng.randf() < 0.32:
		if gap > 0:
			home_goals += 1
		else:
			away_goals += 1
	var result_word := "Imbang"
	var outcome := "draw"
	var points := 1
	var reward := 35
	if home_goals > away_goals:
		result_word = "Menang"
		outcome = "win"
		points = 3
		reward = 72
	elif home_goals < away_goals:
		result_word = "Kalah"
		outcome = "loss"
		reward = 18
	var goals := 0
	if str(player["position"]) in ["ST", "WG"]:
		goals = mini(home_goals, rng.randi_range(0, home_goals))
	elif home_goals > 1 and rng.randf() > 0.55:
		goals = 1
	var rating := clampf(6.0 + (gap * 0.045) + (float(goals) * 0.35) + (0.35 if outcome == "win" else 0.0) - (0.25 if outcome == "loss" else 0.0), 4.8, 9.8)
	var assists := 1 if home_goals > 0 and goals == 0 and rng.randf() > 0.45 else 0
	player["energy"] = maxi(0, energy - 26)
	player["matches"] = int(player["matches"]) + 1
	player["goals"] = int(player["goals"]) + goals
	player["assists"] = int(player["assists"]) + assists
	player["best_rating"] = maxf(float(player["best_rating"]), rating)
	state["club"]["points"] = int(state["club"]["points"]) + points
	state["club"]["funds"] = int(state["club"]["funds"]) + reward
	state["club"][outcome + ("s" if outcome != "loss" else "es")] = int(state["club"].get(outcome + ("s" if outcome != "loss" else "es"), 0)) + 1
	var experience := 32 + points * 10 + goals * 12
	var levelled := _add_xp(experience)
	var match_record := {
		"week": int(state["week"]),
		"season": int(state["season"]),
		"opponent": str(state["opponent"]),
		"score_for": home_goals,
		"score_against": away_goals,
		"outcome": outcome,
		"rating": rating,
		"goals": goals,
		"assists": assists,
		"reward": reward,
		"points": points
	}
	state["played_this_week"] = true
	state["last_result"] = match_record.duplicate(true)
	var history: Array = state.get("history", [])
	history.push_front(match_record)
	state["history"] = history.slice(0, 8)
	save()
	state_changed.emit()
	return {"ok": true, "message": result_word, "record": match_record, "levelled": levelled}


func advance_week() -> Dictionary:
	if not bool(state.get("played_this_week", false)):
		return {"ok": false, "message": "Selesaikan pertandingan pekan ini sebelum melanjutkan."}
	var previous_week := int(state["week"])
	state["week"] = previous_week + 1
	var season_changed := false
	if int(state["week"]) > SEASON_LENGTH:
		state["week"] = 1
		state["season"] = int(state["season"]) + 1
		state["club"]["reputation"] = mini(99, int(state["club"]["reputation"]) + 1)
		state["club"]["points"] = 0
		season_changed = true
	state["opponent"] = OPPONENTS[(int(state["week"]) + int(state["season"]) - 2027) % OPPONENTS.size()]
	state["played_this_week"] = false
	state["player"]["energy"] = mini(100, int(state["player"]["energy"]) + 38)
	state["player"]["morale"] = mini(100, int(state["player"]["morale"]) + 5)
	state["club"]["funds"] = maxi(0, int(state["club"]["funds"]) - int(state["club"]["weekly_wage"]))
	save()
	state_changed.emit()
	return {"ok": true, "season_changed": season_changed, "message": "Pekan baru dimulai. Energi pulih dan jadwal berikutnya sudah tiba." if not season_changed else "Musim baru dimulai! Reputasi klub meningkat."}


func get_offers() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var taken: Array = state.get("offers_taken", [])
	var overall := get_overall()
	for offer_source in TRANSFER_OFFERS:
		var offer: Dictionary = offer_source.duplicate(true)
		offer["locked"] = overall < int(offer["required"])
		offer["current"] = str(state["club"]["name"]) == str(offer["club"])
		offer["taken"] = str(offer["id"]) in taken
		output.append(offer)
	return output


func accept_offer(offer_id: String) -> Dictionary:
	var overall := get_overall()
	for offer in TRANSFER_OFFERS:
		if str(offer["id"]) != offer_id:
			continue
		if overall < int(offer["required"]):
			return {"ok": false, "message": "Overall %d diperlukan untuk tawaran ini." % int(offer["required"])}
		if str(state["club"]["name"]) == str(offer["club"]):
			return {"ok": false, "message": "Kamu sudah bermain di klub ini."}
		var taken: Array = state.get("offers_taken", [])
		if offer_id in taken:
			return {"ok": false, "message": "Tawaran kontrak ini sudah pernah diterima."}
		state["club"]["name"] = str(offer["club"])
		state["club"]["funds"] = int(state["club"]["funds"]) + int(offer["bonus"])
		state["club"]["weekly_wage"] = int(offer["wage"])
		state["club"]["reputation"] = mini(99, int(state["club"]["reputation"]) + 1)
		taken.append(offer_id)
		state["offers_taken"] = taken
		save()
		state_changed.emit()
		return {"ok": true, "message": "Kontrak %s ditandatangani! Bonus %d koin · gaji %d/minggu." % [str(offer["club"]), int(offer["bonus"]), int(offer["wage"])]}
	return {"ok": false, "message": "Tawaran tidak ditemukan."}


func get_league_points() -> int:
	return int(state["club"].get("points", 0))


func get_record() -> Array:
	return (state.get("history", []) as Array).duplicate(true)
