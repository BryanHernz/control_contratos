#!/usr/bin/env bash
# Compila la app para Windows y arma el instalador.
#
#   bash tool/empaquetar_windows.sh
#
# Deja el resultado en build/windows/installer/control-contratos-<version>-setup.exe
#
# No publica nada. Subirlo al canal de actualizaciones es un paso aparte y a
# mano, igual que con el APK: ver `control-contratos-despliegue` en las notas.
set -euo pipefail

cd "$(dirname "$0")/.."

# ---------------------------------------------------------------- version
# Sale del pubspec y de ningun otro lado. En Windows el numero termina en el
# recurso de version del .exe, que es lo que lee `PackageInfo` para decidir si
# hay actualizacion; escribirlo a mano en dos partes es como se rompio esto en
# Android.
VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | tr -d '\r')"
VERSION_CORTA="${VERSION%%+*}"
echo "Version: $VERSION  (instalador: $VERSION_CORTA)"

# ---------------------------------------------------------------- ISCC
ISCC=""
for ruta in \
  "$LOCALAPPDATA/Programs/Inno Setup 6/ISCC.exe" \
  "/c/Program Files (x86)/Inno Setup 6/ISCC.exe" \
  "/c/Program Files/Inno Setup 6/ISCC.exe" ; do
  if [ -x "$ruta" ]; then ISCC="$ruta"; break; fi
done
if [ -z "$ISCC" ]; then
  echo "No encuentro ISCC.exe. Instala Inno Setup:" >&2
  echo "  winget install --id JRSoftware.InnoSetup -e" >&2
  exit 1
fi

# ---------------------------------------------------------------- compilar
# El SDK C++ de Firebase trae un `cmake_minimum_required` anterior a 3.5, que
# CMake 4 rechaza. Sin esta variable la configuracion ni siquiera arranca.
export CMAKE_POLICY_VERSION_MINIMUM=3.5

# El bundle se limpia antes: si el binario cambio de nombre alguna vez, el
# ejecutable viejo sigue ahi y el instalador se lo llevaria adentro.
rm -rf build/windows/x64/runner/Release

flutter build windows --release

EXE="build/windows/x64/runner/Release/control_contratos.exe"
if [ ! -f "$EXE" ]; then
  echo "No se genero $EXE" >&2
  exit 1
fi

# ---------------------------------------------------------------- instalador
mkdir -p build/windows/installer
# `MSYS2_ARG_CONV_EXCL` desactiva la conversion de rutas de Git Bash: sin
# esto convierte `/DVersionApp=...` en `C:/Program Files/Git/DVersionApp=...`
# y ISCC cree que le pasaron dos scripts.
MSYS2_ARG_CONV_EXCL="*" "$ISCC" "/DVersionApp=$VERSION_CORTA" windows/installer/control_contratos.iss

SETUP="build/windows/installer/control-contratos-$VERSION_CORTA-setup.exe"
if [ ! -f "$SETUP" ]; then
  echo "El instalador no quedo en $SETUP" >&2
  exit 1
fi

echo
echo "Listo: $SETUP"
ls -lh "$SETUP" | awk '{print "  " $5}'
