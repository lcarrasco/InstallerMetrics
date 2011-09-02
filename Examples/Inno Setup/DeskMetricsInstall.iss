; DeskMetrics Installer
; Support ANSI and Unicode

[Setup]
AppName=My DeskMetrics
AppVersion=1.0
DefaultDirName={pf}\My DeskMetrics
DefaultGroupName=My DeskMetrics
UninstallDisplayIcon={app}\MyProg.exe
Compression=lzma2
SolidCompression=yes
OutputDir=userdocs:Inno Setup Examples Output

[Files]
Source: DeskMetricsInstaller.dll; DestDir: {app}; Flags: ignoreversion

[UninstallDelete]
Name: {app}; Type: filesandordirs

[Code]
const
  FAppID      = 'YOUR APPLICATION ID';
  FAppVersion = '1.0';

function DeskMetricsTrackInstallation(FApplicationID: PChar; FApplicationVersion: PChar): Integer; external 'DeskMetricsTrackInstallation@files:DeskMetricsInstaller.dll stdcall';
function DeskMetricsTrackUninstallation(FApplicationID: PChar; FApplicationVersion: PChar): Integer; external 'DeskMetricsTrackUninstallation@{app}\DeskMetricsInstaller.dll stdcall uninstallonly';

function NextButtonClick(CurPageID: Integer): Boolean;
var
  FStatus: Integer;
begin
  Result := True;

  if CurPageID = wpWelcome then
    FStatus := DeskMetricsTrackInstallation(FAppID, FAppVersion);
end;

procedure InitializeUninstallProgressForm();
begin
  try
    DeskMetricsTrackUninstallation(FAppID, FAppVersion);
    UnloadDLL(ExpandConstant('{app}\DeskMetricsInstaller.dll'));
  except
  end;
end;
