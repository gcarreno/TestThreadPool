{
File : Threads.Manager
Description : This unit is an example of how to setup a Thread Manager with Worker Threads in Lazarus / FPC
  For the purposes of this test we'll assume that these worker threads need process input files on a
  device.

Written By : Andrew Thomas Brunner
Copyright Aurawin LLC 2008.

 This code is issued under the Aurawin Public Release License
 http://www.aurawin.com/aprl.html
}

unit Threads.Manager;

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
, Threads.Worker
;

type

  { TManagerThread }
  TManagerThread = class(TInterfacedThread, IManagerThread)
  private
    FSleepP: PEventState;
    FLock: TRTLCriticalSection;
  private
    // This one is used by application thread to allow re-entrant adds
    FAddList: TList;  // List of items to add to queue.
    // This one is used to queue up items
    FQueueList: TList;  // List of items in queue.
    // This one is used to store items being processes
    FProcessingList: TList;
    // This one is used to store items processed
    FCompleteList: TList;  // List of items completed.
    // This list is used to store Pointers to Thread Objects (Start/Stop/Pause/Resume
    FThreadList: TInterfaceList;  // List of Threads created in system.
    // The string to convey status
    FStatusMessage: string;
    // Event to send status message
    FOnShowStatus: TOnShowStatus;

    function GetOnShowStatus: TOnShowStatus;
    procedure SetOnShowStatus(const AValue: TOnShowStatus);

    function GetSleepP: PEventState;
  private
    FStatus: TManagerStatus;
  private
    procedure Clear;
    procedure SetSize(Size: byte);
    procedure ShowStatus;
  protected
    procedure Execute; override;
  protected
    procedure ProcessAddList;
  public
    constructor Create(
      aNumberOfWorkerThreads: byte;
      const aOnShowStatus: TOnShowStatus
    ); reintroduce;
    destructor Destroy; override;
  public
    function GetNextItem(var DataP: PThreadData): boolean;
    // This is how you "register" a new worker item.
    procedure AddFile(sFileName: string);
  public
    procedure Log(const AMessage: string);

    // Essential Operations that the Main Application can Perform.
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;

  public
    property OnShowStatus: TOnShowStatus
      read GetOnShowStatus
      write SetOnShowStatus;
    property SleepP: PEventState
      read GetSleepP;
  end;
  TManagerThreadClass = class of TManagerThread;

implementation

const
  Event_Item_Number: integer = 1;

function GetNextEventName: string;
begin
  Result := Concat('uThreads.TManagerThread.', IntToStr(Event_Item_Number));
  Inc(Event_Item_Number);
end;

{ TManagerThread }

constructor TManagerThread.Create(
  aNumberOfWorkerThreads: byte;
  const aOnShowStatus: TOnShowStatus
);
begin
  FOnShowStatus := aOnShowStatus;

  FSleepP := BasicEventCreate(nil, False, False, GetNextEventName);

  FStatus := msNone;
  FreeOnTerminate := False;
  InitCriticalSection(FLock);

  FAddList := TList.Create;
  FQueueList := TList.Create;
  FProcessingList := TList.Create;
  FCompleteList := TList.Create;

  FThreadList := TInterfaceList.Create;

  inherited Create(False);

  SetSize(aNumberOfWorkerThreads);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Manager Created');
  evlMain.Debug(sLogMessage);
  Log(sLogMessage);
end;

destructor TManagerThread.Destroy;
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Stopping');
  evlMain.Debug(sLogMessage);
  Stop;

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Clearing');
  evlMain.Debug(sLogMessage);
  Clear;

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Terminating');
  evlMain.Debug(sLogMessage);
  Terminate;

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Waiting');
  evlMain.Debug(sLogMessage);
  WaitFor;

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Destroying Sleep Event');
  evlMain.Debug(sLogMessage);
  BasicEventDestroy(FSleepP);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Finalising FLock CS');
  evlMain.Debug(sLogMessage);
  DoneCriticalSection(FLock);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Add List');
  evlMain.Debug(sLogMessage);
  FreeAndNil(FAddList);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Queue List');
  evlMain.Debug(sLogMessage);
  FreeAndNil(FQueueList);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Processing List');
  evlMain.Debug(sLogMessage);
  FreeAndNil(FProcessingList);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Complete List');
  evlMain.Debug(sLogMessage);
  FreeAndNil(FCompleteList);

  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Thread List');
  evlMain.Debug(sLogMessage);
  FThreadList:= nil;

  inherited Destroy;
end;

function TManagerThread.GetOnShowStatus: TOnShowStatus;
begin
  Result:= FOnShowStatus;
end;

procedure TManagerThread.SetOnShowStatus(const AValue: TOnShowStatus);
begin
  if AValue = FOnShowStatus then
    exit;
  FOnShowStatus:= AValue;
end;

function TManagerThread.GetSleepP: PEventState;
begin
  Result:= FSleepP;
end;

