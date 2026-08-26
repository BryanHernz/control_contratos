; Instalador de Control de Contratos para Windows.
;
; Se compila con `tool/empaquetar_windows.sh`, que le pasa la version leida del
; pubspec. No editar el numero aqui.
;
;   ISCC.exe /DVersionApp=1.0.7 windows\installer\control_contratos.iss

#ifndef VersionApp
  #define VersionApp "0.0.0"
#endif

#define NombreApp "Control de Contratos"
#define Ejecutable "control_contratos.exe"
#define Editor "Agricola Octavio Nunez EIRL"

[Setup]
; El AppId identifica al producto entre versiones. **No se cambia nunca**: si
; cambia, Windows trata la version nueva como otro programa distinto y quedan
; las dos instaladas en paralelo, cada una con su acceso directo.
AppId={{7C3E9A21-5B4D-4F86-9E2A-1D8F0C6B4A73}
AppName={#NombreApp}
AppVersion={#VersionApp}
AppPublisher={#Editor}
VersionInfoVersion={#VersionApp}

; `lowest` instala en la carpeta del usuario y **no pide permisos de
; administrador**. Con `admin` habria que aprobar un cuadro de UAC en cada
; actualizacion, y la app se actualiza sola: pedir eso cada vez es justamente
; lo que hace que la gente deje de actualizar.
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#NombreApp}
DefaultGroupName={#NombreApp}
DisableProgramGroupPage=yes

; Cierra la app si esta abierta. Windows no deja reemplazar un .exe en uso;
; sin esto el instalador fallaria justo en el caso normal, que es actualizar
; desde la propia app.
CloseApplications=yes
RestartApplications=no

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

OutputDir=..\..\build\windows\installer
OutputBaseFilename=control-contratos-{#VersionApp}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=..\runner\resources\app_icon.ico

; Marca del asistente. Las imagenes las genera
; `tool/generar_icono_windows.dart` a partir del mismo icono de la app, sobre
; el degradado de sus cabeceras, para que el instalador se vea como la misma
; pieza de software y no como un asistente generico.
;
; Van varios tamanos: Inno elige segun la escala de pantalla del equipo.
WizardImageFile=imagenes\banner-*.bmp
WizardSmallImageFile=imagenes\cabecera-*.bmp

; El estilo moderno oculta la pagina de bienvenida, que es justo donde se
; muestra el banner grande. Se vuelve a activar: es la primera pantalla que ve
; quien instala.
DisableWelcomePage=no

UninstallDisplayName={#NombreApp}
UninstallDisplayIcon={app}\{#Ejecutable}

[Languages]
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "escritorio"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
; Todo el bundle que produce `flutter build windows --release`: el ejecutable,
; las DLL de Flutter y de Firebase, y la carpeta `data` con los assets.
; Se excluyen `.lib` y `.exp`, que son sobras del enlazador: no hacen falta
; para ejecutar y solo engordan la descarga de cada actualizacion.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.lib,*.exp"; Flags: ignoreversion recursesubdirs createallsubdirs

; El icono tambien como archivo suelto, para que los accesos directos apunten
; a el y no al `.exe`.
;
; Windows cachea el icono POR RUTA, y esa cache sobrevive incluso a desinstalar
; y volver a instalar: el acceso directo del escritorio seguia mostrando el
; logo de Flutter aunque el ejecutable ya tuviera el correcto. Apuntar a una
; ruta que nunca estuvo en la cache la esquiva.
Source: "..\runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#NombreApp}"; Filename: "{app}\{#Ejecutable}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Desinstalar {#NombreApp}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#NombreApp}"; Filename: "{app}\{#Ejecutable}"; IconFilename: "{app}\app_icon.ico"; Tasks: escritorio

[Run]
Filename: "{app}\{#Ejecutable}"; Description: "Abrir {#NombreApp}"; Flags: nowait postinstall skipifsilent
