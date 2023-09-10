{
File : Threads.Common
Description : Header File for units Threads.Manager, Threads.Worker

Written By : Andrew Thomas Brunner
Copyright Aurawin LLC 2008.

 This code is issued under the Aurawin Public Release License
 http://www.aurawin.com/aprl.html
}

unit Threads.Common;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
;

type

  TManagerStatus = (msNone, msIdle, msStop, msStart, msPause);
  TThreadStatus = (tsNone, tsRunning, tsIdle, tsStopped);

  PThreadData = ^TThreadData;
  TOnShowStatus = procedure(const AStatusMessage: string) of object;
  TOnThreadComplete = procedure(DataP: PThreadData) of object;

  TThreadData = record
    ID: integer;
    FileName: string;
    Errors: boolean;
    // Other user defined data here
  end;

  TThreadDataPointers = array of PThreadData;

procedure ClearThreadData(List: TList);
procedure AddThreadData(List: TList; sFileName: string);
procedure Empty(var Item: TThreadData); overload;

const
  WORKER_TIMESLICE = 320; // milliseconds;
  MANAGER_TIMESLICE = 1220; // milliseconds;

implementation

procedure ClearThreadData(List: TList);
var
  iLcv: integer;
  tdDataP: PThreadData;
begin
  for iLcv := 0 to List.Count - 1 do
  begin
    tdDataP := List.Items[iLcv];
    try
      Empty(tdDataP^);
    finally
      Dispose(tdDataP);
    end;
  end;
  List.Clear;
end;

procedure Empty(var Item: TThreadData);
begin
  SetLength(Item.FileName, 0);
  Item.Errors := False;
end;

procedure AddThreadData(List: TList; sFileName: string);
var
  tdDataP: PThreadData;
begin
  New(tdDataP);
  try
    Empty(tdDataP^);
    tdDataP^.FileName := sFileName;
  finally
    tdDataP^.Id := List.Add(tdDataP);
  end;
end;

end.
