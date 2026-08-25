#!/usr/bin/env bash
# Publica las semillas generadas por `sembrar_plantillas.dart` en una base.
#
#   dart run tool/sembrar_plantillas.dart      # genera build/semillas/
#   bash  tool/sembrar_plantillas.sh pruebas   # las publica
#
# La base va como argumento y no tiene valor por defecto: escribir en
# `(default)` es escribir en produccion, y eso se escribe entero a mano.
set -euo pipefail

BASE="${1:?Falta la base: pruebas | (default)}"
PROYECTO="contratos-control"
SEMILLAS="build/semillas"

if [ ! -d "$SEMILLAS" ]; then
  echo "No hay semillas. Corre primero: dart run tool/sembrar_plantillas.dart" >&2
  exit 1
fi

if [ -z "${CLOUDSDK_PYTHON:-}" ] && [ -x "$LOCALAPPDATA/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe" ]; then
  export CLOUDSDK_PYTHON="$LOCALAPPDATA/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe"
fi

TOKEN="$(gcloud auth print-access-token)"
# `(default)` lleva parentesis, que hay que escapar en la URL.
BASE_URL="$(printf '%s' "$BASE" | sed 's/(/%28/g; s/)/%29/g')"
API="https://firestore.googleapis.com/v1/projects/$PROYECTO/databases/$BASE_URL/documents"

for archivo in "$SEMILLAS"/*.version.json; do
  tipo="$(basename "$archivo" .version.json)"

  # La version primero: si algo falla, la cabecera no queda apuntando al vacio.
  curl -sS --max-time 60 -X PATCH \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    --data-binary "@$archivo" \
    "$API/Plantillas/$tipo/versiones/v1-inicial" \
    -o /dev/null -w "$tipo  version   HTTP %{http_code}\n"

  curl -sS --max-time 60 -X PATCH \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    --data-binary "@$SEMILLAS/$tipo.cabecera.json" \
    "$API/Plantillas/$tipo?updateMask.fieldPaths=tipo&updateMask.fieldPaths=versionActual&updateMask.fieldPaths=ultimoNumero" \
    -o /dev/null -w "$tipo  cabecera  HTTP %{http_code}\n"
done
