unit Threads.InterfacedThread;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
, Threads.Interfaces
, Logger.Common
;

type

{ TInterfacedThread }
  TInterfacedThread = class(TThread, IThread)
  protected
    FRefCount : longint;
    FDestroyCount : longint;

    function QueryInterface(
      {$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} iid : tguid;out obj
    ) : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _AddRef : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};

  public
    constructor Create(const CreateSuspended: Boolean); reintroduce;
    destructor Destroy; override;

  end;
  TInterfacedThreadClass = class of TInterfacedThread;

implementation
{ TInterfacedThread }

function TInterfacedThread.QueryInterface(
  {$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} iid : tguid;out obj
) : longint;{$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  {sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'QueryInterface');
  evlMain.Debug(sLogMessage);}
  if getinterface(iid,obj) then
    Result:= S_OK
  else
    Result:= longint(E_NOINTERFACE);
end;

function TInterfacedThread._AddRef: longint;
  {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result:= interlockedincrement(FRefCount);
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('_AddRef %d', [ Result ])
  );
  evlMain.Debug(sLogMessage);
end;

function TInterfacedThread._Release: longint;
  {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  Result:=interlockeddecrement(FRefCount);
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('_Release %d', [ Result ])
  );
  evlMain.Debug(sLogMessage);
  if Result = 0 then
    begin
      sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
        Format('_Release Destroy %d', [ FDestroyCount ])
      );
      evlMain.Debug(sLogMessage);
      if interlockedincrement(FDestroyCount)=1 then
        Self.destroy;
    end;
end;

constructor TInterfacedThread.Create(const CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
end;

destructor TInterfacedThread.Destroy;
begin
  inherited Destroy;
end;

end.

