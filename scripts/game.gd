extends Node2D

# CHISPA: prototipo jugable en 1280x720, sin plugins externos.
const W: float = 1280.0
const H: float = 720.0
const PLAYER_SIZE := Vector2(62, 82)
const SPEED: float = 315.0
const JUMP: float = -745.0
const GRAVITY: float = 1850.0
const PLATFORM_HEIGHT: float = 24.0

var hero: Texture2D = preload("res://assets/hero.png")
var grass: Texture2D = preload("res://assets/grass.png")
var gull: Texture2D = preload("res://assets/gull.png")
var bins: Texture2D = preload("res://assets/bins.png")
var font: Font = ThemeDB.fallback_font

var level_index: int = 0
var player_pos := Vector2(92, 450)
var velocity := Vector2.ZERO
var on_floor: bool = false
var jumps_remaining: int = 2
var light_on: bool = false
var play_state: int = 0 # 0 menu, 1 jugando, 2 completado, 3 victoria
var moving_left := false
var moving_right := false
var touching_left := false
var touching_right := false
var held_fingers: Dictionary = {}
var pulse_time: float = 0.0
var elapsed: float = 0.0
var deaths: int = 0
var unlocks: int = 1

# Plataforma: [x, y, ancho, modo]. modo=0 fija, 1 solo luz, 2 solo sombra.
var layouts: Array = [
    [
        [0, 604, 350, 0], [410, 548, 200, 1], [665, 604, 220, 0],
        [915, 528, 178, 1], [1110, 604, 170, 0]
    ],
    [
        [0, 604, 265, 0], [305, 520, 195, 2], [530, 455, 170, 1],
        [730, 540, 185, 2], [965, 604, 315, 0]
    ],
    [
        [0, 604, 270, 0], [315, 530, 170, 1], [505, 455, 145, 2],
        [670, 390, 148, 1], [840, 500, 165, 2], [1045, 604, 235, 0]
    ]
]
var hazards: Array = [
    [[746, 560, 48, 40, "bin"]],
    [[1080, 560, 48, 40, "bin"]],
    [[570, 387, 70, 48, "gull"]]
]
var goals: Array = [Vector2(1205, 540), Vector2(1202, 540), Vector2(1200, 540)]

func _ready() -> void:
    reset_level()
    queue_redraw()

func reset_level() -> void:
    player_pos = Vector2(92, 470)
    velocity = Vector2.ZERO
    jumps_remaining = 2
    on_floor = false
    light_on = false
    pulse_time = 0.0
    moving_left = false
    moving_right = false
    touching_left = false
    touching_right = false
    held_fingers.clear()
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    pulse_time += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    if play_state != 1:
        return
    var direction: float = 0.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or moving_left or touching_left:
        direction -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or moving_right or touching_right:
        direction += 1.0
    velocity.x = direction * SPEED
    var old_pos: Vector2 = player_pos
    velocity.y += GRAVITY * delta
    player_pos += velocity * delta
    player_pos.x = clampf(player_pos.x, 0.0, W - PLAYER_SIZE.x)
    on_floor = false
    var old_bottom: float = old_pos.y + PLAYER_SIZE.y
    var new_bottom: float = player_pos.y + PLAYER_SIZE.y
    for p in layouts[level_index]:
        if not platform_active(p):
            continue
        var px: float = float(p[0])
        var py: float = float(p[1])
        var pw: float = float(p[2])
        if velocity.y >= 0.0 and old_bottom <= py + 12.0 and new_bottom >= py and player_pos.x + PLAYER_SIZE.x > px + 8.0 and player_pos.x < px + pw - 8.0:
            player_pos.y = py - PLAYER_SIZE.y
            velocity.y = 0.0
            on_floor = true
            jumps_remaining = 2
            break
    if player_pos.y > H + 100.0:
        die()
        return
    for hazard in hazards[level_index]:
        var h_rect := Rect2(float(hazard[0]), float(hazard[1]), float(hazard[2]), float(hazard[3]))
        if hazard[4] == "gull":
            h_rect.position.x += sin(elapsed * 1.7) * 34.0
        if Rect2(player_pos + Vector2(12, 12), PLAYER_SIZE - Vector2(24, 16)).intersects(h_rect):
            die()
            return
    var goal: Vector2 = goals[level_index]
    if Rect2(player_pos, PLAYER_SIZE).intersects(Rect2(goal - Vector2(18, 18), Vector2(55, 95))):
        level_index += 1
        if level_index >= layouts.size():
            play_state = 3
            level_index = layouts.size() - 1
        else:
            unlocks = maxi(unlocks, level_index + 1)
            play_state = 2
        reset_level()