procedure TManagerThread.Clear;
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Cleaning items');
  evlMain.Debug(sLogMessage);
  SetSize(0); // <- remove from CriticalSection because "GetNextItem" already blocks CS
  EnterCriticalSection(FLock);
  try
    Threads.Common.ClearThreadData(FAddList);
    Threads.Common.ClearThreadData(FQueueList);
    Threads.Common.ClearThreadData(FProcessingList);
    Threads.Common.ClearThreadData(FCompleteList);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TManagerThread.SetSize(Size: byte);
var
  tdWorker: IWorkerThread;
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('Setting size from %d to %d', [FThreadList.Count, Size])
  );
  evlMain.Debug(sLogMessage);
  Log(sLogMessage);
  if (Size > FThreadList.Count) then
  begin
    // Grow List
    repeat
      tdWorker := TWorkerThread.Create(Self);
      tdWorker.Id := FThreadList.Add(tdWorker);
      sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
        Format('Add worker: %d', [tdWorker.Id])
      );
      evlMain.Debug(sLogMessage);
      Log(sLogMessage);
      //tdWorker:= nil;
    until (Size = FThreadList.Count);
  end
  else if (Size < FThreadList.Count) then
  begin
    // Shrink List
    repeat
      tdWorker := FThreadList.First as IWorkerThread;
      try
        sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
          Format('Terminating worker: %d', [tdWorker.Id])
        );
        evlMain.Debug(sLogMessage);
        Log(sLogMessage);
        tdWorker.Terminate;
        try
          sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
            Format('Waiting for worker: %d', [tdWorker.Id])
          );
          evlMain.Debug(sLogMessage);
          Log(sLogMessage);
          tdWorker.WaitFor;
        finally
          sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
            Format('Removing worker: %d', [tdWorker.Id])
          );
          evlMain.Debug(sLogMessage);
          Log(sLogMessage);
          FThreadList.Remove(tdWorker);
        end;
      finally
        FreeAndNil(tdWorker);
        //tdWorker:= nil;
      end;
    until (FThreadList.Count <= Size);
  end;
end;

procedure TManagerThread.ShowStatus;
begin
  if Assigned(FOnShowStatus) then
  begin
    FOnShowStatus(FStatusMessage);
  end;
end;

procedure TManagerThread.Log(const AMessage: string);
begin
  FStatusMessage := AMessage;
  Synchronize(@ShowStatus);
end;

procedure TManagerThread.AddFile(sFileName: string);
begin
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%},
    Format('Adding file: %s', [sFileName])
  );
  evlMain.Debug(sLogMessage);
  Log(sLogMessage);
  EnterCriticalSection(FLock);
  try
    Threads.Common.AddThreadData(FAddList, sFileName);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TManagerThread.GetNextItem(var DataP: PThreadData): boolean;
begin
  EnterCriticalSection(FLock);
  try
    //sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Getting next item');
    //evlMain.Debug(sLogMessage);
    //Log(sLogMessage);
    if (DataP <> nil) then
    begin
      // You had existing Data.
      // Push Data off to complete Bin before you get next one.
      // The Thread as input is just complete.
      // Add Item to Complete List
      FCompleteList.Add(DataP);
      // Remove Item from Processing List
      FProcessingList.Remove(DataP);
    end;
    // Get Next Item & Remove it from the Queue List
    DataP := FQueueList.First;
    if (DataP <> nil) then
    begin  // If you have data present
      FQueueList.Remove(DataP);
      // Now add it to the Processing List
      FProcessingList.Add(DataP);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
  Result := (DataP <> nil);
end;

procedure TManagerThread.Execute;
begin
  // Generally speaking don't declare variables here.
  // Do all your work in object methods not here.
  // ONLY do simple signal processesing here.
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Starting Manager Execute');
  evlMain.Debug(sLogMessage);
  while not Terminated do
  begin
    ProcessAddList;  // Move Add Items To Queue (If Any)
    BasicEventWaitFor(MANAGER_TIMESLICE, FSleepP); // Give it a rest for a bit...
  end;
  sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Exiting Manager Execute');
  evlMain.Debug(sLogMessage);
end;


procedure TManagerThread.Start;
begin
  inherited Start;
end;

procedure TManagerThread.Stop;
begin

end;

procedure TManagerThread.Pause;
begin
  //inherited Suspend;
end;

procedure TManagerThread.Resume;
begin
  inherited Start;
end;

procedure TManagerThread.ProcessAddList;
var
  tdDataP: PThreadData;
begin
  //sLogMessage:= FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Processing Add List');
  //evlMain.Debug(sLogMessage);
  //Log(sLogMessage);
  EnterCriticalSection(FLock);
  try
    while FAddList.Count > 0 do
    begin
      tdDataP := FAddList.First;
      try
        // Lock Queue List now
        FQueueList.Add(tdDataP);
      finally
        FAddList.Remove(tdDataP);
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

end.
