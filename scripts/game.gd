extends Node2D
# CHISPA ULTRA - horizontal mobile platformer with auto light/dark phases,
# articulated character, cinematic intros, explosions, particles and rich HUD.
const W := 1280.0
const H := 720.0
const PLAY_BOTTOM := 554.0
const WORLD_RAISE := 110.0
const PW := 44.0
const PH := 86.0
const RUN := 370.0
const ACCEL := 2400.0
const FRICTION := 2900.0
const GRAVITY := 2080.0
const JUMP := -760.0
const PHASE_SECONDS := 7.0
const WARN_SECONDS := 1.5
const INTRO_SECONDS := 2.3
const GOAL_CINE := 1.5
const CYAN := Color("55edf7")
const VIOLET := Color("af83ff")
const GOLD := Color("ffdf88")
const INK := Color("0a1029")
const WHITE := Color("effaff")
const RED := Color("ff678d")
const LIME := Color("8df1ae")

var face: Texture2D = preload("res://assets/face.png")
var grass: Texture2D = preload("res://assets/grass.png")
var gull: Texture2D = preload("res://assets/gull.png")
var bins: Texture2D = preload("res://assets/bins.png")
var font: Font = ThemeDB.fallback_font
var levels := [
 {"name":"PRIMER DESTELLO", "subtitle":"Aprende el ritmo de la luz", "platforms":[[0,600,306,0],[340,546,205,1],[595,600,224,0],[858,536,194,2],[1080,600,200,0]], "hazards":[[716,556,"bin"]], "goal":Vector2(1200,540), "spawn":Vector2(90,514)},
 {"name":"ENTRE DOS MUNDOS", "subtitle":"Cada fase dibuja un camino", "platforms":[[0,600,258,0],[300,534,178,2],[520,472,181,1],[746,534,175,2],[965,600,315,0]], "hazards":[[1071,556,"bin"],[610,430,"gull"]], "goal":Vector2(1200,540),"spawn":Vector2(90,514)},
 {"name":"PULSO FINAL", "subtitle":"Guardian del pulso: evita sus descargas", "platforms":[[0,600,290,0],[315,545,205,1],[555,600,210,0],[800,545,205,2],[1040,600,240,0]], "hazards":[[690,548,"bin"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514),"boss":true},
 {"name":"JARDINES DE NEON", "subtitle":"El mundo respira contigo", "platforms":[[0,600,300,0],[335,540,190,2],[555,477,190,1],[780,545,200,2],[1020,600,260,0]], "hazards":[[870,498,"gull"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514)},
 {"name":"ECO DE SOMBRAS", "subtitle":"Confia en el pulso", "platforms":[[0,600,305,0],[325,520,195,1],[560,590,185,0],[785,490,190,2],[1010,600,270,0]], "hazards":[[625,548,"bin"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514)},
 {"name":"CIUDAD INTERMITENTE", "subtitle":"Las luces nunca esperan", "platforms":[[0,600,278,0],[310,530,200,2],[545,470,205,1],[785,530,190,2],[1020,600,260,0]], "hazards":[[635,425,"gull"],[875,483,"bin"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514)},
 {"name":"CORAZON DEL APAGON", "subtitle":"Derrota al guardian de las dos fases", "platforms":[[0,600,325,0],[350,535,195,1],[565,600,195,0],[790,525,205,2],[1020,600,260,0]], "hazards":[[685,548,"bin"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514),"boss":true}
]

var level := 0
var state := 0 # 0 menu, 1 playing, 2 level complete prompt, 3 all complete
var p := Vector2(90,514)
var v := Vector2.ZERO
var facing := 1.0
var grounded := false
var coyote := 0.0
var buffer := 0.0
var air_jump := true
var phase_light := true
var phase_timer := 0.0
var phase_grace := 0.0
var t := 0.0
var run_cycle := 0.0
var land_bounce := 0.0
var deaths := 0
var elapsed := 0.0
var shake := 0.0
var flash := 0.0
var particles: Array = []
var trails: Array = []
var touches: Dictionary = {}
var move_axis := 0.0
var transition := 0.0
var best_level := 1
var starfield: Array = []
var sfx: Dictionary = {}
var muted := false
var warning_played := false
var camera_base := Vector2.ZERO
var camera_shake := Vector2.ZERO
var intro_timer := 0.0
var goal_cinematic := 0.0
var goal_burst := 0.0
var scene_glow := 0.0
var ambience: Array = []
var screen_message := ""
var screen_message_t := 0.0
var boss_time := 0.0
var boss_energy := 0.0
var boss_shots: Array = []
var boss_stunned := 0.0
var boss_guard := false
var charge := 0.0
var cinematic_played := false
var music: AudioStreamPlayer
var theme_bright: AudioStream = preload("res://audio/music_light.wav")
var theme_shadow: AudioStream = preload("res://audio/music_dark.wav")
var soundtrack_phase := true
var fx_quality := true

const SFX = {
 "jump": preload("res://audio/jump.wav"),
 "double": preload("res://audio/double_jump.wav"),
 "land": preload("res://audio/land.wav"),
 "light": preload("res://audio/phase_light.wav"),
 "dark": preload("res://audio/phase_dark.wav"),
 "warning": preload("res://audio/danger.wav"),
 "lose": preload("res://audio/lose.wav"),
 "win": preload("res://audio/win.wav"),
 "start": preload("res://audio/start.wav")
}

func play_sfx(name: String) -> void:
 if muted or not sfx.has(name):
  return
 var player: AudioStreamPlayer = sfx[name]
 player.stop()
 player.play()

func _ready() -> void:
 # Keep the entire playable world above the dedicated touch-control bar.
 for stage in levels:
  for platform in stage["platforms"]:
   platform[1] = int(platform[1]) - int(WORLD_RAISE)
  for hazard in stage["hazards"]:
   hazard[1] = int(hazard[1]) - int(WORLD_RAISE)
  stage["spawn"] = stage["spawn"] - Vector2(0, WORLD_RAISE)
  stage["goal"] = stage["goal"] - Vector2(0, WORLD_RAISE)
 for name in SFX:
  var player := AudioStreamPlayer.new()
  player.stream = SFX[name]
  player.volume_db = -8.0 if name == "land" else (-5.0 if name in ["warning","start"] else -3.0)
  add_child(player)
  sfx[name] = player
 music = AudioStreamPlayer.new()
 music.stream = theme_bright
 music.volume_db = -15.0
 add_child(music)
 music.play()
 var rng := RandomNumberGenerator.new()
 rng.seed = 99477
 for i in range(64):
  starfield.append({"p":Vector2(rng.randf_range(0,W),rng.randf_range(45,520)),"s":rng.randf_range(1.2,3.6),"a":rng.randf_range(0.15,0.9)})
 for i in range(11):
  ambience.append({"x":rng.randf_range(0,W),"y":rng.randf_range(120,510),"r":rng.randf_range(22,66),"speed":rng.randf_range(8,20),"phase":rng.randf_range(0,TAU)})
 best_level = int(ProjectSettings.get_setting("application/config/chispa_unlocked",1))
 reset_level()

func reset_level() -> void:
 p = levels[level]["spawn"]
 v = Vector2.ZERO
 grounded = false
 coyote = 0.0
 buffer = 0.0
 air_jump = true
 phase_timer = 0.0
 warning_played = false
 phase_light = true
 phase_grace = 0.0
 run_cycle = 0.0
 particles.clear()
 trails.clear()
 touches.clear()
 move_axis = 0.0
 shake = 0.0
 flash = 0.0
 goal_cinematic = 0.0
 goal_burst = 0.0
 intro_timer = 3.3 if level == 0 and not cinematic_played else INTRO_SECONDS
 cinematic_played = true
 scene_glow = 0.0
 boss_time = 0.0
 boss_energy = 0.0
 boss_stunned = 0.0
 boss_shots.clear()
 boss_guard = bool(levels[level].get("boss", false))
 set_message(levels[level]["name"] + "\n" + levels[level]["subtitle"], 1.65)

func start() -> void:
 if state == 3:
  cinematic_played = false
  level = 0
  deaths = 0
 state = 1
 reset_level()
 play_sfx("start")

func set_message(txt: String, dur: float) -> void:
 screen_message = txt
 screen_message_t = dur

func platform_enabled(item: Array) -> bool:
 return int(item[3]) == 0 or (int(item[3]) == 1) == phase_light

func spawn_spark(location: Vector2, vel: Vector2, life: float, color: Color, kind: String = "spark") -> void:
 particles.append({"kind":kind,"p":location,"v":vel,"life":life,"max":life,"color":color,"r":randf_range(2.0,5.0),"grow":randf_range(20.0,90.0)})

func make_sparks(location: Vector2, amount: int, color: Color) -> void:
 for i in range(amount):
  var a := randf_range(-PI, PI)
  spawn_spark(location, Vector2(cos(a), sin(a))*randf_range(40,260), randf_range(0.18,0.65), color, "spark")

func make_ring(location: Vector2, color: Color, radius: float = 10.0) -> void:
 particles.append({"kind":"ring","p":location,"v":Vector2.ZERO,"life":0.55,"max":0.55,"color":color,"r":radius,"grow":140.0})

func make_explosion(location: Vector2, color: Color, power: float = 1.0) -> void:
 for i in range(int(16 + power * 20.0)):
  var a := randf_range(0.0, TAU)
  var speed := randf_range(80.0, 360.0) * power
  spawn_spark(location, Vector2(cos(a), sin(a))*speed, randf_range(0.25,0.85), color, "spark")
 for j in range(int(6 + power * 4.0)):
  var off := Vector2(randf_range(-18,18), randf_range(-18,18))
  particles.append({"kind":"burst","p":location+off,"v":Vector2(randf_range(-30,30),randf_range(-70,20)),"life":0.55,"max":0.55,"color":color.lightened(0.2),"r":randf_range(7,15),"grow":randf_range(18,44)})
 make_ring(location, color, 20.0 + 12.0*power)
 shake = maxf(shake, 3.0 + 6.0 * power)
 flash = maxf(flash, 0.16 * power)

func emit_trail(color: Color) -> void:
 trails.append({"p":p+Vector2(PW*0.5,PH*0.55),"life":0.22,"max":0.22,"color":color})
 if trails.size() > 40:
  trails.pop_front()

func request_jump() -> void:
 if state != 1:
  start()
  return
 if intro_timer > 0.1 or goal_cinematic > 0.1:
  return
 buffer = 0.15

func _unhandled_key_input(e: InputEvent) -> void:
 if not e.pressed or e.echo:
  return
 if e.keycode in [KEY_SPACE,KEY_W,KEY_UP]:
  request_jump()
 elif e.keycode == KEY_ENTER:
  if state != 1:
   start()
 elif e.keycode == KEY_R:
  reset_level()
 elif e.keycode == KEY_M:
  muted = not muted

func _input(e: InputEvent) -> void:
 if e is InputEventScreenTouch:
  if e.pressed:
   if e.position.x > 1110 and e.position.y < 83:
    muted = not muted
    queue_redraw()
    return
   touches[e.index] = e.position
   if state != 1:
    start()
   elif e.position.x > 960 and e.position.y >= PLAY_BOTTOM:
    request_jump()
  else:
   touches.erase(e.index)
 elif e is InputEventScreenDrag:
  touches[e.index] = e.position
 elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
  if e.position.x > 1110 and e.position.y < 83:
   muted = not muted
   queue_redraw()
   return
  if state != 1:
   start()
  elif e.position.x > 960 and e.position.y >= PLAY_BOTTOM:
   request_jump()

func _physics_process(dt: float) -> void:
 dt = minf(dt,0.035)
 t += dt
 flash = maxf(0,flash-dt*1.8)
 shake = maxf(0,shake-dt*22)
 land_bounce = move_toward(land_bounce,0,dt*6)
 scene_glow = move_toward(scene_glow,0,dt*0.9)
 screen_message_t = maxf(0, screen_message_t - dt)
 if screen_message_t <= 0:
  screen_message = ""

 var light_col := CYAN if phase_light else VIOLET
 # particles
 for i in range(particles.size() - 1, -1, -1):
  var q: Dictionary = particles[i]
  q["p"] += q["v"]*dt
  if q["kind"] == "spark":
   q["v"] += Vector2(0,560)*dt
  elif q["kind"] == "burst":
   q["v"] = q["v"].lerp(Vector2.ZERO, dt*4.0)
  q["life"] -= dt
  if q["life"] <= 0:
   particles.remove_at(i)
  else:
   particles[i] = q
 for i in range(trails.size() - 1, -1, -1):
  var tr: Dictionary = trails[i]
  tr["life"] -= dt
  if tr["life"] <= 0:
   trails.remove_at(i)
  else:
   trails[i] = tr
 for a in ambience:
  a["x"] = wrapf(a["x"] + a["speed"] * dt * (0.35 if phase_light else 0.18), -120.0, W+120.0)

 if music:
  music.volume_db = move_toward(music.volume_db, -80.0 if muted else (-11.0 if state == 1 else -19.0), dt*28.0)
 if state != 1:
  camera_base = camera_base.lerp(Vector2.ZERO, dt*4)
  queue_redraw()
  return

 elapsed += dt
 if intro_timer > 0:
  intro_timer = maxf(0, intro_timer - dt)
  move_axis = 0
  camera_base = Vector2(lerpf(120, -90, 1.0 - intro_timer / INTRO_SECONDS), lerpf(-14, 0, 1.0 - intro_timer / INTRO_SECONDS))
  queue_redraw()
  return

 phase_timer += dt
 if PHASE_SECONDS-phase_timer < WARN_SECONDS and not warning_played:
  warning_played = true
  play_sfx("warning")
  set_message("INVERSION INMINENTE", 0.9)
  make_ring(Vector2(W*0.5, 294), GOLD, 30.0)
 if phase_timer >= PHASE_SECONDS:
  warning_played = false
  phase_timer -= PHASE_SECONDS
  phase_light = not phase_light
  if music and soundtrack_phase != phase_light:
   soundtrack_phase = phase_light
   music.stream = theme_bright if phase_light else theme_shadow
   music.play()
  play_sfx("light" if phase_light else "dark")
  phase_grace = 0.20
  flash = 0.46
  scene_glow = 0.7
  shake = 4.0
  var c := CYAN if phase_light else VIOLET
  make_explosion(Vector2(W/2,310), c, 1.2)
  set_message("MODO LUZ" if phase_light else "MODO SOMBRA", 0.85)
 phase_grace = maxf(0,phase_grace-dt)

 move_axis = 0.0
 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_axis -= 1
 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_axis += 1
 for pt in touches.values():
  if pt.y >= PLAY_BOTTOM:
   if pt.x < 170: move_axis -= 1
   elif pt.x < 350: move_axis += 1
 move_axis = clampf(move_axis,-1,1)
 if absf(move_axis)>0.1:
  v.x = move_toward(v.x,move_axis*RUN,ACCEL*dt)
  facing = signf(move_axis)
 else:
  v.x = move_toward(v.x,0,FRICTION*dt)
 if grounded:
  coyote = 0.115
 else:
  coyote = maxf(0,coyote-dt)
 buffer = maxf(0,buffer-dt)
 if buffer > 0 and (coyote > 0 or air_jump):
  var first := coyote>0
  v.y = JUMP if first else JUMP*0.82
  if not first:
   air_jump = false
  play_sfx("jump" if first else "double")
  coyote = 0
  grounded = false
  buffer = 0
  land_bounce = -0.18
  make_explosion(p+Vector2(PW/2,PH), CYAN if first else VIOLET, 0.45 if first else 0.7)
 if grounded and absf(v.x) > 150 and int(t*60) % 5 == 0:
  emit_trail(CYAN if phase_light else VIOLET)

 v.y = minf(v.y + GRAVITY*dt,1180)
 if v.y < 0 and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)):
  v.y -= 300*dt
 var old_bottom := p.y+PH
 p += v*dt
 p.x = clampf(p.x,0,W-PW)
 var was_grounded := grounded
 grounded = false
 for platform in levels[level]["platforms"]:
  if not platform_enabled(platform) and phase_grace <= 0:
   continue
  var x := float(platform[0])
  var y := float(platform[1])
  var width := float(platform[2])
  if v.y >= 0 and old_bottom <= y+10 and p.y+PH >= y and p.x+PW-8 > x and p.x+8 < x+width:
   p.y = y-PH
   v.y = 0
   grounded = true
   air_jump = true
   if not was_grounded:
    land_bounce = 0.25
    play_sfx("land")
    shake = maxf(shake, 2.0)
    make_explosion(p+Vector2(PW/2,PH), GOLD, 0.32)
   break
 if not grounded and was_grounded:
  coyote = 0.11
 if grounded and absf(v.x)>30:
  run_cycle += absf(v.x)*dt*0.04
 elif not grounded:
  run_cycle += dt*3.1
 if boss_guard and goal_cinematic <= 0.0:
  update_boss(dt)
 if p.y > PLAY_BOTTOM+80:
  die()
  return

 for hazard in levels[level]["hazards"]:
  var hx := float(hazard[0])
  var hy := float(hazard[1])
  var r := Rect2(hx,hy,44,44)
  if hazard[2] == "gull":
   var gx := hx+sin(t*2.0+hx)*50.0
   var gy := hy+sin(t*3.0+hx*0.1)*18.0
   r = Rect2(gx,gy,73,45)
  if Rect2(p+Vector2(9,13),Vector2(PW-18,PH-20)).intersects(r):
   die()
   return
 var goal: Vector2 = levels[level]["goal"]
 if goal_cinematic <= 0.0 and (not boss_guard or boss_energy >= 3.0) and Rect2(p,Vector2(PW,PH)).intersects(Rect2(goal,Vector2(50,68))):
  goal_cinematic = GOAL_CINE
  goal_burst = 1.0
  v = Vector2.ZERO
  make_explosion(goal+Vector2(24,28), GOLD, 1.6)
  play_sfx("win")
  set_message("DESTELLO COMPLETO", 1.1)

 if goal_cinematic > 0.0:
  goal_cinematic = maxf(0, goal_cinematic - dt)
  goal_burst = maxf(0, goal_burst - dt * 0.55)
  camera_base = camera_base.lerp((goal + Vector2(-W*0.5+50,-240)) * 0.15, dt*6.0)
  if goal_cinematic == 0.0:
   level += 1
   if level >= levels.size():
    level = levels.size()-1
    state = 3
   else:
    state = 2
    best_level = maxi(best_level,level+1)
   reset_level()
 else:
  camera_base = camera_base.lerp(Vector2(clampf((p.x-W*0.5)*0.08,-55,55), clampf((p.y-280)*0.06,-26,26)), dt*4.5)

 if shake > 0:
  camera_shake = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
 else:
  camera_shake = camera_shake.lerp(Vector2.ZERO, dt*7.0)
 queue_redraw()

func update_boss(dt: float) -> void:
 boss_time += dt
 boss_stunned = maxf(0.0, boss_stunned - dt)
 # Each successful pulse dodge charges the boss's energy core.
 if boss_time > 2.5 and boss_energy < 3.0 and boss_stunned <= 0.0:
  boss_time = 0.0
  var shot_y := 370.0 if int(t) % 2 == 0 else 435.0
  boss_shots.append({"p":Vector2(1100,shot_y),"v":Vector2(-290.0 - float(level)*16.0,0),"life":5.0,"counted":false})
  play_sfx("warning")
 for i in range(boss_shots.size()-1,-1,-1):
  var sh: Dictionary = boss_shots[i]
  sh["p"] += sh["v"] * dt
  sh["life"] -= dt
  if Rect2(p+Vector2(10,14),Vector2(PW-20,PH-26)).intersects(Rect2(sh["p"]-Vector2(16,16),Vector2(32,32))):
   die()
   return
  if not sh["counted"] and sh["p"].x < p.x - 32.0:
   sh["counted"] = true
   boss_energy += 1.0
   boss_stunned = 0.55
   make_explosion(Vector2(1110,348), GOLD, 1.25)
   play_sfx("win")
   set_message("ENERGIA %d/3 - ESQUIVA LOS PULSOS" % int(boss_energy), 1.0)
  if sh["life"] <= 0 or sh["p"].x < -40.0:
   boss_shots.remove_at(i)
  else:
   boss_shots[i] = sh

func die() -> void:
 play_sfx("lose")
 deaths += 1
 make_explosion(p+Vector2(PW/2, PH*0.55), RED, 1.3)
 for i in range(6):
  make_ring(p+Vector2(randf_range(10,30), randf_range(15,55)), RED, randf_range(10,22))
 shake = 12
 flash = 0.58
 set_message("LA OSCURIDAD TE DEVORO", 1.0)
 reset_level()

func label_text(s: String, where: Vector2, size: int, color: Color=WHITE) -> void:
 draw_string(font,where,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func with_alpha(c: Color, a: float) -> Color:
 var o := c
 o.a = a
 return o

func glow_label(s: String, where: Vector2, size: int, color: Color = WHITE) -> void:
 label_text(s, where + Vector2(2,2), size, Color(0,0,0,0.5))
 label_text(s, where, size, color)

func _draw() -> void:
 var bg := Color("090c22") if not phase_light else Color("173b57")
 draw_rect(Rect2(0,0,W,H),bg)
 draw_aurora()
 draw_parallax()
 draw_set_transform(camera_base + camera_shake, 0.0, Vector2.ONE)
 draw_world()
 draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
 draw_hud()
 draw_controls()
 draw_overlays()

func draw_aurora() -> void:
 var glow_col := CYAN if phase_light else VIOLET
 for s in starfield:
  var pulse := s["a"] + sin(t*1.7 + s["p"].x*0.015)*0.22
  draw_circle(s["p"], s["s"] + pulse * 0.6, Color(1,1,1, clampf(0.06 + pulse*0.25, 0.04, 0.45)))
 for i in range(6):
  var y := 90.0 + i*42.0 + sin(t*0.6+i)*10.0
  var color := Color(glow_col.r, glow_col.g, glow_col.b, 0.055 - i*0.006 + scene_glow*0.05)
  draw_rect(Rect2(-40, y, W+80, 16+i*2), color)
 for a in ambience:
  var rr := a["r"] + sin(t*a["speed"]*0.08 + a["phase"])*12.0
  var ac := Color(glow_col.r, glow_col.g, glow_col.b, 0.035 if phase_light else 0.05)
  draw_circle(Vector2(a["x"], a["y"] + sin(t*0.5+a["phase"])*18.0), rr, ac)

func draw_parallax() -> void:
 var chroma := CYAN if phase_light else VIOLET
 for layer in range(3):
  var speed: float = [9.0, 20.0, 34.0][layer]
  var offset := fmod(t * speed, 160.0)
  for ix in range(-1,10):
   var bx := float(ix)*165.0-offset
   var by := 355.0 + float(layer)*40.0
   var height_b := 110.0 + float((ix*13+layer*17+100)%7)*26.0
   draw_rect(Rect2(bx,by-height_b,128,height_b+140),with_alpha(chroma,0.026+float(layer)*0.018))
   draw_line(Vector2(bx,by-height_b), Vector2(bx+128,by-height_b),with_alpha(chroma,0.12+float(layer)*0.08),2.0)
 for k in range(24):
  var xx := fmod(float(k)*99.0 - t*(13.0+float(k%4)*7.0), W+50.0)
  var yy := 120.0 + float((k*67)%350)
  draw_circle(Vector2(xx,yy+sin(t*1.7+float(k))*7.0), 1.6 + float(k%3), with_alpha(chroma,0.16))

func draw_boss() -> void:
 if not boss_guard:
  return
 var center := Vector2(1114,325+sin(t*2.0)*11.0)
 var body_color := VIOLET if not phase_light else CYAN
 draw_circle(center,74.0,with_alpha(body_color,0.08))
 draw_arc(center,57.0,0.0,TAU,56,with_alpha(body_color,0.68),4.0)
 draw_arc(center,42.0,t, t+PI*1.45,38,GOLD,5.0)
 draw_circle(center,31.0, Color("121733"))
 draw_circle(center,19.0,GOLD if boss_stunned > 0.0 else body_color)
 draw_circle(center+Vector2(-5,-5),7.0,WHITE)
 for j in range(8):
  var aa := t*0.65 + float(j)*TAU/8.0
  draw_circle(center + Vector2(cos(aa),sin(aa))*61.0,5.0,body_color)
 for shot in boss_shots:
  var q: Vector2 = shot["p"]
  draw_circle(q,24.0,with_alpha(RED,0.18))
  draw_circle(q,16.0,RED)
  draw_circle(q,7.0,WHITE)
 draw_rect(Rect2(982,219,225,13),Color("1b1b31"))
 draw_rect(Rect2(982,219,225.0*boss_energy/3.0,13),GOLD)
 label_text("GUARDIAN  %d/3" % int(boss_energy),Vector2(1010,206),18,GOLD)
 if boss_energy >= 3.0:
  label_text("PORTAL LIBRE",Vector2(1050,251),19,LIME)

func draw_world() -> void:
 var glow_col := CYAN if phase_light else VIOLET
 for j in range(12):
  var skyline := 70+j*118
  var hh := 170 + int(abs(sin(float(j)*2.1))*160)
  draw_rect(Rect2(skyline-30, 400-hh*0.1, 96, 360), Color(0.08,0.12 + j*0.002,0.18,0.18))
  for w in range(3):
   for h in range(5):
    if int((j*13+w*7+h+int(t*3)) % 3) == 0:
     draw_rect(Rect2(skyline-15+w*22, 448-h*32, 8, 12), Color(glow_col.r, glow_col.g, glow_col.b, 0.25))
 draw_rect(Rect2(0,PLAY_BOTTOM-10,W,10),Color("061020"))
 if phase_light:
  draw_circle(p+Vector2(18,22),250,Color(0.58,0.88,1,0.055 + scene_glow*0.05))
 var warning := PHASE_SECONDS-phase_timer < WARN_SECONDS and state == 1
 for platform in levels[level]["platforms"]:
  var x := float(platform[0]); var y := float(platform[1]); var w := float(platform[2]); var mode := int(platform[3])
  var active := platform_enabled(platform)
  var rect := Rect2(x,y,w,22)
  var col := Color("5b867d") if mode==0 else (CYAN if mode==1 else VIOLET)
  if active:
   draw_rect(Rect2(x,y+16,w,26),col.darkened(0.58))
   draw_rect(rect,col)
   draw_rect(Rect2(x,y,w,4),col.lightened(0.3))
   draw_rect(Rect2(x,y-5,w,8),Color(col.r,col.g,col.b,0.12+scene_glow*0.06))
   for u in range(int(w/65)):
    draw_texture_rect(grass,Rect2(x+u*65,y-13,66,22),false,Color(0.76,1,0.85,0.72))
    if active and mode != 0 and int((t*5+u+x)) % 3 == 0:
     draw_circle(Vector2(x+u*65+16+fmod(t*25,50), y-6+sin(t*3+u)*3), 1.8, Color(1,1,1,0.6))
  else:
   draw_rect(rect,Color(col.r,col.g,col.b,0.12),true)
   draw_rect(rect,Color(col.r,col.g,col.b,0.45),false,2)
  if warning and mode!=0:
   draw_rect(Rect2(x,y-3,w,4),GOLD if int((t*8))%2==0 else Color.TRANSPARENT)
 for hazard in levels[level]["hazards"]:
  var xh := float(hazard[0]); var yh := float(hazard[1])
  if hazard[2] == "gull":
   var gx := xh+sin(t*2.0+xh)*50.0
   var gy := yh+sin(t*3.0+xh*0.1)*18.0
   draw_texture_rect(gull,Rect2(gx,gy,78,49),false)
   draw_circle(Vector2(gx+38,gy+24), 24, Color(CYAN.r, CYAN.g, CYAN.b, 0.08))
  else:
   draw_texture_rect(bins,Rect2(xh,yh,50,48),false)
   if int(t*2+xh) % 2 == 0:
    draw_circle(Vector2(xh+25,yh+12), 4, Color(RED.r,RED.g,RED.b,0.22))
 var target: Vector2 = levels[level]["goal"]
 draw_rect(Rect2(target,Vector2(48,69)),with_alpha(GOLD,0.18))
 draw_rect(Rect2(target,Vector2(48,69)),GOLD,false,4)
 draw_circle(target+Vector2(25,27),12,Color(1,0.95,0.63,0.70+sin(t*4)*0.2))
 draw_circle(target+Vector2(25,27), 24 + goal_burst*28, Color(1,0.95,0.63,0.08+goal_burst*0.15))
 for tr in trails:
  var ac := tr["color"]
  ac.a = tr["life"]/tr["max"]*0.4
  draw_circle(tr["p"], 7 + (1.0-tr["life"]/tr["max"])*8.0, ac)
 for q in particles:
  var c: Color = q["color"]
  c.a = minf(1,q["life"]/q["max"])
  match q["kind"]:
   "ring":
    draw_arc(q["p"], q["r"] + (1.0 - q["life"]/q["max"]) * q["grow"], 0, TAU, 40, c, 3.5)
   "burst":
    draw_circle(q["p"], q["r"]*(0.4 + (1.0-q["life"]/q["max"])*0.8), c)
   _:
    draw_circle(q["p"], q["r"], c)
 draw_boss()
 draw_hero(p+Vector2(PW/2,PH),facing)

func draw_hud() -> void:
 var warning := PHASE_SECONDS-phase_timer < WARN_SECONDS and state == 1
 draw_rect(Rect2(0,0,W,88),with_alpha(Color("060d20"),0.84))
 glow_label("CHISPA",Vector2(30,53),39,GOLD)
 glow_label("%02d / %02d" % [level+1,levels.size()],Vector2(276,49),26)
 glow_label("LUZ" if phase_light else "SOMBRA",Vector2(493,46),24,CYAN if phase_light else VIOLET)
 draw_rect(Rect2(629,32,190,17),Color("293453"))
 draw_rect(Rect2(629,32,190*(1-phase_timer/PHASE_SECONDS),17),GOLD if warning else (CYAN if phase_light else VIOLET))
 draw_rect(Rect2(629,32,190*(1-phase_timer/PHASE_SECONDS),6),Color(1,1,1,0.25))
 glow_label("%0.1fs" % (PHASE_SECONDS-phase_timer),Vector2(831,48),20)
 glow_label("CAIDAS  %d" % deaths,Vector2(975,47),20)
 glow_label("SONIDO ON" if not muted else "MUTE",Vector2(1122,76),16,CYAN if not muted else GOLD)
 if screen_message != "":
  var parts := screen_message.split("\n")
  draw_rect(Rect2(370,92,540,70 if parts.size()==1 else 104),with_alpha(Color("081227"),0.70))
  draw_rect(Rect2(370,92,540,70 if parts.size()==1 else 104),with_alpha(CYAN if phase_light else VIOLET,0.4),false,2)
  glow_label(parts[0], Vector2(410,128), 30, GOLD)
  if parts.size() > 1:
   glow_label(parts[1], Vector2(410,165), 20, WHITE)

func draw_controls() -> void:
 # Dedicated opaque control bar; world art never uses this space.
 draw_rect(Rect2(0,PLAY_BOTTOM,W,H-PLAY_BOTTOM),Color("071327"))
 draw_line(Vector2(0,PLAY_BOTTOM),Vector2(W,PLAY_BOTTOM),CYAN.darkened(0.38),3.0)
 label_text("MOVER",Vector2(92,587),18,Color("91bdd5"))
 label_text("SALTAR / DOBLE SALTO",Vector2(924,587),18,Color("91bdd5"))
 draw_control(Rect2(27,594,138,105),"<")
 draw_control(Rect2(178,594,138,105),">")
 draw_control(Rect2(996,594,260,105),"SALTAR")

func draw_overlays() -> void:
 var warning := PHASE_SECONDS-phase_timer < WARN_SECONDS and state == 1
 if intro_timer > 0 and state == 1:
  var a := intro_timer / INTRO_SECONDS
  var bar := 54.0 * ease(a, 0.4)
  draw_rect(Rect2(0,0,W,bar),Color.BLACK)
  draw_rect(Rect2(0,H-bar,W,bar),Color.BLACK)
  glow_label(levels[level]["name"], Vector2(420, 100), 34, GOLD)
  glow_label(levels[level]["subtitle"], Vector2(390, 136), 22, WHITE)
 if warning:
  draw_rect(Rect2(403,90,480,49),with_alpha(Color("2a203f"),0.86))
  glow_label("CAMBIO DE FASE INMINENTE",Vector2(434,125),22,GOLD)
 if flash > 0:
  draw_rect(Rect2(0,0,W,H),Color(0.77,0.94,1,flash*0.22))
 # lightweight postprocessing: animated scanlines, vignette, chromatic-edge strips.
 if fx_quality:
  for n in range(0,554,8):
   draw_rect(Rect2(0,n,W,1),Color(0.05,0.07,0.15,0.08))
  for n in range(8):
   var a := 0.016*float(n+1)
   draw_rect(Rect2(n*5,0,5,554),Color(0.0,0.0,0.0,a))
   draw_rect(Rect2(W-5-n*5,0,5,554),Color(0.0,0.0,0.0,a))
  if flash > 0.0:
   draw_rect(Rect2(0,0,6,554),with_alpha(CYAN if phase_light else VIOLET,flash*0.42))
   draw_rect(Rect2(W-6,0,6,554),with_alpha(VIOLET if phase_light else CYAN,flash*0.42))
 draw_rect(Rect2(0,0,W,H), Color(0.0, 0.0, 0.0, 0.04))
 if state != 1:
  draw_rect(Rect2(163,115,953,336),with_alpha(Color("081227"),0.96))
  draw_rect(Rect2(163,115,953,336),CYAN,false,3)
  if state == 0:
   glow_label("CHISPA: EL MUNDO SE APAGA",Vector2(223,240),38,GOLD)
   glow_label("La luz cambia sola. Aprende el ritmo, salta y sobrevive.",Vector2(250,300),25)
   glow_label("MOVER  A / D    |    SALTAR  ESPACIO    |    DOBLE SALTO",Vector2(229,365),22)
   glow_label("TOCA PARA EMPEZAR",Vector2(431,422),30,CYAN)
  elif state == 2:
   glow_label("NIVEL SUPERADO",Vector2(444,255),39,GOLD)
   glow_label("TOCA PARA CONTINUAR",Vector2(423,405),28,CYAN)
  else:
   glow_label("EL MUNDO VUELVE A BRILLAR",Vector2(306,250),38,GOLD)
   glow_label("TERMINASTE LOS 7 NIVELES",Vector2(392,352),27)
   glow_label("TOCA PARA REINICIAR",Vector2(430,416),25,CYAN)

func draw_control(rect: Rect2, caption: String) -> void:
 draw_rect(rect,with_alpha(Color("1c3a5a"),0.79))
 draw_rect(rect,CYAN,false,2)
 draw_rect(Rect2(rect.position + Vector2(0,0), Vector2(rect.size.x, 6)), Color(CYAN.r, CYAN.g, CYAN.b, 0.18))
 glow_label(caption,rect.position+Vector2(26,68),28,WHITE)

# Character animation rig: separate head, chest, upper/lower arms, upper/lower legs,
# feet and tail. Angles respond to grounded running, acceleration and vertical speed.
func limb(a: Vector2,b: Vector2,width: float,shade: Color) -> void:
 draw_line(a+Vector2(2,3),b+Vector2(2,3),Color("071c62"),width+4,true)
 draw_line(a,b,shade,width,true)
 draw_circle(a,width*0.5,shade)
 draw_circle(b,width*0.5,shade)

func draw_hero(at: Vector2,dir: float) -> void:
 var running := grounded and absf(v.x)>35
 var swing := sin(run_cycle)* (0.78 if running else 0.07)
 var yfloat := -absf(sin(run_cycle*2))*2.7 if running else (sin(t*3)*1.3 if grounded else -3.0)
 var pivot := at+Vector2(0,-43+yfloat+land_bounce*9.0)
 var hip := pivot+Vector2(-4,16)
 var chest := pivot+Vector2(0,-18)
 var near_arm := chest+Vector2(-dir*8,-1)
 var far_arm := chest+Vector2(dir*8,-1)
 var kick := clampf(v.y/720,-1,1)
 var left_knee := hip+Vector2(-11+swing*20,-14 if not grounded else 16+absf(swing)*4)
 var right_knee := hip+Vector2(11-swing*20,-14 if not grounded else 16+absf(swing)*4)
 var left_foot := left_knee+Vector2(-3+swing*12,22+kick*7)
 var right_foot := right_knee+Vector2(5-swing*12,22-kick*7)
 limb(hip+Vector2(-6,0),left_knee,15,Color("0649aa"))
 limb(left_knee,left_foot,13,Color("0875d9"))
 draw_circle(left_foot+Vector2(dir*5,3),10,Color("24c8ff"))
 draw_line(hip+Vector2(-dir*9,-6),hip+Vector2(-dir*31,4+sin(t*6)*4),Color("0758c7"),11,true)
 draw_line(hip+Vector2(-dir*31,4+sin(t*6)*4),hip+Vector2(-dir*46,-7+sin(t*6)*8),CYAN,7,true)
 var far_elbow := far_arm+Vector2(-dir*13+swing*7,16)
 var far_hand := far_elbow+Vector2(-dir*7+swing*13,18)
 limb(far_arm,far_elbow,12,Color("0750bc"))
 limb(far_elbow,far_hand,10,Color("1673d5"))
 draw_circle(far_hand,9,Color("168ff2"))
 draw_colored_polygon(PackedVector2Array([chest+Vector2(-16,-5),chest+Vector2(14,-5),hip+Vector2(13,9),hip+Vector2(-15,9)]),Color("0753c6"))
 draw_colored_polygon(PackedVector2Array([chest+Vector2(-5,2),chest+Vector2(10,0),hip+Vector2(6,5),hip+Vector2(-5,5)]),Color("a8f0ed"))
 limb(hip+Vector2(6,0),right_knee,16,Color("0867d3"))
 limb(right_knee,right_foot,14,Color("169cf0"))
 draw_circle(right_foot+Vector2(dir*6,3),11,Color("17bcff"))
 var elbow := near_arm+Vector2(dir*12-swing*12,15)
 var hand := elbow+Vector2(dir*8-swing*16,16)
 limb(near_arm,elbow,13,Color("1768dd"))
 limb(elbow,hand,11,Color("159bf2"))
 draw_circle(hand,10,CYAN)
 var head := chest+Vector2(0,-20+kick*3)
 var spikes := PackedVector2Array([head+Vector2(-16,1),head+Vector2(-32,-10),head+Vector2(-14,-10),head+Vector2(-23,-27),head+Vector2(-3,-18),head+Vector2(-8,-37),head+Vector2(16,-14),head+Vector2(5,3)])
 draw_colored_polygon(spikes,Color("0658c7"))
 draw_circle(head,22,Color("0878e6"))
 draw_circle(head+Vector2(dir*8,5),14,Color("e7e1c7"))
 draw_circle(head+Vector2(dir*13,-5),8,Color("f1ffff"))
 draw_circle(head+Vector2(dir*15,-3),5,Color("008fda"))
 draw_circle(head+Vector2(dir*16,-4),2.5,Color("03235b"))
 draw_line(head+Vector2(dir*9,12),head+Vector2(dir*18,13),Color("284161"),1.5,true)
