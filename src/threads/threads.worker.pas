{
File : Threads.Worker
Description : This unit is an example of how to setup a Thread Manager with Worker Threads in Lazarus / FPC
  For the purposes of this test we'll assume that these worker threads need process input files on a
  device.

Written By : Andrew Thomas Brunner
Copyright Aurawin LLC 2008.

 This code is issued under the Aurawin Public Release License
 http://www.aurawin.com/aprl.html
}

unit Threads.Worker;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
, LazUtils
, Logger.Common
, Threads.Common
, Threads.Interfaces
, Threads.InterfacedThread
;

type

{ TWorkerThread }
  TWorkerThread = class(TInterfacedThread, IWorkerThread)
  private
    FId: integer;
    FManager: IManagerThread;
    FItemP: PThreadData;
    FStatus: TThreadStatus;

    function GetId: Integer;
    procedure SetId(const AValue: Integer);
  protected
    procedure Execute; override;
  protected
    procedure ProcessWorkerItem;
  public
    constructor Create(const aManager: IManagerThread); reintroduce;
    destructor Destroy; override;
  public

    property Id: Integer
      read GetId
      write SetId;

  end;
  TWorkerThreadClass = class of TWorkerThread;

implementation

{ TWorkerThread }

constructor TWorkerThread.Create(const aManager: IManagerThread);
begin
  FManager := aManager;
  FItemP := nil;
  FStatus := tsNone;

  inherited Create(False);
  FreeOnTerminate := False;
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Worker Created');
  evlMain.Debug(sLogMessage);
  FManager.Log(sLogMessage);
end;

destructor TWorkerThread.Destroy;
begin
  FItemP := nil;
  inherited Destroy;
end;

function TWorkerThread.GetId: Integer;
begin
  Result:= FId;
end;


procedure TWorkerThread.SetId(const AValue: Integer);
begin
  if AValue = FId then
    exit;
  FId:= AValue;
end;

procedure TWorkerThread.Execute;
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('[Worker %d] Starting worker thread', [FId])
  );
  evlMain.Debug(sLogMessage);
  //FManager.Log(sLogMessage);
  while not Terminated do
  begin
    if FManager.GetNextItem(FItemP) then
    begin
      FStatus := tsRunning;
      ProcessWorkerItem;
      FStatus := tsIdle;
    end
    else
      FStatus := tsIdle;
    BasicEventWaitFor(WORKER_TIMESLICE, FManager.SleepP);
  end;
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('[Worker %d] Exiting worker thread', [FId])
  );
  evlMain.Debug(sLogMessage);
  //FManager.Log(sLogMessage);
end;

procedure TWorkerThread.ProcessWorkerItem;
var
  FS: TFileStream;
begin
  // This is where we process the file
  if FileExists(FItemP^.FileName) then
  begin
    sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
      Format('[Worker %d] Processing(%d): %s',
        [FId, FItemP^.Id, FItemP^.FileName])
    );
    evlMain.Debug(sLogMessage);
    FManager.Log(sLogMessage);
    FS := TFileStream.Create(FItemP^.FileName, fmOpenRead or fmShareDenyWrite);
    try
      // The file is now loaded as a stream.
      // Process It.
      // And that's it!
    finally
      FreeAndNil(FS);
    end;
  end
  else
  begin
    sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
      Format('File %s does not exist', [FItemP^.FileName])
    );
    evlMain.Debug(sLogMessage);
    FManager.Log(sLogMessage);
  end;
end;

end.
