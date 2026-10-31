; Inno Setup Installer Script for nlpa2
; Compile this script using Inno Setup Compiler (ISCC.exe)

#define AppName "NekokoLPA 2"
#define AppShortName "nlpa2"
#define AppPublisher "ee.nekoko"
#define AppURL "https://github.com/iebb/NekokoLPA2"
#define AppExeName "nlpa2.exe"

; Version information - will be updated by build script
#ifndef AppVersion
#define AppVersion "2.0.0"
#endif

#ifndef AppBuildNumber
#define AppBuildNumber "27"
#endif
#define AppVersionFull AppVersion + "." + AppBuildNumber

[Setup]
; App information
AppId={{5D6D4A8F-0B1F-4B8B-BD7B-8D7F9C9B5C2A}
AppName={#AppName}
AppVersion={#AppVersionFull}
AppVerName={#AppName} {#AppVersionFull}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\NekokoLPA2
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=..\build\windows\installer
OutputBaseFilename=ee.nekoko.nlpa2.windows-{#AppVersion}-{#AppBuildNumber}-setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

; Version info for Windows
VersionInfoVersion={#AppVersionFull}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersionFull}
VersionInfoCopyright=Copyright (C) 2026 {#AppPublisher}. All rights reserved.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main executable and runtime files
Source: "..\build\windows\x64\runner\Release\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  // Check if .NET Framework or other prerequisites are needed
  // Add checks here if required
end;
