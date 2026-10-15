extends RefCounted

# Separate from scene state so progress survives returning to the menu.
static var save_path := "user://progress.cfg"

static func is_level_unlocked(level: int) -> bool:
 if level == 1:
  return true
 if level != 2:
  return false
 var save := ConfigFile.new()
 if save.load(save_path) != OK:
  return false
 return bool(save.get_value("completed", "level_1", false))

static func complete_level(level: int) -> Error:
 if level != 1:
  return OK
 var save := ConfigFile.new()
 save.load(save_path)
 save.set_value("completed", "level_1", true)
 var error := save.save(save_path)
 if error != OK:
  push_error("Could not save level progress: " + error_string(error))
 return error
