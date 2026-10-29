extends Node

var _failures: PackedStringArray = []
var _checks := 0
var _original_state: Dictionary = {}
var _original_save: Variant = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_original_state = CareerState.state.duplicate(true)
	_original_save = FileAccess.get_file_as_bytes(CareerState.SAVE_PATH) if FileAccess.file_exists(CareerState.SAVE_PATH) else null
	CareerState.state = CareerState._default_state()
	_check(not CareerState.has_started(), "new installation begins without a saved career")
	_check(CareerState.get_overall() >= 1, "default player has a valid overall rating")
	_check(CareerState.get_roster().size() == 11, "the starting squad fills eleven positions")
	_check(CareerState.get_formation() == "4-3-3", "default team uses the 4-3-3 formation")

	CareerState.start_career("Dara Putra", "ST")
	_check(CareerState.has_started(), "career onboarding creates a saved career")
	_check(str(CareerState.get_player().get("name", "")) == "Dara Putra", "chosen player name is retained")
	_check(bool(CareerState.state.get("dismissed_onboarding", false)), "onboarding dismissal is remembered")
	_test_training_and_match()
	_test_team_and_transfers()
	_test_snapshot_and_persistence()
	await _test_first_launch_scene()
	_restore_original_data()
	if _failures.is_empty():
		print("[footy-career-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("[footy-career-tests] " + failure)
	print("[footy-career-tests] FAIL: %d issues across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _test_training_and_match() -> void:
	var before: Dictionary = CareerState.get_player()
	var rejected: Dictionary = CareerState.train("not-a-program")
	_check(not bool(rejected.get("ok", true)), "unknown training is rejected")
	var trained: Dictionary = CareerState.train("finishing")
	var after: Dictionary = CareerState.get_player()
	_check(bool(trained.get("ok", false)), "a valid training session completes")
	_check(int(after["attributes"]["shooting"]) == int(before["attributes"]["shooting"]) + 2, "training raises the chosen attribute")
	_check(int(after["energy"]) == int(before["energy"]) - 18, "training consumes the declared energy")
	_check(int(after["xp"]) > int(before["xp"]), "training advances player experience")

	var result: Dictionary = CareerState.play_match()
	_check(bool(result.get("ok", false)), "a player with sufficient energy can play the scheduled match")
	var record: Dictionary = result.get("record", {})
	_check(record.has("score_for") and record.has("score_against"), "played match records a visible score")
	_check(int(record.get("score_for", -1)) in range(0, 5), "match score is bounded to a credible range")
	_check(int(CareerState.get_player().get("matches", 0)) == 1, "the result records one player appearance")
	_check(int(CareerState.get_player().get("energy", 100)) == int(after["energy"]) - 26, "a match consumes the documented energy")
	var duplicate: Dictionary = CareerState.play_match()
	_check(not bool(duplicate.get("ok", true)), "the same scheduled match cannot be counted twice")
	var advanced: Dictionary = CareerState.advance_week()
	_check(bool(advanced.get("ok", false)), "the calendar advances after the match")
	_check(int(CareerState.state.get("week", 1)) == 2, "the next week becomes active")
	_check(int(CareerState.get_player().get("energy", 0)) == 80, "weekly recovery replenishes 38 energy")


func _test_team_and_transfers() -> void:
	var first: String = CareerState.next_formation()
	var second: String = CareerState.next_formation()
	var third: String = CareerState.next_formation()
	_check(first == "4-2-3-1" and second == "3-5-2" and third == "4-3-3", "formation cycling covers and wraps its available tactics")
	CareerState.set_captain("Fajar Nugraha")
	var roster: Array[Dictionary] = CareerState.get_roster()
	var captain_found := false
	for player in roster:
		if str(player.get("name", "")) == "Fajar Nugraha":
			captain_found = bool(player.get("is_captain", false))
	_check(roster.size() == 11 and captain_found, "captain selection updates a full squad")
	var offers: Array[Dictionary] = CareerState.get_offers()
	_check(not offers.is_empty() and not bool(offers[0].get("locked", true)), "overall rating unlocks an eligible transfer offer")
	var accepted: Dictionary = CareerState.accept_offer("pesisir")
	_check(bool(accepted.get("ok", false)), "an eligible contract can be accepted")
	_check(str(CareerState.state["club"]["name"]) == "Pesisir United", "accepted contract changes the player's club")
	var duplicate: Dictionary = CareerState.accept_offer("pesisir")
	_check(not bool(duplicate.get("ok", true)), "a completed offer cannot be accepted twice")


func _test_snapshot_and_persistence() -> void:
	var snapshot: Dictionary = CareerState.get_snapshot()
	snapshot["week"] = 10
	_check(int(CareerState.state["week"]) != 10, "read snapshots cannot mutate the live career")
	var saved_week := int(CareerState.state["week"])
	CareerState.state["week"] = 1
	CareerState._load()
	_check(int(CareerState.state["week"]) == saved_week, "saved career restores its current week")
	_check(str(CareerState.state["club"]["name"]) == "Pesisir United", "saved transfer remains attached after reload")


func _test_first_launch_scene() -> void:
	CareerState.state = CareerState._default_state()
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "the exported game scene is available")
	if packed == null:
		return
	var main := packed.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var setup: Variant = main.get("_setup_layer")
	_check(main is Control and (setup is Control) and (setup as Control).visible, "fresh launch opens the player career onboarding")
	main.call("_on_nav_pressed", "training")
	await get_tree().process_frame
	_check(str(main.get("_current_tab")) == "training", "career tabs can switch to training")
	main.call("_on_nav_pressed", "team")
	await get_tree().process_frame
	_check(str(main.get("_current_tab")) == "team", "career tabs can switch to team tactics")
	main.queue_free()
	await get_tree().process_frame
	_check(not get_tree().root.has_node("I18n"), "the new single-language game has no inherited locale auto-switcher")


func _restore_original_data() -> void:
	CareerState.state = _original_state.duplicate(true)
	if _original_save == null:
		if FileAccess.file_exists(CareerState.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CareerState.SAVE_PATH))
		return
	var file := FileAccess.open(CareerState.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_check(false, "test preserves the pre-existing career save")
		return
	file.store_buffer(_original_save)
	file.close()
	_check(FileAccess.get_file_as_bytes(CareerState.SAVE_PATH) == _original_save, "test restores the career save byte-for-byte")


func _check(condition: bool, context: String) -> void:
	_checks += 1
	if not condition and context not in _failures:
		_failures.append(context)
