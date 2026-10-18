class_name Defs
extends RefCounted
## Spielwerte: Türme, Spezialisierungen, Gegner, Wellen. Reichweite in Feldern, Tempo in Feldern pro Sekunde.

const START_GOLD := 90
const START_LIVES := 20
const WAVES := 30
const FIRST_WAVE_DELAY := 25.0
const WAVE_BREAK := 15.0
const SPAWN_GAP := 0.9
const SELL_SHARE := 0.7
const MAX_LEVEL := 3
## Pro Stufe: Schaden x1,7, Reichweite +0,4, Nachladen x0,9. Ausbau kostet 80 % bzw. 130 % des Grundpreises.
const LEVEL_DAMAGE := 1.7
const LEVEL_RANGE := 0.4
const LEVEL_COOLDOWN := 0.9
const UPGRADE_SHARE: Array[float] = [0.8, 1.3]

## parts: Modellteile von unten nach oben (castle/...), weapon: Waffe oben drauf, scale: Größe der Waffe.
## level_parts: kommt mit Stufe 2 und 3 unter die Spitze (der Turm wächst).
## unit: eine Figur, die fest auf ihrem Feld steht und sich zum Ziel dreht (props: was sie in der Hand hält).
## targets: "ground", "air" oder "both". projectile "melee": trifft sofort (Nahkampf).
const TOWERS := {
	&"wall": {
		"name": "Mauer", "cost": 5, "info": "Blockiert nur. Billig, gut für Labyrinthe.",
		"parts": ["castle/wall"], "damage": 0, "range": 0.0, "cooldown": 0.0, "targets": "ground",
	},
	&"bowman": {
		"name": "Schütze", "cost": 10, "info": "Bogenschütze auf dem Feld. Günstig, trifft Boden und Luft.",
		"parts": ["castle/tower-top"], "unit": "dungeon/character-human", "props": [],
		"damage": 5, "range": 3.0, "cooldown": 0.65, "projectile": "arrow", "speed": 12.0, "targets": "both",
	},
	&"spearman": {
		"name": "Speerträger", "cost": 20, "info": "Hält die Stellung: kurze Reichweite, harter Stoß. Nur Boden.",
		"parts": ["castle/tower-top"], "unit": "dungeon/character-human", "props": ["dungeon/weapon-spear", "dungeon/shield-round"],
		"damage": 20, "range": 1.6, "cooldown": 0.9, "projectile": "melee", "speed": 0.0, "targets": "ground",
	},
	&"archer": {
		"name": "Bogenturm", "cost": 15, "info": "Schnelle Pfeile auf einen Gegner, Boden und Luft.",
		"parts": ["castle/tower-square-base", "castle/tower-square-top"], "level_parts": ["castle/tower-square-mid"],
		"damage": 7, "range": 3.5, "cooldown": 0.7, "projectile": "arrow", "speed": 14.0, "targets": "both",
	},
	&"ballista": {
		"name": "Balliste", "cost": 35, "info": "Weit und stark gegen einzelne Gegner am Boden.",
		"parts": ["castle/tower-base", "castle/tower-top"], "weapon": "castle/siege-ballista", "scale": 0.55,
		"level_parts": ["castle/tower-hexagon-mid"],
		"damage": 34, "range": 5.0, "cooldown": 1.6, "projectile": "bolt", "speed": 18.0, "targets": "ground",
	},
	&"catapult": {
		"name": "Katapult", "cost": 45, "info": "Felsbrocken treffen alle in der Nähe. Nur Boden.",
		"parts": [], "weapon": "castle/siege-catapult", "scale": 0.5, "level_parts": [],
		"damage": 20, "range": 4.0, "cooldown": 2.2, "projectile": "boulder", "speed": 7.0, "splash": 1.2,
		"targets": "ground",
	},
	&"mage": {
		"name": "Magierturm", "cost": 40, "info": "Magie verlangsamt Gegner, Boden und Luft.",
		"parts": ["castle/tower-hexagon-base", "castle/tower-hexagon-roof"], "level_parts": ["castle/tower-hexagon-mid"],
		"damage": 8, "range": 3.5, "cooldown": 0.9, "projectile": "magic", "speed": 10.0, "slow": 0.45,
		"slow_time": 1.6, "targets": "both",
	},
	&"skyguard": {
		"name": "Himmelswacht", "cost": 30, "info": "Feuerpfeile gegen fliegende Gegner. Trifft nur Luft.",
		"parts": ["castle/tower-square-base", "castle/tower-square-mid-windows", "castle/tower-slant-roof"],
		"level_parts": ["castle/tower-square-mid"],
		"damage": 26, "range": 5.0, "cooldown": 0.7, "projectile": "fire", "speed": 16.0, "targets": "air",
	},
	&"trebuchet": {
		"name": "Trebuchet", "cost": 90, "info": "Riesige Reichweite, großer Einschlag, langsam. Nur Boden.",
		"parts": [], "weapon": "castle/siege-trebuchet", "scale": 0.5, "level_parts": [],
		"damage": 75, "range": 7.5, "cooldown": 4.0, "projectile": "boulder", "speed": 6.0, "splash": 1.8,
		"targets": "ground",
	},
}
const BUILD_ORDER: Array[StringName] = [&"wall", &"bowman", &"spearman", &"archer", &"ballista", &"catapult",
		&"mage", &"skyguard", &"trebuchet"]

