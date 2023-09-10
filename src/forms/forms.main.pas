unit Forms.Main;

{$mode objfpc}{$H+}
interface

uses
  Classes
, SysUtils
, Forms
, Controls
, Graphics
, Dialogs
, ExtCtrls
, StdCtrls
, eventlog
, Logger.Common
, Threads.Interfaces
, Threads.Manager
;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnAddToQueue: TButton;
    edtFileName: TEdit;
    lblFileName: TLabel;
    memLog: TMemo;
    panActions: TPanel;
    panCredits: TPanel;
    sttCredits: TStaticText;
    procedure btnAddToQueueClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FManager : IManagerThread;
    procedure ShowMessage(const AStatusMessage: String);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  evlMain:= TEventLog.Create(Self);
  evlMain.AppendContent:= False;
  evlMain.Identification:= Application.Title;
  evlMain.DefaultEventType:= etInfo;
  evlMain.FileName:= ChangeFileExt(ParamStr(0), '.log');
  evlMain.LogType:= ltFile;
  evlMain.Active:= True;
  evlMain.Debug(FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Creating Manager'));
  FManager:=TManagerThread.Create(3, @ShowMessage);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  evlMain.Debug(FormatLogMessage({$I %FILE%}, {$I %LINENUM%}, 'Freeing Manager'));
  FreeAndNil(FManager);
  //FManager:= nil;
  evlMain.Active:= False;
  evlMain.Free;
end;

procedure TfrmMain.ShowMessage(const AStatusMessage: String);
begin
  memLog.Append(AStatusMessage);
end;

procedure TfrmMain.btnAddToQueueClick(Sender: TObject);
begin
  FManager.AddFile(edtFileName.Text);
end;

end.

