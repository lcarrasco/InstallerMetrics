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
  dskMetricsVars in 'dskMetricsVars.pas',
  dskMetricsMSI in 'dskMetricsMSI.pas';

{$R *.res}

function DeskMetricsTrackInstallation(FApplicationID: string; FApplicationVersion: string): Integer; stdcall;
begin
  try
    FAppID              := AnsiString(FApplicationID);
    FAppVersion         := AnsiString(FApplicationVersion);

    Result := _TrackInstallation;
  except
    Result := -1;
  end;
end;

function DeskMetricsTrackUninstallation(FApplicationID: string; FApplicationVersion: string): Integer; stdcall;
begin
  try
    FAppID              := AnsiString(FApplicationID);
    FAppVersion         := AnsiString(FApplicationVersion);

    Result := _TrackUninstallation;
  except
    Result := -1;
  end;
end;

function DeskMetricsMSITrackInstallation(const hInstall: Integer): UINT; stdcall;
begin
  try
    Result := _MSITrackInstallation(hInstall);
  except
    Result := 1607; {ERROR_UNKNOWN_COMPONENT}
  end;
end;


function DeskMetricsMSITrackUninstallation(const hInstall: Integer): UINT; stdcall;
begin
  try
    Result := _MSITrackUninstallation(hInstall);
  except
    Result := 1607; {ERROR_UNKNOWN_COMPONENT}
  end;
end;

exports
  DeskMetricsTrackInstallation,
  DeskMetricsTrackUninstallation,
  DeskMetricsMSITrackInstallation,
  DeskMetricsMSITrackUninstallation;

begin
  FPostServer       := DEFAULTSERVER;
  FPostPort         := DEFAULTPORT;
  FPostTimeOut      := DEFAULTTIMEOUT;
  FPostAgent        := USERAGENT;
  FPostWaitResponse := False;
end.