## Spezialisierung auf Stufe 3: je Turm zwei Wege. Werte wirken auf die Stufe-3-Werte:
## damage (Faktor), range (+Felder), cooldown (Faktor), multishot (Ziele gleichzeitig), chain (springt auf
## weitere Gegner), burn (Schaden pro Sekunde für 3 s), slow, splash, targets.
const SPECS := {
	&"bowman": [
		{"id": &"longbow", "name": "Langbogen", "info": "Viel weiter und stärker.", "cost": 30, "damage": 1.6, "range": 1.5},
		{"id": &"volley", "name": "Salve", "info": "Drei Pfeile auf drei Gegner.", "cost": 35, "multishot": 3},
	],
	&"spearman": [
		{"id": &"knight", "name": "Ritter", "info": "Schwerer Stoß.", "cost": 45, "damage": 2.3},
		{"id": &"pike", "name": "Pikenier", "info": "Trifft alle Gegner rundherum.", "cost": 45, "splash": 1.4, "range": 0.4},
	],
	&"archer": [
		{"id": &"fire_arrows", "name": "Feuerpfeile", "info": "Gegner brennen nach.", "cost": 40, "burn": 12.0},
		{"id": &"volley_tower", "name": "Salventurm", "info": "Vier Ziele gleichzeitig.", "cost": 45, "multishot": 4},
	],
	&"ballista": [
		{"id": &"heavy_bolt", "name": "Riesenbolzen", "info": "Doppelter Schaden, etwas langsamer.", "cost": 80, "damage": 2.6, "cooldown": 1.2},
		{"id": &"sky_ballista", "name": "Flakballiste", "info": "Trifft jetzt auch fliegende Gegner.", "cost": 60, "targets": "both", "range": 1.0},
	],
	&"catapult": [
		{"id": &"fire_pot", "name": "Brandtöpfe", "info": "Der Einschlag brennt nach.", "cost": 90, "burn": 20.0, "splash": 1.6},
		{"id": &"hail", "name": "Steinhagel", "info": "Wirft doppelt so schnell.", "cost": 90, "cooldown": 0.5},
	],
	&"mage": [
		{"id": &"frost", "name": "Frostmagier", "info": "Verlangsamt viel stärker.", "cost": 70, "slow": 0.7, "damage": 1.4},
		{"id": &"lightning", "name": "Blitzmagier", "info": "Der Blitz springt auf vier Gegner.", "cost": 80, "chain": 4, "damage": 1.8},
	],
	&"skyguard": [
		{"id": &"storm", "name": "Sturmturm", "info": "Drei Feuerpfeile gleichzeitig.", "cost": 60, "multishot": 3},
		{"id": &"eagle", "name": "Adlerhorst", "info": "Weiter und viel stärker.", "cost": 60, "range": 2.0, "damage": 1.9},
	],
	&"trebuchet": [
		{"id": &"devastation", "name": "Verheerung", "info": "Riesiger Einschlag.", "cost": 160, "splash": 2.8, "damage": 1.5},
		{"id": &"precision", "name": "Präzision", "info": "Noch weiter, dreifacher Schaden.", "cost": 160, "range": 3.0, "damage": 3.0},
	],
}

