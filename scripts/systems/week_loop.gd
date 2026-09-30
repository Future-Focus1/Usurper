class_name WeekLoop
extends RefCounted

## The campaign week, in the order the player lives it.
## Briefing, then petitions, then one decree, then the realm's answer.


static func phase_title(phase: String) -> String:
	match phase:
		"event":
			return "Petitions"
		"action":
			return "Decree"
		"response":
			return "The Realm Answers"
		_:
			return "Briefing"


static func primary_label(phase: String, has_decree: bool) -> String:
	match phase:
		"event":
			return ""
		"action":
			return "Issue this decree" if has_decree else "Choose one decree"
		"response":
			return "Start the next week"
		_:
			return "Hear the petitions"


static func forecast(state: CampaignState, db: ContentDB) -> PackedStringArray:
	var lines := PackedStringArray()
	var gold_in := 0
	var food_in := 0
	var lands := state.player_territories()
	for tid in lands:
		var data: Dictionary = db.territories.get(tid, {})
		var loyalty := int(state.territories[tid].get("loyalty", 50))
		gold_in += Balance.scaled_yield(int(data.get("gold", 0)), loyalty)
		food_in += Balance.scaled_yield(int(data.get("rations", 0)), loyalty)
	if lands.is_empty():
		lines.append("You hold no land, so nothing is collected in your name.")
	else:
		lines.append("Your lands should bring %s gold and %d rations, if they stay yours." % [Balance.comma(gold_in), food_in])
	var meals := Balance.ration_need(state.forces)
	var pay := Balance.gold_upkeep(state.forces)
	if state.forces <= 0:
		lines.append("You have no host to feed or pay.")
	else:
		lines.append("The host will eat %d rations and is owed %s gold." % [meals, Balance.comma(pay)])
		if state.rations + food_in < meals:
			lines.append("After the expected harvest, the stores remain short by %d rations. Soldiers will leave if that stands." % (meals - state.rations - food_in))
		if state.gold + gold_in < pay:
			lines.append("After expected taxes, the purse remains short by %s gold. Unpaid soldiers stop obeying." % Balance.comma(pay - state.gold - gold_in))
	return lines
