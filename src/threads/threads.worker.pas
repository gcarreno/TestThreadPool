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
;

type

{ TWorkerThread }
  TWorkerThread = class(TThread)
  private
    FId: integer;
    FManager: TThread;
    FItemP: PThreadData;
    FStatus: TThreadStatus;
  protected
    procedure Execute; override;
  protected
    procedure ProcessWorkerItem;
  public
    constructor Create(aManager: TThread); reintroduce;
    destructor Destroy; override;
  public
    property Id: integer read FId write FId;
  end;

implementation

uses
  Threads.Manager // This avoids circular unit error
;

{ TWorkerThread }

constructor TWorkerThread.Create(aManager: TThread);
begin
  FManager := aManager;
  FItemP := nil;
  FStatus := tsNone;

  inherited Create(False);
  FreeOnTerminate := False;
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Worker Created');
  evlMain.Debug(sLogMessage);
  TManagerThread(FManager).Log(sLogMessage);
end;

destructor TWorkerThread.Destroy;
begin
  FItemP := nil;
  inherited Destroy;
end;

procedure TWorkerThread.Execute;
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('[Worker %d] Starting worker thread', [FId])
  );
  evlMain.Debug(sLogMessage);
  TManagerThread(FManager).Log(sLogMessage);
  while not Terminated do
  begin
    if TManagerThread(FManager).GetNextItem(FItemP) then
    begin
      FStatus := tsRunning;
      ProcessWorkerItem;
      FStatus := tsIdle;
    end
    else
      FStatus := tsIdle;
    BasicEventWaitFor(WORKER_TIMESLICE, TManagerThread(FManager).SleepP);
  end;
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('[Worker %d] Exiting worker thread', [FId])
  );
  evlMain.Debug(sLogMessage);
  TManagerThread(FManager).Log(sLogMessage);
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
    TManagerThread(FManager).Log(sLogMessage);
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
    TManagerThread(FManager).Log(sLogMessage);
  end;
end;

end.
