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

unit dskMetricsMSI;

interface

uses
  Windows, SysUtils;

procedure _MSILogString(InstallHandle: Integer; FMessage: string);

function _MSITrackInstallation(const hInstall: Integer): UINT;
function _MSITrackUninstallation(const hInstall: Integer): UINT;

implementation

uses
  dskMetricsInternals, dskMetricsVars, JwaMsi, JwaMsiQuery;

procedure _MSILogString(InstallHandle: Integer; FMessage: string);
var
  FRecordHandle : Integer;
begin
  if Length(FMessage) = 0 then
    Exit;

  FRecordHandle := MsiCreateRecord(2);
  try
    MsiRecordSetStringW(FRecordHandle, 0, PChar('DeskMetrics - ' + FMessage));
    MsiProcessMessage(InstallHandle, INSTALLMESSAGE(INSTALLMESSAGE_INFO), FRecordHandle);
  finally
    MsiCloseHandle(FRecordHandle);
  end;
end;

function _MSITrackInstallation(const hInstall: Integer): UINT;
var
  FProductVersion: PAnsiChar;
  FProductVersionSize: Cardinal;
  FDeskMetricsID:  PAnsiChar;
  FDeskMetricsIDSize: Cardinal;
begin
  try
    try
      FDeskMetricsID        := AnsiStrAlloc(MAX_PATH);
      FDeskMetricsIDSize    := MAX_PATH;

      FProductVersion       := AnsiStrAlloc(MAX_PATH);
      FProductVersionSize   := MAX_PATH;
      try
        { Retrieve the application data }
        Result := MsiGetPropertyA(hInstall, 'DeskMetricsID',  FDeskMetricsID, FDeskMetricsIDSize);
        _MSILogString(hInstall, 'DeskMetricsID = ' + IntToStr(Result));

        Result := MsiGetPropertyA(hInstall, 'ProductVersion', FProductVersion, FProductVersionSize);
        _MSILogString(hInstall, 'ProductVersion = ' + IntToStr(Result));

        { Set variables }
        FAppID      := StrPas(FDeskMetricsID);
        FAppVersion := StrPas(FProductVersion);

        _MSILogString(hInstall, 'Application ID: ' + FAppID);
        _MSILogString(hInstall, 'Application Version: ' + FAppVersion);

        { Track Installation }
        case _TrackInstallation of
          0:  _MSILogString(hInstall, 'Installation tracked.');
          10: _MSILogString(hInstall, 'Application ID not found.');
        else
          _MSILogString(hInstall, 'Error! Installation not tracked.')
        end;
      except
        _MSILogString(hInstall, 'Unknown exception');
      end;

      Result := ERROR_SUCCESS;

    finally
      StrDispose(FDeskMetricsID);
      StrDispose(FProductVersion);
    end;
    Result := ERROR_SUCCESS;
  except
    Result := ERROR_UNKNOWN_COMPONENT;
  end;
end;

function _MSITrackUninstallation(const hInstall: Integer): UINT;
var
  FProductVersion: PAnsiChar;
  FProductVersionSize: Cardinal;
  FDeskMetricsID:  PAnsiChar;
  FDeskMetricsIDSize: Cardinal;
begin
  try
    try
      FDeskMetricsID        := AnsiStrAlloc(MAX_PATH);
      FDeskMetricsIDSize    := MAX_PATH;

      FProductVersion       := AnsiStrAlloc(MAX_PATH);
      FProductVersionSize   := MAX_PATH;
      try
        { Retrieve the application data }
        Result := MsiGetPropertyA(hInstall, 'DeskMetricsID',  FDeskMetricsID, FDeskMetricsIDSize);
        _MSILogString(hInstall, 'DeskMetricsID = ' + IntToStr(Result));

        Result := MsiGetPropertyA(hInstall, 'ProductVersion', FProductVersion, FProductVersionSize);
        _MSILogString(hInstall, 'ProductVersion = ' + IntToStr(Result));

        { Set variables }
        FAppID      := StrPas(FDeskMetricsID);
        FAppVersion := StrPas(FProductVersion);

        _MSILogString(hInstall, 'Application ID: ' + FAppID);
        _MSILogString(hInstall, 'Application Version: ' + FAppVersion);

        { Track Installation }
        case _TrackUninstallation of
          0:  _MSILogString(hInstall, 'Uninstallation tracked.');
          10: _MSILogString(hInstall, 'Application ID not found.');
        else
          _MSILogString(hInstall, 'Error! Uninstallation not tracked.')
        end;
      except
        _MSILogString(hInstall, 'Unknown exception');
      end;

      Result := ERROR_SUCCESS;
    finally
      StrDispose(FDeskMetricsID);
      StrDispose(FProductVersion);
    end;
    Result := ERROR_SUCCESS;
  finally
    Result := ERROR_UNKNOWN_COMPONENT;
  end;
end;


end.
