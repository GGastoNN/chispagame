# CHISPA PRO — Horizontal + Sonido

Proyecto Godot 4.4.1 para Android. **Pantalla horizontal** (landscape 1280×720), barra de controles independiente bajo el área jugable, y sonidos originales sintetizados incluidos en `audio/`.

## Jugar
- En Android: botones `<`, `>` y `SALTAR` en la franja inferior. Toque `SONIDO ON` para silenciar.
- En teclado: A/D o flechas para moverse; espacio/W/flecha arriba para saltar; doble salto en el aire; R reinicia.
- Las fases de luz/oscuridad cambian automáticamente cada 7 segundos. Escuchás un aviso antes del cambio.
- Efectos: salto, doble salto, aterrizaje, aviso, cambio a luz, cambio a sombra, muerte, completar nivel, inicio.

## Exportar APK
Subir el contenido de esta carpeta a la raíz del repositorio. `.github/workflows/android.yml` compila con GitHub Actions y publica `Chispa-Android-APK`.

El audio es PCM WAV mono, sintetizado específicamente para esta versión. No requiere recursos externos. La orientación horizontal se establece en `project.godot`.

**Nota:** proyecto actualizado pero no se ha comprobado aquí la compilación final ni probado en un teléfono real.
