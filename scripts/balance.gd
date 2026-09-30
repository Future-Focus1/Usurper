class_name Balance
extends RefCounted

## Named campaign constants. Tune here rather than inside content or UI.

const DEBUG_ENABLED := false

const RATION_FORCE_DIVISOR := 500
const GOLD_UPKEEP_DIVISOR := 80

const BLOCS: Array[String] = ["nobility", "people", "flame", "military", "court"]

const BLOC_TITLES := {
	"nobility": "Nobility",
	"people": "Common People",
	"flame": "The Flame",
	"military": "Military",
	"court": "Court",
}

const SEASONS: Array[String] = [
	"Late Summer",
	"Early Autumn",
	"Harvest",
	"First Frosts",
	"Deep Winter",
	"The Thaw",
	"Seedtime",
	"High Summer",
]


static func ration_need(forces: int) -> int:
	if forces <= 0:
		return 0
	return maxi(1, int(ceil(float(forces) / float(RATION_FORCE_DIVISOR))))


static func gold_upkeep(forces: int) -> int:
	return int(forces / float(GOLD_UPKEEP_DIVISOR))


static func scaled_yield(base: int, loyalty: int) -> int:
	if base == 0:
		return 0
	var factor := clampf(0.45 + float(loyalty) / 170.0, 0.35, 1.3)
	return maxi(0, int(round(float(base) * factor)))


static func act_of(turn: int) -> int:
	if turn <= 8:
		return 1
	if turn <= 18:
		return 2
	if turn <= 28:
		return 3
	return 4


static func act_name(turn: int) -> String:
	match act_of(turn):
		1:
			return "The King Is Dead"
		2:
			return "The Gathering"
		3:
			return "The Fracture"
		_:
			return "The Crown"


static func date_line(turn: int) -> String:
	var idx := maxi(0, turn - 1)
	var within_year := idx % 52
	var season_index := mini(SEASONS.size() - 1, int(float(within_year) * 8.0 / 52.0))
	var season: String = SEASONS[season_index]
	var week := within_year - int(ceil(float(season_index) * 52.0 / 8.0)) + 1
	var year_index := int(idx / 52) + 1
	var year_name := "Year of the Empty Crown" if year_index == 1 else "Year %d of the Empty Crown" % year_index
	return "Week %d of %s, %s" % [week, season, year_name]


static func bloc_label(value: int) -> String:
	if value >= 60:
		return "Devoted"
	if value >= 25:
		return "Supportive"
	if value > -25:
		return "Neutral"
	if value > -60:
		return "Opposed"
	return "Hostile"


static func relation_label(value: int) -> String:
	if value >= 60:
		return "Loyal"
	if value >= 20:
		return "Warm"
	if value > -20:
		return "Neutral"
	if value > -60:
		return "Cold"
	return "Hostile"


static func fear_label(value: int) -> String:
	if value >= 75:
		return "Tyrant's Shadow"
	if value >= 55:
		return "Dreaded"
	if value >= 35:
		return "Feared"
	if value >= 15:
		return "Whispered"
	return "Little Noted"


static func bloc_title(id: String) -> String:
	return str(BLOC_TITLES.get(id, id.capitalize()))


static func comma(n: int) -> String:
	var negative := n < 0
	var digits := str(absi(n))
	var groups: PackedStringArray = []
	while digits.length() > 3:
		groups.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	groups.insert(0, digits)
	var text := ",".join(groups)
	return "-" + text if negative else text


static func signed(n: int) -> String:
	return "+%d" % n if n >= 0 else str(n)


static func human_flag(flag: String) -> String:
	return flag.replace("_", " ").to_lower()
