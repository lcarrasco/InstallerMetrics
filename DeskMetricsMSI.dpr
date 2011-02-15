{ **********************************************************}
{                                                           }
{     DeskMetrics MSI Custom Action Library                 }
{     Copyright (c) 2010-2011                               }
{     www.deskmetrics.com                                   }
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

library DeskMetricsMSI;

uses
  Windows,
  SysUtils,
  Registry,
  WinInet,
  JwaMsi,
  JwaMsiQuery,
  JwaMSIDefs,
  dskMetricsConsts in '..\componentDelphi\DLL\dskMetricsConsts.pas';

{$R *.res}

var
  FApplicationID: AnsiString = '';
  FApplicationVersion: AnsiString = 'null';

  FPostServer: string;
  FPostPort: Integer;
  FPostTimeOut: Integer;
  FPostAgent: string;
  FPostWaitResponse: Boolean;


{ Helper functions }
//-----------------------------------------------------------------------//

{ GUID }
function _GenerateGUID: string;
var
  FGUIDString: string;
  FGUID: TGUID;
begin
  try
    CreateGUID(FGUID);
    FGUIDString := GUIDToString(FGUID);

    Result      := StringReplace(FGUIDString, '{', '', [rfReplaceAll, rfIgnoreCase]);
    Result      := StringReplace(Result, '}', '', [rfReplaceAll, rfIgnoreCase]);
    Result      := StringReplace(Result, '-', '', [rfReplaceAll, rfIgnoreCase]);
    Result      := Trim(Result);
  except
    Result := '00000000000000000000000000000000';
  end;
end;

{ User ID }
function _UserIDExists: Boolean;
var
  FRegistry: TRegistry;
begin
  Result := False;
  try
    FRegistry := TRegistry.Create;
    try
      FRegistry.RootKey := REGROOTKEY;
      if FRegistry.OpenKey(REGPATH, True) then
      begin
        Result := FRegistry.ValueExists('ID');
        if Result then
          Result := FRegistry.ReadString('ID') <> '';
      end;
    finally
      FreeAndNil(FRegistry);
    end;
  except
    Result := False;
  end;
end;

function _GenerateUserID: string;
begin
  try
    Result := _GenerateGUID;
  except
    Result := '';
  end;
end;

function _SaveUserIDReg(const FUserID: string): Boolean;
var
  FRegistry: TRegistry;
begin
  Result := False;
  try
    FRegistry := TRegistry.Create;
    try
      FRegistry.RootKey := REGROOTKEY;
      if FRegistry.OpenKey(REGPATH, True) then
        FRegistry.WriteString('ID', FUserID);
    finally
      FreeAndNil(FRegistry);
    end;
  except
    Result := False;
  end;
end;

function _LoadUserIDReg: string;
var
  FRegistry: TRegistry;
begin
  Result := '';
  try
    FRegistry := TRegistry.Create;
    try
      FRegistry.RootKey := REGROOTKEY;
      if FRegistry.OpenKey(REGPATH, True) then
      begin
        if FRegistry.ValueExists('ID') then;
          Result := FRegistry.ReadString('ID');
      end;
    finally
      FreeAndNil(FRegistry);
    end;
  except
    Result := '';
  end;
end;

function _GetUserID: string;
begin
  try
    Result := '';
    if _UserIDExists = False then
    begin
      Result := Trim(_GenerateUserID);
      _SaveUserIDReg(Result);
    end
    else
      Result := Trim(_LoadUserIDReg);
  except
    Result := '';
  end;
end;

{ TimeStamp }
function _GetTimeStamp: string;
const
  UnixStartDate: TDateTime = 25569.0;
begin
  try
    Result := Trim(IntToStr(Round((Now - UnixStartDate) * 86400)));
  except
    Result := NULL_STR;
  end;
end;

{ URL Encode }
function _URLEncode(const FText: string): string;
var
  I: Integer;
  Ch: Char;
begin
  try
    for I := 1 to Length(FText) do
    begin
        Ch := FText[I];
        if ((Ch >= '0') and (Ch <= '9')) or
           ((Ch >= 'a') and (Ch <= 'z')) or
           ((Ch >= 'A') and (Ch <= 'Z')) or
           (Ch = '.') or (Ch = '-') or (Ch = '_') or (Ch = '~') then
            Result := Result + Ch
        else
          Result := Result + '%' +  SysUtils.IntToHex(Ord(Ch), 2);
    end;
  except
    Result := '';
  end;
end;

