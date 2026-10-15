# CHISPA DELUXE — revisión del arranque Android

Esta versión conserva los 7 niveles, jefes, música dinámica, cinemáticas, plataformas automáticas luz/sombra y controles horizontales. Se corrigieron las declaraciones de tipos inferidos desde valores dinámicos de GDScript para evitar fallos de compilación del script principal.

## Comprobación en GitHub Actions

El workflow ahora **inicia la escena principal en modo headless antes de exportar**. Si el juego presenta errores de GDScript en el arranque, el workflow se detiene y publica el archivo `build/startup.log` en `Chispa-Pro-Diagnosticos`, en lugar de entregar un APK inutilizable.

La verificación headless no sustituye una prueba de gráficos y controles en un teléfono Android. Si se queda en negro después de una compilación verde, obtener el `adb logcat` filtrando `godot` / `AndroidRuntime` ayudará a aislar errores específicos del dispositivo.

## Instalar

Descomprimir y subir a la raíz del repositorio. El workflow está en `.github/workflows/android.yml`. Descargar `Chispa-Android-APK` desde GitHub Actions.
