extends Node2D
# CHISPA PRO - auto-cycling light world, articulated hero, deterministic 2D physics.
const W := 1280.0
const H := 720.0
const PW := 44.0
const PH := 86.0
const RUN := 350.0
const ACCEL := 2150.0
const FRICTION := 2700.0
const GRAVITY := 2050.0
const JUMP := -745.0
const PHASE_SECONDS := 7.0
const WARN_SECONDS := 1.4
const CYAN := Color("55edf7")
const VIOLET := Color("af83ff")
const GOLD := Color("ffdf88")
const INK := Color("0a1029")
const WHITE := Color("effaff")
var face: Texture2D = preload("res://assets/face.png")
var grass: Texture2D = preload("res://assets/grass.png")
var gull: Texture2D = preload("res://assets/gull.png")
var bins: Texture2D = preload("res://assets/bins.png")
var font: Font = ThemeDB.fallback_font
var levels := [
 {"name":"PRIMER DESTELLO", "platforms":[[0,600,306,0],[340,546,205,1],[595,600,224,0],[858,536,194,2],[1080,600,200,0]], "hazards":[[716,556,"bin"]], "goal":Vector2(1200,540), "spawn":Vector2(90,514)},
 {"name":"ENTRE DOS MUNDOS", "platforms":[[0,600,258,0],[300,534,178,2],[520,472,181,1],[746,534,175,2],[965,600,315,0]], "hazards":[[1071,556,"bin"]], "goal":Vector2(1200,540),"spawn":Vector2(90,514)},
 {"name":"PULSO FINAL", "platforms":[[0,600,250,0],[282,530,155,1],[465,461,164,2],[662,405,155,1],[848,515,170,2],[1060,600,220,0]], "hazards":[[538,396,"gull"]], "goal":Vector2(1190,540),"spawn":Vector2(90,514)}
]
var level := 0
var state := 0 # menu, playing, level complete, all complete
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
var touches: Dictionary = {}
var move_axis := 0.0
var jump_press := false
var transition := 0.0
var best_level := 1
var starfield: Array = []

func _ready() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 99477
 for i in range(56):
  starfield.append(Vector2(rng.randf_range(0,W),rng.randf_range(80,540)))
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
 phase_light = true
 phase_grace = 0.0
 run_cycle = 0.0
 particles.clear()
 touches.clear()
 jump_press = false
 move_axis = 0.0

func start() -> void:
 if state == 3:
  level = 0
  deaths = 0
 state = 1
 reset_level()

func platform_enabled(item: Array) -> bool:
 return int(item[3]) == 0 or (int(item[3]) == 1) == phase_light

func make_sparks(location: Vector2, amount: int, color: Color) -> void:
 for i in range(amount):
  var a := randf_range(-PI,0.0)
  particles.append({"p":location,"v":Vector2(cos(a),sin(a))*randf_range(70,210),"life":randf_range(0.18,0.52),"max":0.52,"color":color})

func request_jump() -> void:
 if state != 1:
  start()
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

func _input(e: InputEvent) -> void:
 if e is InputEventScreenTouch:
  if e.pressed:
   touches[e.index] = e.position
   if state != 1:
    start()
   elif e.position.x > 900 and e.position.y > 500:
    request_jump()
  else:
   touches.erase(e.index)
 elif e is InputEventScreenDrag:
  touches[e.index] = e.position
 elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
  if state != 1:
   start()
  elif e.position.x > 900 and e.position.y > 500:
   request_jump()

