# Pruebas de `firestore.rules`

Casos que se ejecutan contra la API `firebaserules projects.test`. **No tocan
ninguna base de datos ni ningún release**: la API compila las reglas del archivo
que se le manda y evalúa cada caso contra mocks.

## Cómo correrlas

```bash
bash test/rules/run.sh
```

Necesita `gcloud` autenticado con la cuenta que tiene acceso a
`contratos-control`. Si falla con «Python was not found», exporta antes:

```bash
export CLOUDSDK_PYTHON="C:/Users/Bryan/AppData/Local/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python.exe"
```

## Dos cosas que cuestan un rato descubrir

**Usa `curl`, no `Invoke-RestMethod`.** El cmdlet de PowerShell 5.1 se cuelga
indefinidamente con estos cuerpos e ignora su propio `-TimeoutSec`. Con `curl`
la respuesta llega en ~1,5 s.

**Un caso de listado va con ruta de documento, no de colección.** Para probar
`method: "list"` sobre `Usuarios`, la ruta es
`/databases/(default)/documents/Usuarios/cualquiera`, no
`/databases/(default)/documents/Usuarios`. Con la ruta de colección ningún
bloque `match` coincide, la regla nunca se evalúa y el caso «falla» sin haber
probado nada — o peor, un caso que espera `DENY` **pasa por el motivo
equivocado**. La señal para detectarlo es `functionCalls: 0` en el resultado.

## Los archivos

- `casos-documento.json` — lecturas y escrituras de documentos sueltos.
- `casos-listado.json` — consultas de colección (`method: "list"`).

Cada caso lleva un campo `_nombre` que solo sirve para el reporte; el runner lo
quita antes de enviar, porque la API lo rechaza.
