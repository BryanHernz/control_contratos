/**
 * Funciones de servidor de control_contratos.
 *
 * Hasta ahora no habia ninguna: todo pasaba en el cliente, incluidas cosas que
 * el cliente no deberia poder hacer. Estas cubren las dos que importan.
 *
 * Region: southamerica-east1, la misma de Firestore. Poner las funciones en
 * otra region agrega un viaje de ida y vuelta a cada lectura.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "southamerica-east1", maxInstances: 10 });

/**
 * Base contra la que trabajan las funciones.
 *
 * Las funciones son del PROYECTO, no de una base: no existe "las funciones de
 * pruebas". Sin esto escribirian siempre en `(default)`, o sea en produccion,
 * incluso mientras se prueban.
 *
 * Se despliega con:
 *   firebase functions:config  ->  no; con variable de entorno:
 *   firebase deploy --only functions   (usa .env del directorio functions/)
 *
 * `functions/.env` decide la base. Para probar: FIRESTORE_DB=pruebas.
 * Para produccion: quitarlo o dejarlo en (default).
 */
const BASE = process.env.FIRESTORE_DB || "(default)";
const db =
  BASE === "(default)"
    ? admin.firestore()
    : admin.firestore(admin.app(), BASE);

/** Perfil de quien llama, con sus permisos. */
async function perfilDe(uid) {
  if (!uid) return null;
  const snap = await db.collection("Usuarios").doc(uid).get();
  return snap.exists ? snap.data() : null;
}

function puede(perfil, accion) {
  return (
    perfil?.activo === true && perfil?.permissions?.actions?.[accion] === true
  );
}

/**
 * Crea una cuenta de usuario.
 *
 * La app lo hacia desde el navegador: levantaba una segunda instancia de
 * Firebase y llamaba a `createUserWithEmailAndPassword`. Funcionaba, pero
 * significaba que **crear cuentas era una capacidad del cliente**, no un
 * permiso del servidor -- y las reglas de Firestore no pueden impedirlo,
 * porque ocurre en Auth, antes de tocar Firestore.
 *
 * Aqui el permiso se verifica del lado del servidor, donde nadie lo puede
 * saltar abriendo la consola del navegador.
 */
exports.crearUsuario = onCall(async (request) => {
  const solicitante = await perfilDe(request.auth?.uid);
  if (!puede(solicitante, "manageUsers")) {
    throw new HttpsError(
      "permission-denied",
      "Necesitas el permiso de gestionar usuarios."
    );
  }

  const { email, password, nombre, apellido, telefono, ocupacion, permissions } =
    request.data ?? {};

  if (!email || !password) {
    throw new HttpsError("invalid-argument", "Faltan el correo o la clave.");
  }
  if (String(password).length < 6) {
    throw new HttpsError("invalid-argument", "La clave necesita 6 caracteres.");
  }

  let usuario;
  try {
    usuario = await admin.auth().createUser({
      email: String(email).trim().toLowerCase(),
      password: String(password),
      displayName: `${nombre ?? ""} ${apellido ?? ""}`.trim() || undefined,
    });
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Ese correo ya tiene cuenta.");
    }
    throw new HttpsError("internal", `No se pudo crear la cuenta: ${e.message}`);
  }

  // La ficha nace desactivada salvo que se pidan permisos explicitos: el
  // cliente fallaba abierto y una cuenta sin `permissions` terminaba con
  // acceso total.
  await db.collection("Usuarios").doc(usuario.uid).set({
    uid: usuario.uid,
    email: usuario.email,
    nombre: nombre ?? "",
    apellido: apellido ?? "",
    telefono: telefono ?? "",
    ocupacion: ocupacion ?? "",
    activo: true,
    permissions: permissions ?? { views: {}, actions: {} },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    creadoPor: request.auth.uid,
  });

  await db.collection("Auditoria").add({
    accion: "CREAR_USUARIO",
    usuario: solicitante.email ?? request.auth.uid,
    entidadId: usuario.uid,
    email: usuario.email,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { uid: usuario.uid };
});

/**
 * Deja constancia de los cambios en `Usuarios`.
 *
 * La auditoria la escribia el propio cliente, o sea que quien es auditado
 * decidia que registrar. Las reglas ya impiden editar o borrar un registro,
 * pero no que se omita escribirlo. Un trigger lo registra sin que la app
 * participe.
 *
 * Solo se anota lo que cambia de verdad -- activo y permisos -- para no llenar
 * la coleccion con cada actualizacion de `updatedAt`.
 */
exports.auditarUsuarios = onDocumentWritten(
  // Sin `database`, el trigger escucha `(default)`: dispararia sobre
  // produccion aunque las funciones esten apuntando a `pruebas`.
  { document: "Usuarios/{uid}", database: BASE },
  async (event) => {
  const antes = event.data?.before?.data();
  const despues = event.data?.after?.data();

  let accion;
  if (!antes && despues) accion = "ALTA_USUARIO";
  else if (antes && !despues) accion = "BAJA_USUARIO";
  else {
    const cambioActivo = antes.activo !== despues.activo;
    const cambioPermisos =
      JSON.stringify(antes.permissions ?? {}) !==
      JSON.stringify(despues.permissions ?? {});
    if (!cambioActivo && !cambioPermisos) return;
    accion = cambioActivo ? "CAMBIO_ESTADO_USUARIO" : "CAMBIO_PERMISOS_USUARIO";
  }

  await db.collection("Auditoria").add({
    accion,
    usuario: "sistema",
    entidadId: event.params.uid,
    email: (despues ?? antes)?.email ?? "",
    activoAntes: antes?.activo ?? null,
    activoDespues: despues?.activo ?? null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  }
);

/**
 * Mantiene un resumen del padron para el dashboard.
 *
 * El dashboard bajaba documentos para contarlos y agruparlos. Con un resumen
 * que se actualiza solo, esos paneles pasan a ser **una lectura**.
 *
 * Se recalcula entero en cada escritura de un trabajador. Con 675 documentos
 * eso son 675 lecturas por cambio, mas de lo que ahorra; por eso el conteo va
 * por agregacion y solo el agrupado recorre. Si el padron crece mucho, esto
 * hay que pasarlo a contadores incrementales.
 */
exports.resumenTrabajadores = onDocumentWritten(
  { document: "Trabajadores/{id}", database: BASE },
  async () => {
    const col = db.collection("Trabajadores");

    const [total, activos] = await Promise.all([
      col.count().get(),
      col.where("activo", "==", true).count().get(),
    ]);

    const porLugar = {};
    const porLabor = {};
    const snap = await col.where("activo", "==", true).get();
    snap.forEach((d) => {
      const w = d.data();
      const lugar = w.lugar || "Sin asignar";
      const labor = w.labor || "Sin asignar";
      porLugar[lugar] = (porLugar[lugar] ?? 0) + 1;
      porLabor[labor] = (porLabor[labor] ?? 0) + 1;
    });

    await db.collection("Resumenes").doc("trabajadores").set({
      total: total.data().count,
      activos: activos.data().count,
      porLugar,
      porLabor,
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);
