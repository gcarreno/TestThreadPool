unit Logger.Common;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
, eventlog
;

function FormatLogMessage(AFileName: String; ALineNumber: Integer;
  AMessage: String): String;

var
  evlMain: TEventLog;
  sLogMessage: String;

implementation

function FormatLogMessage(AFileName: String; ALineNumber: Integer;
  AMessage: String): String;
begin
  Result:= Format('[%s(%d)] %s', [ AFileName, ALineNumber, AMessage ]);
end;

end.

