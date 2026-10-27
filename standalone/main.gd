extends Node3D
# Original standalone trial game. All models are generated locally; no online assets.
const PINK = Color("ff458f")
const GOLD = Color("ffd17b")
const INK = Color("111321")
const PALE = Color("eee8e5")
const NAMES = ["REI", "AKIRA", "MORGAN", "SORA", "JUNE", "KAI", "NOVA"]
const JOBS = ["THE ARCHIVIST", "THE RUNNER", "THE DESIGNER", "THE MECHANIC", "THE MUSICIAN", "THE BOTANIST", "THE ASTRONOMER"]
const CLUES = [
    ["ACCESS LOG", "At 20:54, %s's personal key opened the archive. No other key was used that evening."],
    ["GOLD THREAD", "A gold fiber caught inside the display matches the unique gold cuff on %s's jacket."],
    ["POWER REPORT", "The building's power stayed on all night. The clock stopped because its battery was removed."]
]
var rng = RandomNumberGenerator.new()
var camera: Camera3D
var cast: Array[Node3D] = []
var podiums: Array[Vector3] = []
var culprit = 0
var ui: Control
var screen: Control
var overlay: Control
var hud: Label
var feedback: Label
var evidence_info: Label
var evidence_buttons: Array[Button] = []
var statement: Button
var speaker_name: Label
var portrait_camera: Camera3D
var portrait_root: Node3D
var phase = "menu"
var round_number = 0
var confidence = 5
var selected = 0
var score = 0
var dialogue_index = 0
var orbit_time = 0.0
var elapsed = 0.0
var statement_time = 0.0
var statement_index = 0
var target_is_weak = false
var cooldown = 0.0
var feedback_time = 0.0
var camera_tween: Tween
var statement_tween: Tween
var sequence = 0
var muted = false
var music: AudioStreamPlayer
var aim: Label
var appearance_seeds: Array[int] = []
var shot_sound: AudioStreamPlayer
var shots = 0
var hits = 0

func _ready():
    rng.randomize()
    culprit = rng.randi_range(0, 6)
    for i in range(7): appearance_seeds.append(rng.randi())
    build_world()
    var layer = CanvasLayer.new()
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(ui)
    screen = Control.new()
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(screen)
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(overlay)
    music = AudioStreamPlayer.new()
    add_child(music)
    if ResourceLoader.exists("res://ambience.wav"):
        music.stream = load("res://ambience.wav")
        music.volume_db = -18
        music.finished.connect(func(): music.play())
        music.play()
    shot_sound = AudioStreamPlayer.new()
    add_child(shot_sound)
    shot_sound.stream = load("res://shot.wav")
    shot_sound.volume_db = -12
    show_menu()
    if "--smoke-test" in OS.get_cmdline_user_args():
        run_smoke_test.call_deferred()

func material(color: Color, glow = false) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.65
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.5
    return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow = false) -> MeshInstance3D:
    var node = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.material_override = material(color, glow)
    node.position = pos
    parent.add_child(node)
    return node

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var node = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 16
    node.mesh = mesh
    node.position = pos
    node.material_override = material(color)
    parent.add_child(node)
    return node

