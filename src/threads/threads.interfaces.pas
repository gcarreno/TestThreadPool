unit Threads.Interfaces;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
, Threads.Common
;

type

{ IThread }
  IThread = interface
    ['{5D340B25-31E7-40C3-A5AB-8AFE68AA31C0}']

    procedure Start;
    procedure Resume;
    procedure Terminate;
    function WaitFor: Integer;

  end;

{ IManagerThread }
  IManagerThread = interface(IThread)
    ['{06037478-8DE0-455C-8FDB-01B054E511AE}']

    function GetOnShowStatus: TOnShowStatus;
    procedure SetOnShowStatus(const AValue: TOnShowStatus);
    function GetSleepP: PEventState;
    function GetNextItem(var DataP: PThreadData): boolean;
    procedure AddFile(sFileName: string);
    procedure Log(const AMessage: string);

    property OnShowStatus: TOnShowStatus
      read GetOnShowStatus
      write SetOnShowStatus;

    property SleepP: PEventState
      read GetSleepP;

  end;

{ IWorkerThread }
  IWorkerThread = interface(IThread)
    ['{5621A095-A864-461C-8E1C-9D9E27D90258}']
    function GetId: Integer;
    procedure SetId(const AValue: Integer);

    property Id: Integer
      read GetId
      write SetId;

  end;

implementation

end.

