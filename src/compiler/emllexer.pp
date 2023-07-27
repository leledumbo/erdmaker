unit emllexer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl,
  emlerrors;

type

  TTokenKind = (
    tkDiagram,
    tkEntities,
    tkRelationships,
    tkOpenBlock,
    tkCloseBlock,
    tkComma,
    tkAsterisk,
    tkIdentifier,
    tkQuantifier,
    tkEOF,
    tkNil
  );

  { TToken }

  TToken = class
  private
    FKind: TTokenKind;
    FLexeme: String;
    FLine, FCol: LongWord;
  public
    property Kind: TTokenKind read FKind;
    property Lexeme: String read FLexeme;
    property Line: LongWord read FLine;
    property Col: LongWord read FCol;
    constructor Create(const AKind: TTokenKind; const ALexeme: String;
      const ALine, ACol: LongWord);
    function ToString: String; override;
  end;

  TTokenList = specialize TFPGObjectList<TToken>;

  { TEMLLexer }

  TEMLLexer = class
  private
    FInput: TextFile;
    FLine, FCol: LongWord;
    FLineBuf: String;
    FLook: Char;
    FCurrentToken: TToken;
    FTokenList: TTokenList;
    FErrorList: TEMLErrorList;
    function ReadChar: Char;
  public
    property Line: LongWord read FLine;
    property Col: LongWord read FCol;
    property CurrentToken: TToken read FCurrentToken;
    property Tokens: TTokenList read FTokenList;
    property Errors: TEMLErrorList read FErrorList;
    constructor Create(AStream: TStream; AErrorList: TEMLErrorList);
    destructor Destroy; override;
    procedure NextToken;
  end;

  { EUnclosedQuotedIdentifier }

  EUnclosedQuotedIdentifier = class(Exception)
  public
    constructor Create(const ALine,ACol: LongWord);
  end;

implementation

uses
  streamio;

const
  EOFChar                    = #26;
  LFChar                     = #10;
  SingleQuote                = '''';
  WhiteSpaces                = [' ', #9, #10];
  WhiteSpacesAndCommentStart = WhiteSpaces + ['#'];
  AlphaChars                 = ['A'..'Z', 'a'..'z', '_'];
  NumChars                   = ['0'..'9'];
  IdentChars                 = AlphaChars + NumChars;

{ TToken }

constructor TToken.Create(const AKind: TTokenKind; const ALexeme: String;
  const ALine, ACol: LongWord);
begin
  FKind := AKind;
  FLexeme := ALexeme;
  FLine := ALine;
  FCol := ACol;
end;

function TToken.ToString: String;
var
  KindStr: String;
begin
  Str(FKind,KindStr);
  Result := Format('(%d,%d): %s(%s) ',[FLine,FCol,KindStr,FLexeme]);
end;

{ TEMLLexer }

function TEMLLexer.ReadChar: Char;
begin
  // increment current column then return next available character
  if FCol < Length(FLineBuf) then begin
    Inc(FCol);
    Result := FLineBuf[FCol];
  end else begin
    // don't waste time reading past EOF
    if EOF(FInput) then Result := EOFChar
    // end of line, read the next line then return newline character
    else begin
      ReadLn(FInput,FLineBuf);
      Inc(FLine);
      FCol := 0;
      Result := LFChar;
    end;
  end;
end;

constructor TEMLLexer.Create(AStream: TStream; AErrorList: TEMLErrorList);
begin
  inherited Create;
  AssignStream(FInput,AStream);
  Reset(FInput);
  FLine := 0;
  FCol := 0;
  FTokenList := TTokenList.Create(true);
  FErrorList := AErrorList;
  FLook := ReadChar;
  NextToken;
end;

destructor TEMLLexer.Destroy;
begin
  CloseFile(FInput);
  FTokenList.Free;
  inherited Destroy;
end;

procedure TEMLLexer.NextToken;

  function QuotedIdentifier(const StartLine,StartCol: LongWord): String; inline;
  begin
    Result := '';
    FLook := ReadChar;
    while not(FLook in [SingleQuote,EOFChar]) do begin
      Result := Result + FLook;
      FLook := ReadChar;
    end;
    if FLook = EOFChar then
      FErrorList.Add(
        TTokenError.Create(
          FLine,
          FCol,
          Format('Unterminated quoted identifier started in (%d,%d)',
            [StartLine,StartCol]
          )
        )
      );
    FLook := ReadChar;
    if FLook = SingleQuote then
      Result := Result + SingleQuote + QuotedIdentifier(StartLine,StartCol);
  end;

  procedure SkipWhitespacesAndComment;
  begin
    repeat
      // skip whitespaces
      while FLook in WhiteSpaces do
        FLook := ReadChar;
      // skip comment
      while FLook = '#' do begin
        repeat
          FLook := ReadChar;
        until FLook in [LFChar,EOFChar];
        FLook := ReadChar;
      end;
    until not(FLook in WhiteSpacesAndCommentStart);
  end;

var
  Kind: TTokenKind;
  Lexeme: String;
  StartLine,StartCol: LongWord;
begin
  SkipWhitespacesAndComment;
  Lexeme := FLook;
  StartLine := FLine;
  StartCol := FCol;
  case FLook of
    EOFChar: begin
      Lexeme := 'EOF';
      Kind := tkEOF;
      FLook := ReadChar;
    end;
    ',': begin
      Kind := tkComma;
      FLook := ReadChar;
    end;
    '*': begin
      Kind := tkAsterisk;
      FLook := ReadChar;
    end;
    '{': begin
      Kind := tkOpenBlock;
      FLook := ReadChar;
    end;
    '}': begin
      Kind := tkCloseBlock;
      FLook := ReadChar;
    end;
    'A'..'Z', 'a'..'z', '0'..'9', '_': begin
      FLook := ReadChar;
      while FLook in IdentChars do begin
        Lexeme := Lexeme + FLook;
        FLook := ReadChar;
      end;
      case Lexeme of
        'diagram'      : Kind := tkDiagram;
        'entities'     : Kind := tkEntities;
        'relationships': Kind := tkRelationships;
        '0','1','m','n': Kind := tkQuantifier;
        else             Kind := tkIdentifier;
      end;
    end;
    SingleQuote: begin
      Kind := tkIdentifier;
      Lexeme := QuotedIdentifier(StartLine,StartCol);
    end;
    else begin
      Kind := tkNil;
      FLook := ReadChar;
    end;
  end;
  FCurrentToken := TToken.Create(Kind,Lexeme,StartLine,StartCol);
  FTokenList.Add(FCurrentToken);
end;

{ EUnclosedQuotedIdentifier }

constructor EUnclosedQuotedIdentifier.Create(const ALine, ACol: LongWord);
begin
  inherited Create(Format('Unterminated quoted identifier started at (%d,%d)',
    [ALine,ACol]));
end;

end.