## model: Figur, lift: Höhe über dem Boden (manche Figuren stehen tiefer im Modell), air: fliegt geradeaus
## über alles hinweg (von Kontrollpunkt zu Kontrollpunkt).
const ENEMIES := {
	&"skeleton": {"name": "Skelett", "model": "graveyard/character-skeleton", "hp": 28.0, "speed": 1.5, "gold": 2, "lift": 0.2},
	&"bandit": {"name": "Räuber", "model": "dungeon/character-human", "hp": 45.0, "speed": 1.2, "gold": 2, "lift": 0.0},
	&"zombie": {"name": "Zombie", "model": "graveyard/character-zombie", "hp": 75.0, "speed": 0.8, "gold": 3, "lift": 0.2},
	&"orc": {"name": "Ork", "model": "dungeon/character-orc", "hp": 110.0, "speed": 1.0, "gold": 4, "lift": 0.0},
	&"ghost": {"name": "Geist", "model": "graveyard/character-ghost", "hp": 55.0, "speed": 1.3, "gold": 3, "lift": 1.4, "air": true},
	&"vampire": {"name": "Vampir", "model": "graveyard/character-vampire", "hp": 650.0, "speed": 0.9, "gold": 30, "lift": 0.2, "boss": true, "size": 1.8},
	&"keeper": {"name": "Totengräber", "model": "graveyard/character-keeper", "hp": 1600.0, "speed": 0.75, "gold": 70, "lift": 0.2, "boss": true, "size": 2.2},
}
const WAVE_CYCLE: Array[StringName] = [&"skeleton", &"bandit", &"zombie", &"orc"]
## Luftwellen: 4, 9, 14, ... (jede fünfte, eine vor dem Boss).
const AIR_WAVE_EVERY := 5
const AIR_WAVE_OFFSET := 4


static func is_air_wave(number: int) -> bool:
	return number % AIR_WAVE_EVERY == AIR_WAVE_OFFSET


## Gegner einer Welle (1-basiert) in der Reihenfolge, in der sie erscheinen.
static func wave(number: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if is_air_wave(number):
		for i in 6 + number / 3:
			out.append(&"ghost")
		return out
	var kind: StringName = WAVE_CYCLE[(number - 1) % WAVE_CYCLE.size()]
	var count := 8 + number / 2
	if number % 10 == 0:
		out.append(&"keeper")
		count = 6
	elif number % 5 == 0:
		out.append(&"vampire")
		count = 6
	for i in count:
		# Ab Welle 11 mischt sich die nächste Art dazu, ab Welle 16 auch ein paar Geister.
		var mix: StringName = WAVE_CYCLE[number % WAVE_CYCLE.size()]
		if number > 15 and i % 5 == 4:
			out.append(&"ghost")
		else:
			out.append(mix if number > 10 and i % 3 == 2 else kind)
	return out


## Lebenspunkte wachsen je Welle um 13 %.
static func health_factor(number: int) -> float:
	return pow(1.13, number - 1)


static func spec(id: StringName, spec_id: StringName) -> Dictionary:
	for entry: Dictionary in SPECS.get(id, []):
		if entry["id"] == spec_id:
			return entry
	return {}


static func tower_damage(id: StringName, level: int, spec_id: StringName = &"") -> float:
	return TOWERS[id]["damage"] * pow(LEVEL_DAMAGE, level - 1) * spec(id, spec_id).get("damage", 1.0)


static func tower_range(id: StringName, level: int, spec_id: StringName = &"") -> float:
	if TOWERS[id]["range"] <= 0.0:
		return 0.0
	return TOWERS[id]["range"] + LEVEL_RANGE * (level - 1) + spec(id, spec_id).get("range", 0.0)


static func tower_cooldown(id: StringName, level: int, spec_id: StringName = &"") -> float:
	return TOWERS[id]["cooldown"] * pow(LEVEL_COOLDOWN, level - 1) * spec(id, spec_id).get("cooldown", 1.0)


static func tower_targets(id: StringName, spec_id: StringName = &"") -> String:
	return spec(id, spec_id).get("targets", TOWERS[id]["targets"])


## Kosten für den Ausbau von `level` auf `level + 1`, -1 wenn es keinen gibt (dann ggf. Spezialisierung).
static func upgrade_cost(id: StringName, level: int) -> int:
	if id == &"wall" or level >= MAX_LEVEL:
		return -1
	return roundi(TOWERS[id]["cost"] * UPGRADE_SHARE[level - 1])
