extends RefCounted

# Spara framsteg mellan banor och menybesök.
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

# Spara bästa poäng och medaljantal per bana.
static func save_best(level: int, score: int, medals: int) -> Error:
 var save := ConfigFile.new()
 save.load(save_path)
 var key := "level_%d" % level
 if score > int(save.get_value("best_score", key, 0)):
  save.set_value("best_score", key, score)
 if medals > int(save.get_value("best_medals", key, 0)):
  save.set_value("best_medals", key, medals)
 var error := save.save(save_path)
 if error != OK:
  push_error("Could not save best result: " + error_string(error))
 return error

static func get_best_score(level: int) -> int:
 var save := ConfigFile.new()
 if save.load(save_path) != OK:
  return 0
 return int(save.get_value("best_score", "level_%d" % level, 0))

static func get_best_medals(level: int) -> int:
 var save := ConfigFile.new()
 if save.load(save_path) != OK:
  return 0
 return int(save.get_value("best_medals", "level_%d" % level, 0))