func make_actor(index: int, parent: Node3D) -> Node3D:
    var actor = Node3D.new()
    parent.add_child(actor)
    var style_rng = RandomNumberGenerator.new()
    style_rng.seed = appearance_seeds[index]
    var jacket = Color.from_hsv(style_rng.randf(), 0.42, 0.48)
    var skin = [Color("e9bd9c"), Color("b87d55"), Color("79513f"), Color("dca180")][style_rng.randi_range(0, 3)]
    var hair = [Color("282234"), Color("d5bd88"), Color("993c59"), Color("496671")][style_rng.randi_range(0, 3)]
    box(actor, Vector3(0, 1.2, 0), Vector3(0.65, 0.8, 0.35), jacket)
    box(actor, Vector3(0, 1.35, -0.19), Vector3(0.2, 0.55, 0.03), PALE)
    box(actor, Vector3(0, 1.42, -0.22), Vector3(0.065, 0.42, 0.025), PINK)
    for side in [-1, 1]:
        box(actor, Vector3(side * 0.2, 0.43, 0), Vector3(0.27, 0.8, 0.3), Color("202132"))
        box(actor, Vector3(side * 0.2, 0.08, -0.08), Vector3(0.3, 0.17, 0.48), Color("101119"))
        box(actor, Vector3(side * 0.46, 1.2, 0), Vector3(0.22, 0.73, 0.3), jacket)
        box(actor, Vector3(side * 0.46, 0.83, 0), Vector3(0.21, 0.2, 0.26), skin)
        box(actor, Vector3(side * 0.12, 1.99, -0.23), Vector3(0.065, 0.045, 0.025), Color("202035"))
    box(actor, Vector3(0, 1.96, 0), Vector3(0.5, 0.55, 0.45), skin)
    box(actor, Vector3(0, 2.24, 0.01), Vector3(0.56, 0.2, 0.5), hair)
    box(actor, Vector3(-0.2, 2.08, 0.01), Vector3(0.13, 0.37, 0.49), hair)
    box(actor, Vector3(0, 1.83, -0.235), Vector3(0.1, 0.02, 0.015), Color("874e54"))
    if index == culprit:
        box(actor, Vector3(0.46, 0.99, -0.01), Vector3(0.24, 0.10, 0.33), GOLD, true)
    if index % 3 == 0:
        for side in [-1, 1]:
            box(actor, Vector3(side * 0.12, 2.0, -0.25), Vector3(0.19, 0.12, 0.025), Color("506a83"))
    if index % 3 == 1:
        box(actor, Vector3(0, 2.4, 0), Vector3(0.7, 0.12, 0.6), jacket)
        box(actor, Vector3(0, 2.5, 0), Vector3(0.48, 0.2, 0.44), jacket)
    if index % 3 == 2:
        box(actor, Vector3(0.26, 2.18, -0.12), Vector3(0.18, 0.12, 0.1), PINK, true)
    return actor

func build_world():
    var environment = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("0c0e1c")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("9b91bb")
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_color = Color("e8deff")
    sun.light_energy = 1.4
    add_child(sun)
    cylinder(self, Vector3(0, -0.2, 0), 16, 0.4, Color("191b2d"))
    cylinder(self, Vector3(0, 0.025, 0), 5, 0.04, Color("353044"))
    cylinder(self, Vector3(0, 0.07, 0), 1.8, 0.06, Color("4a2346"))
    for i in range(16):
        var a = i * TAU / 16.0
        var wall = Node3D.new()
        add_child(wall)
        wall.position = Vector3(sin(a) * 14, 0, cos(a) * 14)
        wall.rotation.y = a
        box(wall, Vector3(0, 4, 0), Vector3(5.6, 8, 0.5), Color("171a2a"))
        box(wall, Vector3(2.3, 4, -0.3), Vector3(0.075, 6.5, 0.1), PINK, true)
        box(wall, Vector3(0, 1, -0.3), Vector3(4.6, 0.08, 0.1), GOLD, true)
    for i in range(8):
        var a = i * TAU / 8.0
        var p = Vector3(sin(a) * 9, 0, cos(a) * 9)
        podiums.append(p)
        var podium = Node3D.new()
        add_child(podium)
        podium.position = p
        podium.rotation.y = a
        box(podium, Vector3(0, 0.08, 0), Vector3(2.6, 0.16, 2.2), PINK, true)
        box(podium, Vector3(0, 0.65, -0.65), Vector3(1.75, 1.25, 0.65), Color("252637"))
        box(podium, Vector3(0, 1.32, -0.65), Vector3(2.1, 0.15, 0.95), Color("7d647c"))
        if i > 0:
            var actor = make_actor(i - 1, podium)
            actor.position.z = 0.35
            cast.append(actor)
        var placard = Label3D.new()
        podium.add_child(placard)
        placard.position = Vector3(0, 0.8, -1.0)
        placard.rotation.y = PI
        placard.text = "YOU" if i == 0 else NAMES[i - 1]
        placard.font_size = 48
        placard.pixel_size = 0.006
        placard.modulate = GOLD
    camera = Camera3D.new()
    add_child(camera)
    camera.current = true
    camera.position = Vector3(0, 7, 5)
    camera.look_at(Vector3(0, 1, -4))