func _physics_process(dt: float) -> void:
 dt = minf(dt,0.035)
 t += dt
 flash = maxf(0,flash-dt*1.9)
 shake = maxf(0,shake-dt*20)
 land_bounce = move_toward(land_bounce,0,dt*6)
 for i in range(particles.size() - 1, -1, -1):
  var q: Dictionary = particles[i]
  q["p"] += q["v"]*dt
  q["v"] += Vector2(0,500)*dt
  q["life"] -= dt
  if q["life"] <= 0: particles.remove_at(i)
  else: particles[i] = q
 if state != 1:
  queue_redraw()
  return
 elapsed += dt
 phase_timer += dt
 if phase_timer >= PHASE_SECONDS:
  phase_timer -= PHASE_SECONDS
  phase_light = not phase_light
  phase_grace = 0.20
  flash = 0.45
  shake = 2.0
  make_sparks(Vector2(W/2,310),32,CYAN if phase_light else VIOLET)
 phase_grace = maxf(0,phase_grace-dt)
 move_axis = 0.0
 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):move_axis -= 1
 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):move_axis += 1
 for pt in touches.values():
  if pt.y > 495:
   if pt.x < 170: move_axis -= 1
   elif pt.x < 350: move_axis += 1
 move_axis = clampf(move_axis,-1,1)
 if absf(move_axis)>0.1:
  v.x = move_toward(v.x,move_axis*RUN,ACCEL*dt)
  facing = signf(move_axis)
 else:v.x = move_toward(v.x,0,FRICTION*dt)
 if grounded:coyote = 0.115
 else:coyote = maxf(0,coyote-dt)
 buffer = maxf(0,buffer-dt)
 if buffer > 0 and (coyote > 0 or air_jump):
  var first := coyote>0
  v.y = JUMP if first else JUMP*0.82
  if not first:air_jump = false
  coyote = 0
  grounded = false
  buffer = 0
  land_bounce = -0.18
  make_sparks(p+Vector2(PW/2,PH),9,CYAN)
 v.y = minf(v.y + GRAVITY*dt,1100)
 if v.y < 0 and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)):
  v.y -= 285*dt
 var old_bottom := p.y+PH
 p += v*dt
 p.x = clampf(p.x,0,W-PW)
 var was_grounded := grounded
 grounded = false
 for platform in levels[level]["platforms"]:
  if not platform_enabled(platform) and phase_grace <= 0:continue
  var x := float(platform[0]); var y := float(platform[1]);var width := float(platform[2])
  if v.y >= 0 and old_bottom <= y+10 and p.y+PH >= y and p.x+PW-8 > x and p.x+8 < x+width:
   p.y = y-PH
   v.y = 0
   grounded = true
   air_jump = true
   if not was_grounded:
    land_bounce = 0.25
    shake = 2
    make_sparks(p+Vector2(PW/2,PH),10,GOLD)
   break
 if not grounded and was_grounded: coyote = 0.11
 if grounded and absf(v.x)>30:run_cycle += absf(v.x)*dt*0.038
 elif not grounded:run_cycle += dt*3.0
 if p.y > H+65:
  die()
  return
 for hazard in levels[level]["hazards"]:
  var hx := float(hazard[0]);var hy := float(hazard[1])
  var r := Rect2(hx,hy,44,44)
  if hazard[2] == "gull":
   r = Rect2(hx+sin(t*2)*50,hy+sin(t*3)*18,73,45)
  if Rect2(p+Vector2(9,13),Vector2(PW-18,PH-20)).intersects(r):
   die()
   return
 var goal: Vector2 = levels[level]["goal"]
 if Rect2(p,Vector2(PW,PH)).intersects(Rect2(goal,Vector2(50,68))):
  make_sparks(goal+Vector2(20,20),28,GOLD)
  level += 1
  if level >= levels.size():
   level = levels.size()-1
   state = 3
  else:
   state = 2
   best_level = maxi(best_level,level+1)
  reset_level()
 queue_redraw()

func die() -> void:
 deaths += 1
 shake = 11
 flash = 0.55
 reset_level()

