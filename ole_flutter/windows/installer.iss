; Inno Setup 6 安装脚本 — OLE 影视
; 通过 ISCC.exe 编译，CI 里这样调用：
;   iscc.exe /DBuildDir=<path> /DOutDir=<path> installer.iss

#ifndef BuildDir
  #define BuildDir "..\build\windows\x64\runner\Release"
#endif
#ifndef OutDir
  #define OutDir "."
#endif
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define AppName     "OLE 影视"
#define AppPublisher "Barry"
#define AppExeName  "ole_flutter.exe"

[Setup]
AppId={{B6F4E2A5-6FE1-4D5C-9F8E-7E0D31F4A111}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/fastcode555/ole
DefaultDirName={autopf}\OLE
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/ultra64
SolidCompression=yes
OutputDir={#OutDir}
OutputBaseFilename=ole_flutter-windows-setup
SetupIconFile=runner\resources\app_icon.ico
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DisableProgramGroupPage=yes
DisableDirPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; 把 flutter build 的整个 Release 目录递归拷过去
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}";       Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName} now"; Flags: nowait postinstall skipifsilent