func clear_screen():
    sequence += 1
    for child in screen.get_children():
        screen.remove_child(child)
        child.queue_free()
    evidence_buttons.clear()
    statement = null
    aim = null
    if statement_tween and statement_tween.is_valid():
        statement_tween.kill()

func rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
    var r = ColorRect.new()
    r.position = pos
    r.size = size
    r.color = color
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(r)
    return r

func text(parent: Control, content: String, pos: Vector2, size: Vector2, font_size = 24, color = PALE) -> Label:
    var l = Label.new()
    l.text = content
    l.position = pos
    l.size = size
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func button(parent: Control, content: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
    var b = Button.new()
    b.text = content
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 19)
    b.add_theme_color_override("font_color", PALE)
    var style = StyleBoxFlat.new()
    style.bg_color = Color("222438")
    style.border_color = Color("776279")
    style.set_border_width_all(1)
    style.set_corner_radius_all(3)
    b.add_theme_stylebox_override("normal", style)
    var hover = style.duplicate()
    hover.bg_color = Color("503348")
    hover.border_color = PINK
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("focus", hover)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func show_menu():
    phase = "menu"
    clear_screen()
    rect(screen, Vector2.ZERO, Vector2(680, 720), Color(0.035, 0.04, 0.07, 0.93))
    rect(screen, Vector2(52, 82), Vector2(44, 4), PINK)
    text(screen, "AN ORIGINAL TRIAL GAME", Vector2(52, 104), Vector2(500, 40), 18, GOLD)
    text(screen, "NEON\nVERDICT", Vector2(48, 151), Vector2(600, 220), 88)
    text(screen, "CASE 01  /  THE MISSING SEAL", Vector2(54, 391), Vector2(550, 38), 23, PINK)
    text(screen, "Seven witnesses. Three contradictions. One stolen archive seal.\nRead the evidence, break the lies, and name the culprit.", Vector2(54, 440), Vector2(525, 95), 21)
    button(screen, "BEGIN TRIAL  →", Vector2(54, 565), Vector2(340, 60), start_game)
    button(screen, "QUIT", Vector2(413, 565), Vector2(155, 60), func(): get_tree().quit())
    text(screen, "Standalone demo  •  Original procedural characters  •  v0.1", Vector2(54, 670), Vector2(750, 30), 15, Color("a39eb3"))

func start_game():
    confidence = 5
    score = 0
    shots = 0
    hits = 0
    round_number = 0
    selected = 0
    dialogue_index = 0
    show_dialogue()