func label_text(s: String, where: Vector2, size: int, color: Color=WHITE) -> void:
 draw_string(font,where,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
 var bg := Color("090c22") if not phase_light else Color("173b57")
 draw_rect(Rect2(0,0,W,H),bg)
 for i in range(starfield.size()):
  var sp: Vector2 = starfield[i]
  draw_circle(sp,2.0+sin(t*1.6+float(i))*0.6,Color(0.63,0.80,1,0.37) if not phase_light else Color(0.9,1,1,0.22))
 for j in range(10):
  var skyline := 105+j*139
  draw_rect(Rect2(skyline-40,300+sin(float(j)*2.5)*80,95,330),Color(0.1,0.18,0.31,0.6))
 draw_rect(Rect2(0,625,W,95),Color("07111e"))
 if phase_light:
  draw_circle(p+Vector2(18,22),230,Color(0.58,0.88,1,0.055))
 var warning := PHASE_SECONDS-phase_timer < WARN_SECONDS and state == 1
 for platform in levels[level]["platforms"]:
  var x := float(platform[0]); var y := float(platform[1]); var w := float(platform[2]);var mode := int(platform[3])
  var active := platform_enabled(platform)
  var rect := Rect2(x,y,w,22)
  var col := Color("5b867d") if mode==0 else (CYAN if mode==1 else VIOLET)
  if active:
   draw_rect(Rect2(x,y+16,w,26),col.darkened(0.58))
   draw_rect(rect,col)
   draw_rect(Rect2(x,y,w,4),col.lightened(0.3))
   for u in range(int(w/65)):
    draw_texture_rect(grass,Rect2(x+u*65,y-13,66,22),false,Color(0.76,1,0.85,0.7))
  else:
   draw_rect(rect,Color(col.r,col.g,col.b,0.16),true)
   draw_rect(rect,Color(col.r,col.g,col.b,0.5),false,2)
  if warning and mode!=0:
   draw_rect(Rect2(x,y-3,w,4),GOLD if int((t*8))%2==0 else Color.TRANSPARENT)
 for hazard in levels[level]["hazards"]:
  var xh := float(hazard[0]); var yh := float(hazard[1])
  if hazard[2] == "gull":draw_texture_rect(gull,Rect2(xh+sin(t*2)*50,yh+sin(t*3)*18,78,49),false)
  else:draw_texture_rect(bins,Rect2(xh,yh,50,48),false)
 var target: Vector2 = levels[level]["goal"]
 draw_rect(Rect2(target,Vector2(48,69)),Color(GOLD,0.18))
 draw_rect(Rect2(target,Vector2(48,69)),GOLD,false,4)
 draw_circle(target+Vector2(25,27),12,Color(1,0.95,0.63,0.70+sin(t*4)*0.2))
 for q in particles:
  var c: Color = q["color"]
  c.a = minf(1,q["life"]/q["max"])
  draw_circle(q["p"],3,c)
 draw_hero(p+Vector2(PW/2,PH),facing)
 draw_rect(Rect2(0,0,W,86),Color("060d20",0.86))
 label_text("CHISPA",Vector2(30,53),39,GOLD)
 label_text("%02d / %02d" % [level+1,levels.size()],Vector2(276,49),26)
 label_text("LUZ" if phase_light else "SOMBRA",Vector2(493,46),24,CYAN if phase_light else VIOLET)
 draw_rect(Rect2(629,32,190,17),Color("293453"))
 draw_rect(Rect2(629,32,190*(1-phase_timer/PHASE_SECONDS),17),GOLD if warning else (CYAN if phase_light else VIOLET))
 label_text("%0.1fs" % (PHASE_SECONDS-phase_timer),Vector2(831,48),20)
 label_text("CAIDAS  %d" % deaths,Vector2(986,47),20)
 draw_control(Rect2(26,568,136,125),"<")
 draw_control(Rect2(174,568,136,125),">")
 draw_control(Rect2(1070,555,185,140),"SALTAR")
 if warning:
  draw_rect(Rect2(403,90,480,49),Color("2a203f",0.86))
  label_text("CAMBIO DE FASE INMINENTE",Vector2(434,125),22,GOLD)
 if flash>0:draw_rect(Rect2(0,0,W,H),Color(0.77,0.94,1,flash*0.2))
 if state!=1:
  draw_rect(Rect2(163,155,953,366),Color("081227",0.96))
  draw_rect(Rect2(163,155,953,366),CYAN,false,3)
  if state==0:
   label_text("CHISPA: EL MUNDO SE APAGA",Vector2(223,240),38,GOLD)
   label_text("La luz cambia sola. Aprende el ritmo y sobrevive.",Vector2(280,300),25)
   label_text("MOVER  A / D    |    SALTAR  ESPACIO    |    DOBLE SALTO",Vector2(229,365),22)
   label_text("TOCA PARA EMPEZAR",Vector2(431,457),30,CYAN)
  elif state==2:
   label_text("NIVEL SUPERADO",Vector2(444,255),39,GOLD)
   label_text("TOCA PARA CONTINUAR",Vector2(423,405),28,CYAN)
  else:
   label_text("EL MUNDO VUELVE A BRILLAR",Vector2(306,250),38,GOLD)
   label_text("TERMINASTE LOS 3 NIVELES",Vector2(392,352),27)
   label_text("TOCA PARA REINICIAR",Vector2(430,428),25,CYAN)

func draw_control(rect: Rect2, caption: String) -> void:
 draw_rect(rect,Color("1c3a5a",0.79))
 draw_rect(rect,CYAN,false,2)
 label_text(caption,rect.position+Vector2(25,83),28,WHITE)

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
 var pivot := at+Vector2(0,-43+yfloat)
 # Each articulated segment has its own joint coordinates and velocity-derived pose.
 var hip := pivot+Vector2(-4,16)
 var chest := pivot+Vector2(0,-18)
 var near_arm := chest+Vector2(-dir*8,-1)
 var far_arm := chest+Vector2(dir*8,-1)
 var kick := clampf(v.y/720,-1,1)
 var left_knee := hip+Vector2(-11+swing*20,-14 if not grounded else 16+absf(swing)*4)
 var right_knee := hip+Vector2(11-swing*20,-14 if not grounded else 16+absf(swing)*4)
 var left_foot := left_knee+Vector2(-3+swing*12,22+kick*7)
 var right_foot := right_knee+Vector2(5-swing*12,22-kick*7)
 # far leg behind torso
 limb(hip+Vector2(-6,0),left_knee,15,Color("0649aa"))
 limb(left_knee,left_foot,13,Color("0875d9"))
 draw_circle(left_foot+Vector2(dir*5,3),10,Color("24c8ff"))
 # sweeping tail
 draw_line(hip+Vector2(-dir*9,-6),hip+Vector2(-dir*31,4+sin(t*6)*4),Color("0758c7"),11,true)
 draw_line(hip+Vector2(-dir*31,4+sin(t*6)*4),hip+Vector2(-dir*46,-7+sin(t*6)*8),CYAN,7,true)
 # far arm
 var far_elbow := far_arm+Vector2(-dir*13+swing*7,16)
 var far_hand := far_elbow+Vector2(-dir*7+swing*13,18)
 limb(far_arm,far_elbow,12,Color("0750bc"))
 limb(far_elbow,far_hand,10,Color("1673d5"))
 draw_circle(far_hand,9,Color("168ff2"))
 # torso
 draw_colored_polygon(PackedVector2Array([chest+Vector2(-16,-5),chest+Vector2(14,-5),hip+Vector2(13,9),hip+Vector2(-15,9)]),Color("0753c6"))
 draw_colored_polygon(PackedVector2Array([chest+Vector2(-5,2),chest+Vector2(10,0),hip+Vector2(6,5),hip+Vector2(-5,5)]),Color("a8f0ed"))
 # near leg
 limb(hip+Vector2(6,0),right_knee,16,Color("0867d3"))
 limb(right_knee,right_foot,14,Color("169cf0"))
 draw_circle(right_foot+Vector2(dir*6,3),11,Color("17bcff"))
 # near arm (counterphase swing)
 var elbow := near_arm+Vector2(dir*12-swing*12,15)
 var hand := elbow+Vector2(dir*8-swing*16,16)
 limb(near_arm,elbow,13,Color("1768dd"))
 limb(elbow,hand,11,Color("159bf2"))
 draw_circle(hand,10,CYAN)
 # quills on the head rotate subtly with horizontal velocity
 var head := chest+Vector2(0,-20+kick*3)
 var spikes := PackedVector2Array([head+Vector2(-16,1),head+Vector2(-32,-10),head+Vector2(-14,-10),head+Vector2(-23,-27),head+Vector2(-3,-18),head+Vector2(-8,-37),head+Vector2(16,-14),head+Vector2(5,3)])
 draw_colored_polygon(spikes,Color("0658c7"))
 draw_circle(head,22,Color("0878e6"))
 draw_circle(head+Vector2(dir*8,5),14,Color("e7e1c7"))
 draw_circle(head+Vector2(dir*13,-5),8,Color("f1ffff"))
 draw_circle(head+Vector2(dir*15,-3),5,Color("008fda"))
 draw_circle(head+Vector2(dir*16,-4),2.5,Color("03235b"))
 draw_line(head+Vector2(dir*9,12),head+Vector2(dir*18,13),Color("284161"),1.5,true)
