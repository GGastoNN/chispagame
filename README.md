# CHISPA PRO — El mundo se apaga

Proyecto Godot **4.4.1** para Android (1280×720, horizontal). Primera vertical slice de 3 niveles.

## Jugabilidad

- La fase **LUZ / SOMBRA cambia automáticamente cada 7 segundos**, con aviso de 1,4 segundos, barra de cuenta atrás y destello de cambio. **No hay botón para cambiar de fase**.
- Plataformas turquesas existen en LUZ; violetas en SOMBRA; las verdes permanecen siempre.
- Movimiento con aceleración/frenado, gravedad, velocidad terminal, salto de altura variable, doble salto, coyote time (0,115 s), jump buffer (0,15 s), partículas de despegue y aterrizaje.
- Personaje reilustrado como **rig 2D** separado en cabeza, púas, torso, brazos, antebrazos, manos, muslos, piernas, pies y cola, con pose dependiente de movimiento. El `hero.png` original queda incluido como referencia; `face.png` contiene un recorte experimental de rostro (no se usa en el rig de dibujo).
- 3 niveles jugables con gaviota, basura, puertas, HUD, controles táctiles, menú y pantalla final.

## Controles

En PC: **A / D** o **← / →** para caminar, **Espacio / W / ↑** para saltar o doble salto, **R** para reiniciar el nivel.
En Android: botones táctiles izquierda, derecha y SALTAR (admite multitouch).

## Compilar APK por GitHub Actions

Subí **los contenidos de esta carpeta**, no la carpeta en sí, a la raíz de tu repositorio `dashgame`. El flujo `.github/workflows/android.yml` instala Godot 4.4.1/SDK Android y publica el artefacto `Chispa-Android-APK`. El archivo `project.godot` ya habilita texturas ETC2/ASTC para Android.

> El APK todavía debe validarse ejecutando el workflow. No se incluye APK compilado.

## Desarrollo

El prototipo usa un controlador de física propio con colisiones rectangulares tipo *one-way*; para un lanzamiento comercial sería conveniente migrar a `CharacterBody2D` con `CollisionShape2D`, dividir el juego en escenas por nivel e incorporar sonidos y animaciones con `AnimationTree`. Los 3 niveles actuales son de prueba, no los 100 del concepto final.
