#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

[Setup]
AppId={{E6F7A9D4-3B2E-4C1A-9F5B-8A1D4E2C7B09}
AppName=Awake
AppVersion={#MyAppVersion}
AppVerName=Awake {#MyAppVersion}
AppPublisher=Othman Shawgan
AppPublisherURL=https://github.com/othman98shawgan/awake
AppSupportURL=https://github.com/othman98shawgan/awake/issues
DefaultDirName={autopf}\Awake
DefaultGroupName=Awake
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
OutputDir=..\..\dist
OutputBaseFilename=Awake-{#MyAppVersion}-Setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\awake.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Awake"; Filename: "{app}\awake.exe"
Name: "{autodesktop}\Awake"; Filename: "{app}\awake.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\awake.exe"; Description: "{cm:LaunchProgram,Awake}"; Flags: nowait postinstall skipifsilent
