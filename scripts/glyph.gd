class_name Glyph
extends Control
## Kleines Symbol, mit Vektoren gezeichnet (die Schrift hat nur Latein-1): Münze, Herz, Schädel, Sanduhr,
## Zahnrad, Pause, Abspielen, Vorspulen, Schließen, Drehen. Passt sich der Größe an, fängt keine Eingaben ab.

const OUTLINE := Color("#2b1d12")

var kind := ""
var color := Color.WHITE


static func make(glyph_kind: String, size := 24.0, tint := Color(0, 0, 0, 0)) -> Glyph:
	var glyph := Glyph.new()
	glyph.kind = glyph_kind
	glyph.custom_minimum_size = Vector2(size, size)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.color = tint if tint.a > 0.0 else {"coin": Color("#f2c14e"), "heart": Color("#e0533d"), "skull": Color("#efe2c0"),
			"hourglass": Color("#d9b26a"), "gear": Color("#efe2c0")}.get(glyph_kind, OUTLINE)
	return glyph


func set_kind(glyph_kind: String) -> void:
	kind = glyph_kind
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) / 2.0  # halbe Kantenlänge, gezeichnet wird in -1..1
	var c := size / 2.0
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match kind:
		"coin":
			draw_circle(c, s * 0.92, OUTLINE, true, -1.0, true)
			draw_circle(c, s * 0.8, color, true, -1.0, true)
			draw_arc(c, s * 0.55, 0, TAU, 24, color.darkened(0.3), s * 0.12, true)
		"heart":
			var points := PackedVector2Array()
			for i in 32:
				var t := TAU * i / 32.0
				points.append(p.call(sin(t) ** 3 * 0.9, -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) / 17.0 * 0.95 + 0.05))
			draw_colored_polygon(points, color)
			draw_polyline(points + PackedVector2Array([points[0]]), OUTLINE, maxf(1.0, s * 0.12), true)
		"skull":
			draw_circle(p.call(0, -0.15), s * 0.72, OUTLINE, true, -1.0, true)
			draw_rect(Rect2(p.call(-0.42, 0.15), Vector2(0.84, 0.7) * s), OUTLINE)
			draw_circle(p.call(0, -0.15), s * 0.6, color, true, -1.0, true)
			draw_rect(Rect2(p.call(-0.32, 0.2), Vector2(0.64, 0.55) * s), color)
			for x in [-0.27, 0.27]:
				draw_circle(p.call(x, -0.12), s * 0.17, OUTLINE, true, -1.0, true)
			for x in [-0.16, 0.0, 0.16]:
				draw_line(p.call(x, 0.5), p.call(x, 0.75), OUTLINE, maxf(1.0, s * 0.08), true)
		"hourglass":
			var glass := PackedVector2Array([p.call(-0.6, -0.8), p.call(0.6, -0.8), p.call(0.08, 0), p.call(0.6, 0.8),
					p.call(-0.6, 0.8), p.call(-0.08, 0)])
			draw_colored_polygon(glass, color)
			draw_polyline(glass + PackedVector2Array([glass[0]]), OUTLINE, maxf(1.0, s * 0.1), true)
			for y in [-0.85, 0.85]:
				draw_line(p.call(-0.75, y), p.call(0.75, y), OUTLINE, maxf(1.5, s * 0.16), true)
		"gear":
			for i in 8:
				var a := TAU * i / 8.0
				draw_line(c + Vector2.from_angle(a) * s * 0.5, c + Vector2.from_angle(a) * s * 0.95, color, s * 0.3, true)
			draw_circle(c, s * 0.68, color, true, -1.0, true)
			draw_circle(c, s * 0.28, OUTLINE, true, -1.0, true)
		"pause":
			for x in [-0.35, 0.35]:
				draw_rect(Rect2(p.call(x - 0.16, -0.7), Vector2(0.32, 1.4) * s), color)
		"play":
			draw_colored_polygon(PackedVector2Array([p.call(-0.5, -0.75), p.call(0.7, 0), p.call(-0.5, 0.75)]), color)
		"fast":
			for x in [-0.55, 0.1]:
				draw_colored_polygon(PackedVector2Array([p.call(x, -0.6), p.call(x + 0.6, 0), p.call(x, 0.6)]), color)
		"close":
			draw_line(p.call(-0.6, -0.6), p.call(0.6, 0.6), color, maxf(2.0, s * 0.25), true)
			draw_line(p.call(0.6, -0.6), p.call(-0.6, 0.6), color, maxf(2.0, s * 0.25), true)
		"turn":
			var width := maxf(2.0, s * 0.22)
			draw_arc(c, s * 0.6, deg_to_rad(-60), deg_to_rad(210), 24, color, width, true)
			var tip := c + Vector2.from_angle(deg_to_rad(-60)) * s * 0.6
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.38, -0.2) * s, tip + Vector2(0.3, -0.32) * s,
					tip + Vector2(0.12, 0.38) * s]), color)
