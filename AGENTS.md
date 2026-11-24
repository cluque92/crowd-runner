# AGENTS.md — Crowd Runner

> Instrucciones para agentes de IA que trabajen en este repositorio. Léelas antes de tocar código.
> Responde y documenta en **español**. La interfaz y los comentarios están en español; mantén esa línea.

## Qué es este proyecto

Juego runner hipercasual de multitudes: multiplicas tu ejército con puertas, arrasas hordas y derrotas a un jefe a lo largo de **65 niveles**. Se juega en el navegador, se instala como PWA y se empaqueta como APK Android.

- **Web:** un único `index.html` con HTML, CSS y JavaScript vanilla. Sin dependencias, sin npm y sin build.
- **Android:** WebView mínima en `apk/` y un script que compila y firma el APK sin Android Studio.
- **Fuente de verdad funcional:** el propio `index.html`; `README.md` no existe en este repo, así que documenta aquí los cambios relevantes.

## Estructura

```
index.html            Todo el juego: estilos, HUD, overlays y JS
icons/                Iconos PWA 192 y 512
manifest.json         Metadatos PWA (fullscreen, portrait)
sw.js                 Service worker cache-first para uso offline
apk/
  MainActivity.java   WebView que carga assets/www/index.html
  AndroidManifest.xml
build-apk.sh          Pipeline aapt + javac + d8 + zipalign + apksigner
CrowdRunner.apk       APK generado (no editar a mano)
```

## Cómo ejecutarlo

```bash
cd /home/cris/Documentos/soldados
python3 -m http.server 8080
# http://localhost:8080
```

El service worker solo se registra en `http(s)`, no en `file://`. Para probar la PWA y el modo offline hace falta servidor.

Controles: flechas izquierda/derecha o `A`/`D`; arrastrar en pantalla táctil; `Esc`/`P` pausa.

## Compilar el APK

```bash
cd /home/cris/Documentos/soldados
./build-apk.sh
# Genera CrowdRunner.apk y lo firma con la keystore de /tmp/opencode/apkbuild
```

El script usa rutas absolutas y herramientas concretas del equipo:

- SDK: `~/Android/Sdk`, build-tools `37.0.0`, plataforma `android-35`.
- JDK: `~/development/jdk`.
- Trabajo temporal: `/tmp/opencode/apkbuild`.
- `minSdk 24`, `targetSdk 34`.

**Si mueves el repositorio o cambias de SDK, actualiza las rutas del script.** El APK copia `index.html`, iconos y `manifest.json`; vuelve a compilarlo después de cualquier cambio en el juego.

> **Aviso de firma:** el script hace `rm -rf /tmp/opencode/apkbuild` al empezar, así que también borra la keystore generada y cada compilación firma con una clave nueva. Para actualizar una instalación existente sin desinstalar, conserva la keystore en una ruta permanente y reutilízala.

## Arquitectura del juego

`index.html` está dividido en secciones numeradas. Respétalas al añadir código:

1. `CONFIG` — constantes de cámara, carril, disparo y render.
2. Utilidades matemáticas y aleatorias.
3. Canvas, resize y DPR.
4. Atmósferas (`PRESETS`, `ATM_ORDER`): día, atardecer, noche, alba y dorado.
5. Audio con Web Audio (`tone`, `sfx`).
6. Estado, niveles y progreso. `S` es la máquina de estados (`TITLE`, `MAP`, `TRANS`, `PLAY`, `WIN`, `LOSE`); `levelCfg(n)` escala la dificultad de forma exponencial.
7. Puertas, hordas y obstáculos.
8. Input (teclado, puntero y arrastre).
9. Generación aleatoria del nivel.
10. Arma y disparo (solo contra el jefe).
11. Partículas, números flotantes y efectos.
12. Render del mundo (fondo, carretera, vegetación, niebla, meta, sprites).
13. Flujo de partida (`startLevel`, `winLevel`, `lose`, mapa, overlays).
14. Login/perfiles y monedas.
15. Bucle principal con `requestAnimationFrame` y `dt` limitado a 0,05 s.

Detalles que no debes romper:

- **Sprites horneados**: los humanoides se dibujan una vez en canvases offscreen (`baked`) y luego se estampan; no vuelvas a dibujarlos por frame.
- **Progreso**: `localStorage` usa `crowdRunner.users.v2` (perfiles) y migra desde `crowdRunner.v1`. No cambies la clave sin migración.
- **Desbloqueo**: el nivel actual es `progress.unlocked`; ganar guarda récord por nivel y desbloquea el siguiente.
- **Pausa**: al ocultar la pestaña se pausa automáticamente.
- **Service worker**: si cambias assets o el HTML, sube la versión de `CACHE` en `sw.js` (`crowd-runner-v1` → `v2`…) para evitar servir una versión antigua.

## Convenciones

- JavaScript clásico dentro de un único `<script>`, sin módulos ni bundler.
- 2 espacios, comillas dobles en HTML/JS existentes, punto y coma y funciones pequeñas.
- Comentarios de sección con el formato `/* ==================== N. Título ==================== */`.
- Mantén el HUD y los overlays accesibles: botones reales, textos legibles y foco visible.
- Respeta `prefers-reduced-motion` si añades animaciones de interfaz.
- No introduzcas dependencias externas, fuentes remotas ni assets que rompan el modo offline.

## Verificación antes de terminar

No hay tests automatizados. Comprueba manualmente:

1. Carga con servidor local y sin errores en consola.
2. Niveles 1, 15, 40 y 65: puertas buenas/malas, hordas, obstáculos, jefe y victoria/derrota.
3. Mapa, desbloqueo y récord tras recargar.
4. Perfiles: crear, cambiar, invitado y migración desde la clave v1.
5. Móvil en vertical y escritorio; arrastre y teclado.
6. Pausa, cambio de pestaña y reanudación.
7. PWA: instalación, recarga offline y versión de caché actualizada.
8. `./build-apk.sh` termina con firma válida y el APK instala y abre.

## Reglas para agentes

- No hagas commits, pushes, builds de release ni despliegues sin que se te pida.
- No edites `CrowdRunner.apk` ni los archivos de `apk/` generados a mano; cambia el código y reconstruye.
- No rompas la compatibilidad con `file://` (el juego debe abrirse con doble clic aunque la PWA necesite servidor).
- `../CLN/demos/crowd-runner/` es una copia embebida de este juego. Si actualizas el juego, sincroniza esa copia para que la web personal no quede desfasada.
- Si cambias el número de niveles (`N_LEVELS`), revisa el mapa, los textos de campaña y los récords.
- No añadas analítica, anuncios ni servicios externos sin una petición explícita.
