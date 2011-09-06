{ **********************************************************}
{                                                           }
{     DeskMetrics Installer Library                         }
{     Copyright (c) 2011                                    }
{     http://deskmetrics.com                                }
{                                                           }
{     The entire contents of this file is protected by      }
{     International Copyright Laws. Unauthorized            }
{     reproduction, reverse-engineering, and distribution   }
{     of all or any portion of the code contained in this   }
{     file is strictly prohibited and may result in severe  }
{     civil and criminal penalties and will be prosecuted   }
{     to the maximum extent possible under the law.         }
{                                                           }
{ **********************************************************}

library DeskMetricsInstaller;

uses
  Windows,
  dskMetricsConsts in 'dskMetricsConsts.pas',
  dskMetricsInternals in 'dskMetricsInternals.pas',
  dskMetricsVars in 'dskMetricsVars.pas';

function DeskMetricsTrackInstallation(FApplicationID: PChar; FApplicationVersion: PChar; BackupServer: PChar; BackupServerPort: Integer): Integer; stdcall;
begin
  try
    FAppID              := AnsiString(FApplicationID);
    FAppVersion         := AnsiString(FApplicationVersion);
    FBackupServer       := AnsiString(BackupServer);
    FBackupServerPort   := BackupServerPort;

    Result := _TrackInstallation;
  except
    Result := -1;
  end;
end;

function DeskMetricsTrackUninstallation(FApplicationID: PChar; FApplicationVersion: PChar; BackupServer: PChar; BackupServerPort: Integer): Integer; stdcall;
begin
  try
    FAppID              := AnsiString(FApplicationID);
    FAppVersion         := AnsiString(FApplicationVersion);
    FBackupServer       := AnsiString(BackupServer);
    FBackupServerPort   := BackupServerPort;

    Result := _TrackUninstallation;
  except
    Result := -1;
  end;
end;

exports
  DeskMetricsTrackInstallation,
  DeskMetricsTrackUninstallation;

begin
  FPostServer       := DEFAULTSERVER;
  FPostPort         := DEFAULTPORT;
  FPostTimeOut      := DEFAULTTIMEOUT;
  FPostAgent        := USERAGENT;
  FPostWaitResponse := False;
end.


