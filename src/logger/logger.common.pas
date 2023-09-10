unit Logger.Common;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
, SysUtils
, eventlog
;

function FormatLogMessage(
  const AFileName: String;
  const ALineNumber: Integer;
  const AMessage: String
): String;

var
  evlMain: TEventLog;
  sLogMessage: String;

implementation

function FormatLogMessage(
  const AFileName: String;
  const ALineNumber: Integer;
  const AMessage: String
): String;
begin
  Result:= Format('[%s(%d)] %s', [ AFileName, ALineNumber, AMessage ]);
end;

finalization
  SetLength(sLogMessage, 0);
end.

