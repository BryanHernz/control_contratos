#!/usr/bin/env bash
# Corre los casos de test/rules/*.json contra firestore.rules usando la API
# firebaserules projects.test. No toca ninguna base ni ningun release.
set -euo pipefail

PROJECT="contratos-control"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES="$ROOT/firestore.rules"
CASOS_DIR="$ROOT/test/rules"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# gcloud en Windows necesita que se le diga con que Python arrancar.
if [ -z "${CLOUDSDK_PYTHON:-}" ] && [ -x "$LOCALAPPDATA/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe" ]; then
  export CLOUDSDK_PYTHON="$LOCALAPPDATA/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe"
fi

PYBIN="${CLOUDSDK_PYTHON:-python}"

echo "Obteniendo token..."
TOKEN="$(gcloud auth print-access-token)"

"$PYBIN" - "$RULES" "$CASOS_DIR" "$TMP/body.json" "$TMP/nombres.txt" <<'PY'
import json, sys, glob, os
rules, casos_dir, out_body, out_nombres = sys.argv[1:5]

casos = []
for f in sorted(glob.glob(os.path.join(casos_dir, "casos-*.json"))):
    with open(f, encoding="utf-8") as fh:
        casos.extend(json.load(fh))

nombres = [c.pop("_nombre", "(sin nombre)") for c in casos]

body = {
    "source": {"files": [{"name": "firestore.rules",
                          "content": open(rules, encoding="utf-8").read()}]},
    "testSuite": {"testCases": casos},
}
with open(out_body, "w", encoding="utf-8") as fh:
    json.dump(body, fh)
with open(out_nombres, "w", encoding="utf-8") as fh:
    fh.write("\n".join(nombres))
print(f"{len(casos)} casos preparados")
PY

curl -sS --max-time 90 -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: $PROJECT" \
  --data-binary "@$TMP/body.json" \
  "https://firebaserules.googleapis.com/v1/projects/$PROJECT:test" \
  -o "$TMP/result.json"

"$PYBIN" - "$TMP/result.json" "$TMP/nombres.txt" <<'PY'
import json, sys
res = json.load(open(sys.argv[1], encoding="utf-8"))
nombres = open(sys.argv[2], encoding="utf-8").read().split("\n")

if res.get("issues"):
    print("ERRORES DE COMPILACION:")
    for i in res["issues"]:
        pos = i.get("sourcePosition", {})
        print(f"  L{pos.get('line')}: {i.get('severity')} {i.get('description')}")
    sys.exit(1)

ok = bad = 0
for i, r in enumerate(res.get("testResults", [])):
    nombre = nombres[i] if i < len(nombres) else f"caso {i}"
    if r.get("state") == "SUCCESS":
        ok += 1
        print(f"  PASA   {nombre}")
    else:
        bad += 1
        print(f"  FALLA  {nombre}")
        # functionCalls == 0 casi siempre significa que ningun `match` coincidio
        # con la ruta del caso, no que la regla haya negado el acceso.
        if not r.get("functionCalls"):
            print("           (functionCalls: 0 - revisa la ruta del caso)")

print()
print(f"PASA: {ok}  /  FALLA: {bad}  /  TOTAL: {ok + bad}")
sys.exit(1 if bad else 0)
PY
