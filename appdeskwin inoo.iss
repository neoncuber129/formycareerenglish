; FormyCareer Windows installer — upgrade-safe (fixed AppId, user data stays outside {app}).
; Version defaults match apps/desktop/pubspec.yaml; override from CLI:
;   ISCC "/DMyAppVersion=1.2.3" "/DMyAppVersionInfo=1.2.3.45" "appdeskwin inoo.iss"
; Or run: .\scripts\package_windows_installer.ps1

#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif
#ifndef MyAppVersionInfo
#define MyAppVersionInfo "1.0.0.1"
#endif

[Setup]
AppId={{A1B2C3D4-E5F6-4789-A012-34567890ABCD}}
AppName=FormyCareer
AppVersion={#MyAppVersion}
AppVerName=FormyCareer {#MyAppVersion}
AppPublisher=FormyCareer
DefaultDirName={autopf}\FormyCareer
DefaultGroupName=FormyCareer
OutputDir=apps\desktop\installer
OutputBaseFilename=FormyCareer_Setup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
DisableDirPage=auto
CloseApplications=yes
RestartApplications=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\desktop.exe
VersionInfoVersion={#MyAppVersionInfo}
VersionInfoCompany=FormyCareer
VersionInfoProductName=FormyCareer

[Files]
Source: "apps\desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\FormyCareer"; Filename: "{app}\desktop.exe"
Name: "{commondesktop}\FormyCareer"; Filename: "{app}\desktop.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\desktop.exe"; Description: "Launch FormyCareer"; Flags: nowait postinstall skipifsilent
