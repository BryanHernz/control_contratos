; Instalador de Control de Contratos para Windows.
;
; Se compila con `tool/empaquetar_windows.sh`, que le pasa la version leida del
; pubspec. No editar el numero aqui.
;
;   ISCC.exe /DVersionApp=1.0.4 windows\installer\control_contratos.iss

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

[Icons]
Name: "{group}\{#NombreApp}"; Filename: "{app}\{#Ejecutable}"
Name: "{group}\Desinstalar {#NombreApp}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#NombreApp}"; Filename: "{app}\{#Ejecutable}"; Tasks: escritorio

[Run]
Filename: "{app}\{#Ejecutable}"; Description: "Abrir {#NombreApp}"; Flags: nowait postinstall skipifsilent