func platform_active(p: Array) -> bool:
    return int(p[3]) == 0 or (int(p[3]) == 1 and light_on) or (int(p[3]) == 2 and not light_on)

func jump() -> void:
    if play_state != 1 or jumps_remaining <= 0:
        return
    velocity.y = JUMP if on_floor else JUMP * 0.84
    jumps_remaining -= 1
    on_floor = false

func toggle_light() -> void:
    if play_state == 1:
        light_on = not light_on
        pulse_time = 0.0

func die() -> void:
    deaths += 1
    reset_level()

func action() -> void:
    if play_state == 0 or play_state == 2:
        play_state = 1
        reset_level()
    elif play_state == 3:
        level_index = 0
        deaths = 0
        play_state = 1
        reset_level()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.pressed or event.echo:
        return
    if event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP:
        if play_state == 1:
            jump()
        else:
            action()
    elif event.keycode == KEY_E or event.keycode == KEY_SHIFT or event.keycode == KEY_L:
        toggle_light()
    elif event.keycode == KEY_ENTER:
        action()
    elif event.keycode == KEY_R:
        reset_level()

func touch_to_action(pos: Vector2, pressed: bool, finger: int) -> void:
    if play_state != 1:
        if pressed:
            action()
        return
    if pressed:
        held_fingers[finger] = pos
    else:
        held_fingers.erase(finger)
    if pressed and pos.x > 1120 and pos.y > 540:
        jump()
    elif pressed and pos.x > 935 and pos.y > 540:
        toggle_light()
    elif pressed and pos.x > 1130 and pos.y < 120:
        reset_level()
    update_touch_motion()

func update_touch_motion() -> void:
    touching_left = false
    touching_right = false
    for pos in held_fingers.values():
        if pos.y > 520 and pos.x < 170:
            touching_left = true
        elif pos.y > 520 and pos.x < 360:
            touching_right = true

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        touch_to_action(event.position, event.pressed, event.index)
    elif event is InputEventScreenDrag:
        if held_fingers.has(event.index):
            held_fingers[event.index] = event.position
            update_touch_motion()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        touch_to_action(event.position, event.pressed, 99)

