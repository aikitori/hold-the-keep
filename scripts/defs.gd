class_name Defs
extends RefCounted
## Spielwerte: Türme, Gegner, Wellen. Reichweite in Feldern, Tempo in Feldern pro Sekunde.

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
## projectile "melee": trifft sofort (Nahkampf).
const TOWERS := {
	&"wall": {
		"name": "Mauer", "cost": 5, "info": "Blockiert nur. Billig, gut für Labyrinthe.",
		"parts": ["castle/wall"], "damage": 0, "range": 0.0, "cooldown": 0.0,
	},
	&"bowman": {
		"name": "Schütze", "cost": 10, "info": "Bogenschütze auf dem Feld. Günstig, mittlere Reichweite.",
		"parts": ["castle/tower-top"], "unit": "dungeon/character-human", "props": [],
		"damage": 5, "range": 3.0, "cooldown": 0.65, "projectile": "arrow", "speed": 12.0,
	},
	&"spearman": {
		"name": "Speerträger", "cost": 20, "info": "Hält die Stellung: kurze Reichweite, harter Stoß.",
		"parts": ["castle/tower-top"], "unit": "dungeon/character-human", "props": ["dungeon/weapon-spear", "dungeon/shield-round"],
		"damage": 20, "range": 1.6, "cooldown": 0.9, "projectile": "melee", "speed": 0.0,
	},
	&"archer": {
		"name": "Bogenturm", "cost": 15, "info": "Schnelle Pfeile auf einen Gegner.",
		"parts": ["castle/tower-square-base", "castle/tower-square-top"], "level_parts": ["castle/tower-square-mid"],
		"damage": 7, "range": 3.5, "cooldown": 0.7, "projectile": "arrow", "speed": 14.0,
	},
	&"ballista": {
		"name": "Balliste", "cost": 35, "info": "Weit und stark gegen einzelne Gegner.",
		"parts": ["castle/tower-base", "castle/tower-top"], "weapon": "castle/siege-ballista", "scale": 0.5,
		"level_parts": ["castle/tower-hexagon-mid"],
		"damage": 34, "range": 5.0, "cooldown": 1.6, "projectile": "bolt", "speed": 18.0,
	},
	&"catapult": {
		"name": "Katapult", "cost": 45, "info": "Felsbrocken treffen alle in der Nähe.",
		"parts": [], "weapon": "castle/siege-catapult", "scale": 0.42, "level_parts": [],
		"damage": 20, "range": 4.0, "cooldown": 2.2, "projectile": "boulder", "speed": 7.0, "splash": 1.2,
	},
	&"mage": {
		"name": "Magierturm", "cost": 40, "info": "Magie verlangsamt Gegner.",
		"parts": ["castle/tower-hexagon-base", "castle/tower-hexagon-roof"], "level_parts": ["castle/tower-hexagon-mid"],
		"damage": 8, "range": 3.5, "cooldown": 0.9, "projectile": "magic", "speed": 10.0, "slow": 0.45,
		"slow_time": 1.6,
	},
	&"trebuchet": {
		"name": "Trebuchet", "cost": 90, "info": "Riesige Reichweite, großer Einschlag, langsam.",
		"parts": [], "weapon": "castle/siege-trebuchet", "scale": 0.4, "level_parts": [],
		"damage": 75, "range": 7.5, "cooldown": 4.0, "projectile": "boulder", "speed": 6.0, "splash": 1.8,
	},
}
const BUILD_ORDER: Array[StringName] = [&"wall", &"bowman", &"spearman", &"archer", &"ballista", &"catapult", &"mage", &"trebuchet"]

## model: Figur, lift: Höhe über dem Boden (manche Figuren stehen tiefer im Modell).
const ENEMIES := {
	&"skeleton": {"name": "Skelett", "model": "graveyard/character-skeleton", "hp": 28.0, "speed": 1.5, "gold": 2, "lift": 0.2},
	&"bandit": {"name": "Räuber", "model": "dungeon/character-human", "hp": 45.0, "speed": 1.2, "gold": 2, "lift": 0.0},
	&"zombie": {"name": "Zombie", "model": "graveyard/character-zombie", "hp": 75.0, "speed": 0.8, "gold": 3, "lift": 0.2},
	&"ghost": {"name": "Geist", "model": "graveyard/character-ghost", "hp": 36.0, "speed": 2.1, "gold": 3, "lift": 0.35},
	&"orc": {"name": "Ork", "model": "dungeon/character-orc", "hp": 110.0, "speed": 1.0, "gold": 4, "lift": 0.0},
	&"vampire": {"name": "Vampir", "model": "graveyard/character-vampire", "hp": 650.0, "speed": 0.9, "gold": 30, "lift": 0.2, "boss": true, "size": 1.8},
	&"keeper": {"name": "Totengräber", "model": "graveyard/character-keeper", "hp": 1600.0, "speed": 0.75, "gold": 70, "lift": 0.2, "boss": true, "size": 2.2},
}
const WAVE_CYCLE: Array[StringName] = [&"skeleton", &"bandit", &"zombie", &"ghost", &"orc"]


## Gegner einer Welle (1-basiert) in der Reihenfolge, in der sie erscheinen.
static func wave(number: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var kind: StringName = WAVE_CYCLE[(number - 1) % WAVE_CYCLE.size()]
	var count := 8 + number / 2
	if number % 10 == 0:
		out.append(&"keeper")
		count = 6
	elif number % 5 == 0:
		out.append(&"vampire")
		count = 6
	for i in count:
		# Ab Welle 11 mischt sich die nächste Art dazu.
		var mix: StringName = WAVE_CYCLE[number % WAVE_CYCLE.size()]
		out.append(mix if number > 10 and i % 3 == 2 else kind)
	return out


## Lebenspunkte wachsen je Welle um 13 %.
static func health_factor(number: int) -> float:
	return pow(1.13, number - 1)


static func tower_damage(id: StringName, level: int) -> float:
	return TOWERS[id]["damage"] * pow(LEVEL_DAMAGE, level - 1)


static func tower_range(id: StringName, level: int) -> float:
	return TOWERS[id]["range"] + LEVEL_RANGE * (level - 1) if TOWERS[id]["range"] > 0.0 else 0.0


static func tower_cooldown(id: StringName, level: int) -> float:
	return TOWERS[id]["cooldown"] * pow(LEVEL_COOLDOWN, level - 1)


## Kosten für den Ausbau von `level` auf `level + 1`, -1 wenn es keinen gibt.
static func upgrade_cost(id: StringName, level: int) -> int:
	if id == &"wall" or level >= MAX_LEVEL:
		return -1
	return roundi(TOWERS[id]["cost"] * UPGRADE_SHARE[level - 1])
