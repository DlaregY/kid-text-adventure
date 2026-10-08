extends RefCounted
# Test scripts deliberately mutate user://. Refuse to run in a player's directory.
# tests/run_checks.py supplies a random, startup-time custom directory in a staged project.
static func enter() -> bool:
	var name := OS.get_environment("IKE_QUEST_QA_DIR_NAME")
	var pattern := RegEx.new()
	pattern.compile("^ike-quest-qa-[0-9a-f]{32}$")
	var data_dir := OS.get_user_data_dir().replace("\\", "/").trim_suffix("/")
	if pattern.search(name) == null or data_dir.get_file() != name or not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)) or str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")) != name:
		printerr("Refusing to modify player data. Run python3 tests/run_checks.py instead.")
		return false
	var marker := FileAccess.open("user://.ike-quest-qa", FileAccess.WRITE)
	var receipt := FileAccess.open("res://.qa-user-data-path", FileAccess.WRITE)
	if marker == null or receipt == null:
		printerr("Could not initialize isolated QA data.")
		return false
	marker.store_string(name)
	receipt.store_string(data_dir)
	marker.close()
	receipt.close()
	return true