func closeup(index: int):
    if camera_tween and camera_tween.is_valid(): camera_tween.kill()
    var target = cast[index].global_position + Vector3(0, 1.6, 0)
    var inward = -Vector3(target.x, 0, target.z).normalized()
    var destination = target + inward * 4.3 + Vector3(0.5, 0.35, 0)
    var transform = camera.global_transform.looking_at(target, Vector3.UP)
    transform.origin = destination
    transform = transform.looking_at(target, Vector3.UP)
    camera_tween = create_tween()
    camera_tween.tween_property(camera, "global_transform", transform, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func add_portrait(index: int):
    var holder = SubViewportContainer.new()
    holder.position = Vector2(24, 435)
    holder.size = Vector2(235, 285)
    holder.stretch = true
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    screen.add_child(holder)
    var viewport = SubViewport.new()
    viewport.size = Vector2i(235, 285)
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    holder.add_child(viewport)
    var root = Node3D.new()
    viewport.add_child(root)
    make_actor(index, root)
    var portrait = Camera3D.new()
    root.add_child(portrait)
    portrait.position = Vector3(0, 1.75, -3.6)
    portrait.look_at(Vector3(0, 1.65, 0))
    portrait.fov = 34
    var light = DirectionalLight3D.new()
    root.add_child(light)
    light.rotation_degrees = Vector3(-20, 150, 0)
    light.light_energy = 2.0

func show_dialogue():
    phase = "dialogue"
    clear_screen()
    var other = (culprit + 2) % 7
    var speakers = [other, culprit, other]
    var lines = [
        "The archive seal vanished during the reception. We have the access log, a fiber from the cabinet, and the power report.",
        "I didn't go anywhere near the archive. You can't prove otherwise.",
        "Let's compare the testimony with the evidence. Select a truth bullet, then fire at the gold statements."
    ]
    var who: int = speakers[dialogue_index]
    closeup(who)
    text(screen, "CASE 01  /  THE MISSING SEAL", Vector2(38, 28), Vector2(1000, 45), 22, PINK)
    rect(screen, Vector2(24, 522), Vector2(1232, 174), Color(0.045, 0.05, 0.09, 0.96))
    rect(screen, Vector2(24, 522), Vector2(1232, 3), PINK)
    add_portrait(who)
    text(screen, NAMES[who] + "  /  " + JOBS[who], Vector2(285, 540), Vector2(900, 36), 24, PINK)
    text(screen, lines[dialogue_index], Vector2(285, 585), Vector2(855, 78), 22)
    button(screen, "NEXT  →", Vector2(1120, 642), Vector2(112, 38), next_dialogue)

func next_dialogue():
    if phase != "dialogue": return
    dialogue_index += 1
    if dialogue_index >= 3: debate_intro()
    else: show_dialogue()

func debate_intro():
    phase = "intro"
    clear_screen()
    rect(screen, Vector2.ZERO, Vector2(1280, 720), Color(0.03, 0.03, 0.06, 0.78))
    text(screen, "TRUTH AGAINST TESTIMONY", Vector2(298, 236), Vector2(800, 50), 24, GOLD)
    var headline = text(screen, "NONSTOP DEBATE", Vector2(-1100, 298), Vector2(1200, 120), 76, PINK)
    text(screen, "Choose evidence with 1 / 2 / 3. Aim at gold text and click to fire.\nStatements advance automatically. Five mistakes end the trial.", Vector2(248, 460), Vector2(850, 90), 22)
    var tween = create_tween()
    tween.tween_property(headline, "position:x", 225.0, 0.45).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
    var token = sequence
    await get_tree().create_timer(3.0).timeout
    if token == sequence: show_debate()

func clue_description(index: int) -> String:
    var description: String = CLUES[index][1]
    return description % NAMES[culprit] if description.contains("%s") else description

func show_debate():
    phase = "debate"
    clear_screen()
    if camera_tween and camera_tween.is_valid(): camera_tween.kill()
    text(screen, "NONSTOP DEBATE", Vector2(35, 24), Vector2(850, 40), 23, PINK)
    hud = text(screen, "", Vector2(850, 24), Vector2(410, 70), 20, GOLD)
    speaker_name = text(screen, "", Vector2(40, 108), Vector2(900, 50), 25)
    feedback = text(screen, "", Vector2(350, 435), Vector2(850, 60), 32, PINK)
    rect(screen, Vector2(24, 548), Vector2(1232, 150), Color(0.045, 0.05, 0.09, 0.94))
    text(screen, "TRUTH BULLETS  /  SELECT EVIDENCE", Vector2(42, 559), Vector2(850, 30), 16, GOLD)
    for i in range(3):
        var index = i
        evidence_buttons.append(button(screen, str(i + 1) + "  " + CLUES[i][0], Vector2(42 + i * 402, 594), Vector2(388, 42), func(): select_evidence(index)))
    evidence_info = text(screen, "", Vector2(42, 645), Vector2(1190, 50), 17, Color("c9c4d5"))
    aim = text(screen, "+", Vector2.ZERO, Vector2(35, 35), 32, GOLD)
    aim.z_index = 8
    select_evidence(selected)
    update_hud()
    statement_index = 0
    spawn_statement()

func select_evidence(index: int):
    selected = index
    if phase != "debate": return
    evidence_info.text = clue_description(index)
    for i in range(evidence_buttons.size()):
        evidence_buttons[i].modulate = GOLD if i == selected else Color.WHITE

func update_hud():
    if is_instance_valid(hud):
        hud.text = "CONFIDENCE  " + str(confidence) + "/5\nCONTRADICTIONS  " + str(round_number) + "/3"

func spawn_statement():
    if phase != "debate": return
    if is_instance_valid(statement):
        screen.remove_child(statement)
        statement.queue_free()
    if statement_tween and statement_tween.is_valid(): statement_tween.kill()
    var lies = ["I NEVER ENTERED THE ARCHIVE.", "I NEVER TOUCHED THAT CABINET.", "A POWER CUT STOPPED THE CLOCK."]
    var neutral = ["The reception began at eight.", "The seal was kept in a glass cabinet.", "We found the clock without a battery."]
    target_is_weak = statement_index % 2 == 0
    var saying: String = lies[round_number] if target_is_weak else neutral[round_number]
    var who = culprit if target_is_weak else (culprit + 2) % 7
    speaker_name.text = NAMES[who] + "  /  " + JOBS[who]
    statement = button(screen, saying, Vector2(250, 270), Vector2(820, 85), func(): pass)
    statement.add_theme_font_size_override("font_size", 30)
    statement.add_theme_color_override("font_color", GOLD if target_is_weak else PALE)
    statement.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    statement.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
    statement.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    statement.mouse_filter = Control.MOUSE_FILTER_IGNORE
    statement_tween = create_tween()
    statement_tween.tween_property(statement, "position", Vector2(70, 315), 5.0)
    statement_time = 0
    statement_index += 1

func fire(point: Vector2):
    if phase != "debate" or cooldown > 0: return
    cooldown = 0.28
    shots += 1
    if not muted: shot_sound.play()
    var start = Vector2(640, 530)
    var delta = point - start
    var tracer = rect(overlay, start, Vector2(delta.length(), 4), GOLD)
    tracer.rotation = delta.angle()
    var tween = create_tween()
    tween.tween_property(tracer, "modulate:a", 0.0, 0.2)
    tween.tween_callback(tracer.queue_free)
    var hit = is_instance_valid(statement) and statement.get_global_rect().grow(10).has_point(point)
    if hit and target_is_weak and selected == round_number:
        hits += 1
        score += 100
        round_number += 1
        phase = "break"
        feedback.text = "BREAK!  +100"
        feedback_time = 1.2
        statement.hide()
        var token = sequence
        await get_tree().create_timer(1.2).timeout
        if sequence != token: return
        if round_number == 3: show_verdict()
        else: show_debate()
    else:
        confidence -= 1
        feedback.text = "WRONG EVIDENCE" if hit and target_is_weak else ("THAT ISN'T A CONTRADICTION" if hit else "MISS — AIM AT THE WORDS")
        feedback_time = 1.6
        update_hud()
        if confidence <= 0: show_result(false, "Your argument fell apart. Read each truth bullet before firing.")

func show_verdict():
    phase = "verdict"
    clear_screen()
    rect(screen, Vector2.ZERO, Vector2(1280, 720), Color(0.04, 0.04, 0.08, 0.87))
    text(screen, "FINAL VERDICT", Vector2(70, 72), Vector2(1000, 85), 56, PINK)
    text(screen, "Whose key opened the archive? Whose gold cuff matches the fiber?", Vector2(74, 175), Vector2(1100, 70), 25)
    for i in range(7):
        var suspect = i
        var col = i % 4
        var row = i / 4
        button(screen, NAMES[i] + "\n" + JOBS[i], Vector2(74 + col * 288, 290 + floor(row) * 124), Vector2(265, 102), func(): vote(suspect))

func vote(index: int):
    if phase != "verdict": return
    var won = index == culprit
    if won: score += confidence * 50
    show_result(won, NAMES[culprit] + " took the seal, leaving a key record and a gold fiber. The power-cut story was a cover.")

func show_result(won: bool, explanation: String):
    phase = "result"
    clear_screen()
    rect(screen, Vector2.ZERO, Vector2(1280, 720), Color(0.035, 0.04, 0.07, 0.91))
    text(screen, "CASE CLOSED" if won else "TRIAL FAILED", Vector2(95, 125), Vector2(1100, 100), 70, GOLD if won else PINK)
    text(screen, explanation, Vector2(100, 266), Vector2(1040, 110), 27)
    text(screen, "SCORE  %03d     •     CONTRADICTIONS  %d/3     •     ACCURACY  %d%%" % [score, round_number, int(100.0 * hits / max(shots, 1))], Vector2(100, 400), Vector2(1050, 55), 23, GOLD)
    button(screen, "RETRY CASE", Vector2(100, 520), Vector2(300, 65), start_game)
    button(screen, "MAIN MENU", Vector2(425, 520), Vector2(300, 65), show_menu)
    button(screen, "QUIT", Vector2(750, 520), Vector2(210, 65), func(): get_tree().quit())

func _process(dt: float):
    elapsed += dt
    cooldown = max(0, cooldown - dt)
    feedback_time = max(0, feedback_time - dt)
    if phase in ["menu", "intro", "debate", "break", "verdict", "result"]:
        orbit_time += dt * (0.16 if phase in ["debate", "break"] else 0.06)
        var radius = 5.5 if phase in ["debate", "break"] else 6.5
        camera.position = Vector3(sin(orbit_time) * radius, 3.1 if phase == "debate" else 4.2, cos(orbit_time) * radius)
        camera.look_at(Vector3(-sin(orbit_time) * 6, 1.25, -cos(orbit_time) * 6))
    if phase == "debate":
        statement_time += dt
        if statement_time >= 5.0: spawn_statement()
        if is_instance_valid(aim): aim.position = get_viewport().get_mouse_position() - Vector2(12, 12)
        if feedback_time <= 0 and is_instance_valid(feedback): feedback.text = ""
    for i in range(cast.size()):
        cast[i].rotation.z = sin(elapsed * 1.7 + i) * 0.012

func _unhandled_input(event: InputEvent):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            show_menu()
        elif event.keycode == KEY_M:
            muted = not muted
            music.volume_db = -80 if muted else -18
        elif event.keycode == KEY_F11:
            var full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
        elif phase == "dialogue" and event.keycode in [KEY_SPACE, KEY_ENTER]:
            next_dialogue()
        elif phase == "debate" and event.keycode in [KEY_1, KEY_2, KEY_3]:
            select_evidence(event.keycode - KEY_1)
    if phase == "debate":
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if event.position.y < 540: fire(event.position)
        elif event is InputEventScreenTouch and event.pressed:
            if event.position.y < 540: fire(event.position)

func run_smoke_test():
    start_game()
    assert(phase == "dialogue")
    dialogue_index = 2
    next_dialogue()
    await get_tree().create_timer(3.2).timeout
    assert(phase == "debate")
    assert(screen.find_children("*", "SubViewportContainer", false, false).is_empty())
    for stage in range(3):
        select_evidence(stage)
        assert(round_number == stage)
        assert(target_is_weak)
        fire(statement.get_global_rect().get_center())
        await get_tree().create_timer(1.4).timeout
    assert(phase == "verdict")
    vote(culprit)
    assert(phase == "result")
    assert(score == 550)
    start_game()
    round_number = 0
    show_debate()
    await get_tree().create_timer(5.2).timeout
    assert(not target_is_weak)
    await get_tree().create_timer(5.2).timeout
    assert(target_is_weak)
    selected = 2
    fire(statement.get_global_rect().get_center())
    assert(confidence == 4)
    cooldown = 0
    fire(Vector2(20, 200))
    assert(confidence == 3)
    vote(culprit)
    assert(phase == "debate")
    show_menu()
    print("SMOKE PASS: dialogue, intro, auto debate, correct evidence, wrong evidence, misses, verdict, score, restart")
    get_tree().quit()
