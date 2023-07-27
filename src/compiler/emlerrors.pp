unit emlerrors;

{$mode objfpc}

interface

uses
  Classes, SysUtils, fgl;

type

  { TEMLError }

  TEMLError = class
  protected
    FLine,FCol: LongWord;
    FMessage: String;
    function GetMessage: String;
  public
    property Message: String read GetMessage;
    constructor Create(const ALine,ACol: LongWord; const AMessage: String);
  end;

  TEMLErrorList = specialize TFPGObjectList<TEMLError>;

  TTokenError = class(TEMLError)
  end;

  { TParseError }

  TParseError = class(TEMLError)
  end;

  { TSemanticError }

  TSemanticError = class(TEMLError)
  end;

implementation

{ TEMLError }

function TEMLError.GetMessage: String;
begin
  Result := Format('(%d,%d): %s',[FLine,FCol,FMessage]);
end;

constructor TEMLError.Create(const ALine, ACol: LongWord;
  const AMessage: String);
begin
  FLine := ALine;
  FCol := ACol;
  FMessage := AMessage;
end;

end.