func text_at(s: String, pos: Vector2, size: int, color: Color = Color.WHITE) -> void:
    draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
    var bg: Color = Color("11142f") if not light_on else Color("4f91b3")
    draw_rect(Rect2(0, 0, W, H), bg)
    for i in range(12):
        var x: float = 52.0 + i * 109.0
        var y: float = 125.0 + sin(float(i) * 4.2) * 78.0
        draw_circle(Vector2(x, y), 2.5, Color(0.55, 0.78, 1.0, 0.24) if not light_on else Color(1, 1, 1, 0.3))
    draw_rect(Rect2(0, 620, W, 100), Color("090e20") if not light_on else Color("346d63"))
    # La luz ilumina la escena, y las plataformas cambian de fase.
    if light_on:
        draw_circle(player_pos + PLAYER_SIZE * 0.5, 235.0, Color(1.0, 0.84, 0.35, 0.07))
    for p in layouts[level_index]:
        var active: bool = platform_active(p)
        var rect := Rect2(float(p[0]), float(p[1]), float(p[2]), PLATFORM_HEIGHT)
        if active:
            var c: Color = Color("59e1ed") if int(p[3]) == 1 else (Color("b19afc") if int(p[3]) == 2 else Color("42755f"))
            draw_rect(rect, c)
            draw_rect(Rect2(rect.position.x, rect.position.y + 16, rect.size.x, 11), c.darkened(0.4))
            for j in range(int(rect.size.x / 70.0)):
                draw_texture_rect(grass, Rect2(rect.position.x + j * 70.0, rect.position.y - 15, 70, 28), false, Color(0.7, 1, 0.8, 0.85))
        else:
            draw_rect(rect, Color(0.6, 0.78, 1, 0.12), false, 2.0)
    for hazard in hazards[level_index]:
        var rect := Rect2(float(hazard[0]), float(hazard[1]), float(hazard[2]), float(hazard[3]))
        if hazard[4] == "gull":
            rect.position.x += sin(elapsed * 1.7) * 34.0
            draw_texture_rect(gull, rect, false)
        else:
            draw_texture_rect(bins, rect, false)
    var goal: Vector2 = goals[level_index]
    draw_rect(Rect2(goal, Vector2(40, 66)), Color("ffdd77", 0.14))
    draw_rect(Rect2(goal, Vector2(40, 66)), Color("ffdc62"), false, 3.0)
    draw_circle(goal + Vector2(20, 26), 10.0, Color("fff5bd"))
    draw_texture_rect(hero, Rect2(player_pos - Vector2(5, 15), PLAYER_SIZE + Vector2(10, 20)), false)
    draw_rect(Rect2(0, 0, W, 81), Color("07111e", 0.78))
    text_at("CHISPA", Vector2(30, 48), 35, Color("ffe88d"))
    text_at("NIVEL %d / %d" % [level_index + 1, layouts.size()], Vector2(275, 47), 25)
    text_at("LUZ ENCENDIDA" if light_on else "OSCURIDAD", Vector2(493, 47), 24, Color("ffe579") if light_on else Color("b3b7ed"))
    text_at("CAIDAS: %d" % deaths, Vector2(925, 44), 20)
    text_at("REINICIAR", Vector2(1120, 44), 18)
    draw_button(Rect2(22, 555, 126, 130), "<", Color("425579"))
    draw_button(Rect2(165, 555, 126, 130), ">", Color("425579"))
    draw_button(Rect2(951, 555, 145, 130), "LUZ", Color("d9a93e"))
    draw_button(Rect2(1122, 555, 140, 130), "SALTO", Color("2e9cc7"))
    if play_state != 1:
        draw_rect(Rect2(155, 154, 970, 362), Color("071121", 0.93))
        draw_rect(Rect2(155, 154, 970, 362), Color("6bdce5"), false, 3.0)
        if play_state == 0:
            text_at("CHISPA: EL MUNDO SE APAGA", Vector2(226, 242), 39, Color("ffe582"))
            text_at("La luz revela caminos. La sombra abre otros.", Vector2(270, 305), 25)
            text_at("Mover: flechas / A D   |   Saltar: espacio   |   Luz: E", Vector2(220, 372), 23)
            text_at("TOCA PARA COMENZAR", Vector2(425, 454), 31, Color("7ce6f3"))
        elif play_state == 2:
            text_at("NIVEL SUPERADO", Vector2(440, 258), 40, Color("ffe582"))
            text_at("Toca para entrar al siguiente nivel", Vector2(330, 375), 28)
        else:
            text_at("LA LUZ HA VUELTO", Vector2(392, 250), 42, Color("ffe582"))
            text_at("Completaste los tres niveles. Toca para reiniciar.", Vector2(255, 360), 25)

func draw_button(rect: Rect2, label: String, color: Color) -> void:
    draw_rect(rect, Color(color, 0.62))
    draw_rect(rect, color.lightened(0.3), false, 2.0)
    text_at(label, rect.position + Vector2(24, 80), 26)
