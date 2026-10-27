extends Control
# Original vector artwork: a rotating six-chamber evidence cylinder.
signal evidence_selected(index: int)
const GOLD = Color("ffd17b")
const PINK = Color("ff458f")
var selected = 0
var angle = 0.0
var target_angle = 0.0
var recoil = 0.0
var chamber_positions: Array[Vector2] = []

func _ready():
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func load_bullet(index: int):
    selected = index
    target_angle = -index * TAU / 6.0
    queue_redraw()

func kick():
    recoil = 1.0

func _process(dt: float):
    angle = lerp_angle(angle, target_angle, min(1.0, dt * 12.0))
    recoil = max(0.0, recoil - dt * 5.0)
    queue_redraw()

func _draw():
    var center = Vector2(150, 150) + Vector2(-9, 6) * recoil
    # Grip, steel body, knurled cylinder, and the fixed loading indicator.
    var grip = PackedVector2Array([center + Vector2(-65, 67), center + Vector2(18, 80), center + Vector2(-12, 143), center + Vector2(-86, 136)])
    draw_colored_polygon(grip, Color("242235"))
    draw_polyline(PackedVector2Array([grip[0], grip[1], grip[2], grip[3], grip[0]]), Color("7b647d"), 3.0, true)
    draw_circle(center, 123, Color("0c101a"))
    draw_arc(center, 123, 0, TAU, 96, PINK, 3, true)
    draw_circle(center, 113, Color("303246"))
    draw_arc(center, 110, 0, TAU, 96, Color("a49ca9"), 3, true)
    for i in range(24):
        var a = i * TAU / 24.0 + angle
        draw_line(center + Vector2.from_angle(a) * 102, center + Vector2.from_angle(a) * 110, Color("6d647b"), 2, true)
    chamber_positions.clear()
    for i in range(6):
        var a = -PI / 2 + i * TAU / 6.0 + angle
        var p = center + Vector2.from_angle(a) * 75
        chamber_positions.append(p)
        draw_circle(p, 27, Color("10111d"))
        draw_arc(p, 27, 0, TAU, 40, Color("8a8096"), 2, true)
        if i < 3:
            draw_circle(p, 21, GOLD if i == selected else Color("97734d"))
            draw_circle(p, 13, Color("4b352b"))
            draw_arc(p, 17, 0, TAU, 32, Color("f9ddb2"), 1, true)
            draw_string(ThemeDB.fallback_font, p + Vector2(-6, 7), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    draw_circle(center, 18, Color("121321"))
    draw_arc(center, 17, 0, TAU, 32, PINK, 2, true)
    draw_line(center - Vector2(10, 0), center + Vector2(10, 0), GOLD, 3, true)
    draw_line(center - Vector2(0, 10), center + Vector2(0, 10), GOLD, 3, true)
    draw_colored_polygon(PackedVector2Array([Vector2(138, 8), Vector2(162, 8), Vector2(150, 25)]), GOLD)

func _gui_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            evidence_selected.emit(posmod(selected - 1, 3))
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            evidence_selected.emit((selected + 1) % 3)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            for i in range(min(3, chamber_positions.size())):
                if event.position.distance_to(chamber_positions[i]) <= 30:
                    evidence_selected.emit(i)
                    break
        accept_event()
