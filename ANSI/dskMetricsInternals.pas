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

unit dskMetricsInternals;

interface

function _GenerateGUID: string;

function _UserIDExists: Boolean;
function _GenerateUserID: string;
function _SaveUserIDReg(const FUserID: string): Boolean;
function _LoadUserIDReg: string;
function _GetUserID: string;

function _GetTimeStamp: string;

function _SendPost(const FJSON: string): Integer;

function _TrackInstallation: Integer;
function _TrackUninstallation: Integer;

implementation

uses
  Windows, SysUtils, Registry, WinInet, DateUtils, dskMetricsConsts, dskMetricsVars;

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

function _UserIDExists: Boolean;
var
  FRegistry: TRegistry;
begin
  Result := False;
  try
    FRegistry := TRegistry.Create(KEY_ALL_ACCESS OR KEY_WOW64_32KEY);
    try
      FRegistry.RootKey := REGROOTKEY;
      if FRegistry.OpenKey(REGPATH, True) then
      begin
        if FRegistry.ValueExists('ID') then
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
    FRegistry := TRegistry.Create(KEY_ALL_ACCESS OR KEY_WOW64_32KEY);
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
    FRegistry := TRegistry.Create(KEY_ALL_ACCESS OR KEY_WOW64_32KEY);
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

function _GetTimeStamp: string;
begin
  try
    Result := IntToStr(DateTimeToUnix(Now));
  except
    Result := NULL_STR;
  end;
end;

function _SendPost(const FJSON: string): Integer;
var
  FJSONTemp: string;
  hint,hconn,hreq:hinternet;
  hdr: UTF8String;
  buf:array[0..READBUFFERSIZE-1] of PAnsiChar;
  bufsize:dword;
  i,flags:integer;
  data: UTF8String;
  dwSize, dwFlags: DWORD;
begin
  Result  := 1;
  try
    FJSONTemp := FJSON;

    { check type - WebService API Call }
    hdr       := UTF8Encode('Content-Type: application/json');
    data      := UTF8Encode('[' + FJSONTemp + ']');

    hint := InternetOpenW(PWideChar(FPostAgent),INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
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
      hconn := InternetConnect(hint,PChar(FAppID + FPostServer),FPostPort,nil,nil,INTERNET_SERVICE_HTTP,0,1);
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
          if HttpSendRequestA(hreq,PAnsiChar(hdr),Length(hdr), PAnsiChar(Data),Length(Data)) then
          begin
            if (FPostWaitResponse) then
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
                    Result := 1;
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
    Result := -1;
  end;
end;

function _TrackInstallation: Integer;
var
  FJSONData: string;
begin
  try
    if FAppID <> '' then
    begin
      FJSONData := '{"tp":"ist","aver":"' + FAppVersion + '","ID":"' + _GetUserID + '","ts":' + _GetTimeStamp + ',"ss":"' + _GenerateGUID + '"}';
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
    if FAppID <> '' then
    begin
      FJSONData := '{"tp":"ust","aver":"' + FAppVersion + '","ID":"' + _GetUserID + '","ts":' + _GetTimeStamp + ',"ss":"' + _GenerateGUID + '"}';
      Result    := _SendPost(FJSONData);
    end
    else
      Result := 10;
  except
    Result := -1;
  end;
end;


end.
