class_name Ranking
extends RefCounted
## 로컬 웨이브 랭킹 저장/조회. user://rankings.json 에 저장되며 기기 로컬에만 남는다.

const SAVE_PATH := "user://rankings.json"
const MAX_ENTRIES := 100
const MAX_MESSAGE_LEN := 10


## 웨이브 내림차순으로 정렬된 랭킹 목록을 반환. 각 항목: {message, wave, kills}.
static func load_entries() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return []
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_ARRAY:
		return []
	return data


## 새 기록을 저장하고(웨이브 내림차순 정렬, 최대 MAX_ENTRIES개 유지) 등록된 순위(1부터)를 반환.
static func submit(message: String, wave: int, kills: int) -> int:
	var entries := load_entries()
	var entry := {
		"message": message.strip_edges().substr(0, MAX_MESSAGE_LEN),
		"wave": wave,
		"kills": kills,
	}
	entries.append(entry)
	entries.sort_custom(func(a, b): return int(a["wave"]) > int(b["wave"]))
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(entries))
		f.close()
	return entries.find(entry) + 1
