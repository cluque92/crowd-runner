#!/usr/bin/env bash
# ============================================================
# build-apk.sh — compila CrowdRunner.apk SIN Android Studio
# pipeline: aapt(v1) + javac + d8 + zipalign + apksigner
# ============================================================
set -e
SDK="$HOME/Android/Sdk"
BT="$SDK/build-tools/37.0.0"
PLAT="$SDK/platforms/android-35/android.jar"
JAVA="$HOME/development/jdk/bin"
DIR="/home/cris/Documentos/soldados/apk"
BUILD="/tmp/opencode/apkbuild"
OUT="/home/cris/Documentos/soldados/CrowdRunner.apk"

export JAVA_HOME="$HOME/development/jdk"
export PATH="$JAVA_HOME/bin:$PATH"
export LC_ALL=C

rm -rf "$BUILD"; mkdir -p "$BUILD/gen" "$BUILD/classes" "$BUILD/dex"

# 0) recursos: icono
mkdir -p "$DIR/res/drawable"
cp -f /home/cris/Documentos/soldados/icons/icon-192.png "$DIR/res/drawable/ic_launcher.png"

# 1) assets del juego (versión web actual)
mkdir -p "$BUILD/assets/www/icons"
cp -f /home/cris/Documentos/soldados/index.html        "$BUILD/assets/www/"
cp -f /home/cris/Documentos/soldados/icons/icon-192.png "$BUILD/assets/www/icons/" 2>/dev/null || true
cp -f /home/cris/Documentos/soldados/icons/icon-512.png "$BUILD/assets/www/icons/" 2>/dev/null || true
cp -f /home/cris/Documentos/soldados/manifest.json      "$BUILD/assets/www/" 2>/dev/null || true

# 2) aapt v1: R.java + APK con recursos y assets
"$BT/aapt" package -f \
  -M "$DIR/AndroidManifest.xml" \
  -S "$DIR/res" \
  -A "$BUILD/assets" \
  -I "$PLAT" \
  -J "$BUILD/gen" \
  --min-sdk-version 24 --target-sdk-version 34 \
  -F "$BUILD/unsigned.apk"

# 3) javac (MainActivity + R)
find "$BUILD/gen" -name "*.java" > "$BUILD/sources.txt"
echo "$DIR/MainActivity.java" >> "$BUILD/sources.txt"
"$JAVA/javac" -source 1.8 -target 1.8 -nowarn -cp "$PLAT" -d "$BUILD/classes" @"$BUILD/sources.txt"

# 4) dexear
"$BT/d8" --release --lib "$PLAT" --min-api 24 --output "$BUILD/dex" $(find "$BUILD/classes" -name "*.class") >/dev/null

# 5) meter classes.dex en el APK
cd "$BUILD/dex" && zip -q -u "$BUILD/unsigned.apk" classes.dex

# 6) alinear
"$BT/zipalign" -f 4 "$BUILD/unsigned.apk" "$BUILD/aligned.apk"

# 7) firmar (keystore autogenerada la primera vez)
if [ ! -f "$BUILD/crowdrunner.jks" ]; then
  "$JAVA/keytool" -genkeypair -keystore "$BUILD/crowdrunner.jks" \
    -storepass android -alias crowd -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Crowd Runner, O=CrisPro, C=ES" >/dev/null 2>&1
fi
"$BT/apksigner" sign --ks "$BUILD/crowdrunner.jks" \
  --ks-key-alias crowd --ks-pass pass:android --key-pass pass:android \
  --out "$OUT" "$BUILD/aligned.apk"

# 8) verificar
"$BT/apksigner" verify "$OUT" && echo "✔ firma válida"
echo "✔ APK generada: $OUT ($(du -h "$OUT" | cut -f1))"
