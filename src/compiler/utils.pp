unit utils;

{$mode objfpc}

interface

uses
  Classes, SysUtils; 

function ReplaceSpacesWithUnderscores(const S: String): String;

implementation

function ReplaceSpacesWithUnderscores(const S: String): String;
begin
  Result := StringReplace(S,' ','_',[rfReplaceAll]);
end;

end.