{ HTTP Post }
function _SendPost(const FJSON: string): Integer;
var
  FResult: string;
  FJSONTemp: string;
  hint,hconn,hreq:hinternet;
  hdr: AnsiString;
  buf:array[0..READBUFFERSIZE-1] of ansichar;
  bufsize:dword;
  i,flags:integer;
  data: AnsiString;
  dwSize, dwFlags: DWORD;
begin
  Result  := 0;
  try
    FJSONTemp := FJSON;
    hdr       := 'Content-Type: application/x-www-form-urlencoded';
    FJSONTemp := '[' + FJSONTemp + ']';
    data      := AnsiString('data=' + _URLEncode(FJSONTemp));

    hint := InternetOpenW(PChar(FPostAgent),INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
    if hint = nil then
    begin
      Result := 2;
      Exit;
    end;

    try
      { Set HTTP request timeout }
      if FPostTimeOut > 0 then
      begin
        InternetSetOption(hint, INTERNET_OPTION_CONNECT_TIMEOUT, @FPostTimeOut, SizeOf(FPostTimeOut));
        InternetSetOption(hint, INTERNET_OPTION_SEND_TIMEOUT,    @FPostTimeOut, SizeOf(FPostTimeOut));
        InternetSetOption(hint, INTERNET_OPTION_RECEIVE_TIMEOUT, @FPostTimeOut, SizeOf(FPostTimeOut));
      end;

      { Set HTTP port }
      hconn := InternetConnect(hint,PChar(FApplicationID + FPostServer),FPostPort,nil,nil,INTERNET_SERVICE_HTTP,0,1);
      if hconn = nil then
      begin
        Result := 3;
        Exit;
      end;

      try
        if FPostPort = INTERNET_DEFAULT_HTTPS_PORT then
          flags := INTERNET_FLAG_NO_UI or INTERNET_FLAG_SECURE or INTERNET_FLAG_IGNORE_CERT_CN_INVALID or INTERNET_FLAG_IGNORE_CERT_DATE_INVALID
        else
          flags := INTERNET_FLAG_NO_UI;

        hreq := HttpOpenRequest(hconn, 'POST', PChar(API_SENDDATA), nil, nil, nil, flags, 1);
        if Assigned(hreq) and (FPostPort = INTERNET_DEFAULT_HTTPS_PORT) then
        begin
          dwSize := SizeOf(dwFlags);
          if (InternetQueryOption(hreq, INTERNET_OPTION_SECURITY_FLAGS, @dwFlags, dwSize)) then
          begin
            dwFlags := dwFlags or SECURITY_FLAG_IGNORE_UNKNOWN_CA;
            if not (InternetSetOption(hreq, INTERNET_OPTION_SECURITY_FLAGS, @dwFlags, dwSize)) then
              Result := 4;
          end
          else
            Result := 5;  //InternetQueryOption failed
        end;

        if hreq = nil then
        begin
          Result := 2;
          Exit;
        end;

        try
          if HttpSendRequestA(hreq,PAnsiChar(hdr),Length(hdr),PAnsiChar(Data),Length(Data)) then
          begin
            if FPostWaitResponse then
            begin
              { Read server Response }
              bufsize := READBUFFERSIZE;
              while (bufsize > 0) do
              begin
                if not InternetReadFile(hreq,@buf,READBUFFERSIZE,bufsize) then
                begin
                  Result := 7;
                  Break;
                end;

                if (bufsize > 0) and (bufsize <= READBUFFERSIZE) then
                begin
                  for i := 0 to bufsize - 1 do
                    FResult := FResult + string(buf[i]);
                end;
              end;
            end;
          end
          else
            Result := 6;
        finally
          InternetCloseHandle(hreq);
        end;
      finally
        InternetCloseHandle(hconn);
      end;
    finally
      InternetCloseHandle(hint);
    end;
  except
    Result := 5;
  end;
end;

{ Log Message }
procedure LogString(InstallHandle: Integer; FMessage: string);
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

{ Installation / Uninstallation }
function _TrackInstallation: Integer;
var
  FJSONData: string;
begin
  try
    if FApplicationID <> '' then
    begin
      FJSONData := '{"tp":"ist","aver":"' + FApplicationVersion + '","atst":0,"ID":"' + _GetUserID + '","ts":' + _GetTimeStamp + ',"ss":"' + _GenerateGUID + '"}';
      Result    := _SendPost(FJSONData);
    end
    else
      Result := 10;
  except
    Result := -1;
  end;
end;

function _TrackUninstallation: Integer;
var
  FJSONData: string;
begin
  try
    if FApplicationID <> '' then
    begin
      FJSONData := '{"tp":"ust","aver":"' + FApplicationVersion + '","atst":0,"ID":"' + _GetUserID + '","ts":' + _GetTimeStamp + ',"ss":"' + _GenerateGUID + '"}';
      Result    := _SendPost(FJSONData);
    end
    else
      Result := 10;
  except
    Result := -1;
  end;
end;

function _TrackRollback: Integer;
var
  FJSONData: string;
begin
  try
    if FApplicationID <> '' then
    begin
      FJSONData := '{"tp":"rst","aver":"' + FApplicationVersion + '","atst":0,"ID":"' + _GetUserID + '","ts":' + _GetTimeStamp + ',"ss":"' + _GenerateGUID + '"}';
      Result    := _SendPost(FJSONData);
    end
    else
      Result := 10;
  except
    Result := -1;
  end;
end;

{ Debug }
procedure ShowDebugMessage(const title: string);
begin
{$IFDEF DEBUG}
    MessageBoxA(GetDesktopWindow(), PAnsiChar('Debug build. If correctly set up, you can now attach a debugger. Process Id: ' + IntToStr(Windows.GetCurrentProcessId())), PAnsiChar(title), MB_SYSTEMMODAL or MB_OK or MB_ICONINFORMATION);
{$ENDIF}
end;

{ Exported functions }
//------------------------------------------------------------------------//

function DeskMetricsTrackInstallation(const hInstall: Integer): UINT; stdcall;
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
        LogString(hInstall, 'DeskMetricsID = ' + IntToStr(Result));

        Result := MsiGetPropertyA(hInstall, 'ProductVersion', FProductVersion, FProductVersionSize);
        LogString(hInstall, 'ProductVersion = ' + IntToStr(Result));

        { Set variables }
        FApplicationID      := StrPas(FDeskMetricsID);
        FApplicationVersion := StrPas(FProductVersion);

        LogString(hInstall, 'Application ID: ' + FApplicationID);
        LogString(hInstall, 'Application Version: ' + FApplicationVersion);

        { Track Installation }
        case _TrackInstallation of
          0:  LogString(hInstall, 'Installation tracked.');
          10: LogString(hInstall, 'Application ID not found.');
        else
          LogString(hInstall, 'Error! Installation not tracked.')
        end;
      except
        LogString(hInstall, 'Unknown exception');
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

function DeskMetricsTrackUninstallation(const hInstall: Integer): UINT; stdcall;
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
        LogString(hInstall, 'DeskMetricsID = ' + IntToStr(Result));

        Result := MsiGetPropertyA(hInstall, 'ProductVersion', FProductVersion, FProductVersionSize);
        LogString(hInstall, 'ProductVersion = ' + IntToStr(Result));

        { Set variables }
        FApplicationID      := StrPas(FDeskMetricsID);
        FApplicationVersion := StrPas(FProductVersion);

        LogString(hInstall, 'Application ID: ' + FApplicationID);
        LogString(hInstall, 'Application Version: ' + FApplicationVersion);

        { Track Installation }
        case _TrackUninstallation of
          0:  LogString(hInstall, 'Uninstallation tracked.');
          10: LogString(hInstall, 'Application ID not found.');
        else
          LogString(hInstall, 'Error! Uninstallation not tracked.')
        end;
      except
        LogString(hInstall, 'Unknown exception');
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

function DeskMetricsTrackRollback(const hInstall: Integer): UINT; stdcall;
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
         LogString(hInstall, 'DeskMetricsID = ' + IntToStr(Result));

        Result := MsiGetPropertyA(hInstall, 'ProductVersion', FProductVersion, FProductVersionSize);
         LogString(hInstall, 'ProductVersion = ' + IntToStr(Result));

        { Set variables }
        FApplicationID      := StrPas(FDeskMetricsID);
        FApplicationVersion := StrPas(FProductVersion);

        //FApplicationID      := '4c5c6ca7924b8d37e0000001';
        //FApplicationVersion := '1.0';

        LogString(hInstall, 'DeskMetrics App ID: ' + FApplicationID);
        LogString(hInstall, 'DeskMetrics App Version: ' + FApplicationVersion);

        { Track Installation }
        case _TrackRollback of
          0:  LogString(hInstall, 'Rollback tracked.');
          10: LogString(hInstall, 'Application ID not found.');
        else
          LogString(hInstall, 'Error! Rollback not tracked.')
        end;
      except
        LogString(hInstall, 'Unknown exception');
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

exports
  DeskMetricsTrackInstallation,
  DeskMetricsTrackUninstallation,
  DeskMetricsTrackRollback;

begin
  FPostServer       := DEFAULTSERVER;
  FPostPort         := DEFAULTPORT;
  FPostTimeOut      := DEFAULTTIMEOUT;
  FPostAgent        := USERAGENT;
  FPostWaitResponse := False;
end.

