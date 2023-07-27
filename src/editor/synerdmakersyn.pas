unit SynERDMakerSyn;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, SynEditTypes, SynEditHighlighter;

type

  { TSynERDMakerHL }


  TSynERDMakerHL = class(TSynCustomHighlighter)
  private
    FKeywordAttri: TSynHighlighterAttributes;
    FSymbolAttri: TSynHighlighterAttributes;
    FConstantAttri: TSynHighlighterAttributes;
    FIdentifierAttri: TSynHighlighterAttributes;
    FCommentAttri: TSynHighlighterAttributes;
    procedure SetKeywordAttri(AValue: TSynHighlighterAttributes);
    procedure SetSymbolAttri(AValue: TSynHighlighterAttributes);
    procedure SetIdentifierAttri(AValue: TSynHighlighterAttributes);
    procedure SetConstantAttri(AValue: TSynHighlighterAttributes);
    procedure SetCommentAttri(AValue: TSynHighlighterAttributes);
  protected
    // accesible for the other examples
    FTokenPos, FTokenEnd: Integer;
    FLineText: String;
  public
    procedure SetLine(const NewValue: String; LineNumber: Integer); override;
    procedure Next; override;
    function  GetEol: Boolean; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function  GetTokenAttribute: TSynHighlighterAttributes; override;
  public
    function GetToken: String; override;
    function GetTokenPos: Integer; override;
    function GetTokenKind: integer; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes; override;
    constructor Create(AOwner: TComponent); override;
  published
    (* Define 4 Attributes, for the different highlights. *)
    property KeywordAttri: TSynHighlighterAttributes read FKeywordAttri
      write SetKeywordAttri;
    property SymbolAttri: TSynHighlighterAttributes read FSymbolAttri
      write SetSymbolAttri;
    property ConstantAttri: TSynHighlighterAttributes read FConstantAttri
      write SetConstantAttri;
    property IdentifierAttri: TSynHighlighterAttributes read FIdentifierAttri
      write SetIdentifierAttri;
    property CommentAttri: TSynHighlighterAttributes read FCommentAttri write SetCommentAttri;
  end;

implementation

constructor TSynERDMakerHL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  (* Create and initialize the attributes *)

  FKeywordAttri := TSynHighlighterAttributes.Create('keyword', 'keyword');
  AddAttribute(FKeywordAttri);
  FKeywordAttri.Style := [fsBold];

  FSymbolAttri := TSynHighlighterAttributes.Create('symbol', 'symbol');
  AddAttribute(FSymbolAttri);
  FSymbolAttri.Foreground := clRed;

  FConstantAttri := TSynHighlighterAttributes.Create('constant', 'constant');
  AddAttribute(FConstantAttri);
  FConstantAttri.Foreground := clGreen;
  FConstantAttri.Style := [fsBold];

  FIdentifierAttri := TSynHighlighterAttributes.Create('identifier', 'identifier');
  AddAttribute(FIdentifierAttri);
  FIdentifierAttri.Foreground := clNavy;

  FCommentAttri := TSynHighlighterAttributes.Create('comment', 'comment');
  AddAttribute(FCommentAttri);
  FCommentAttri.Foreground := clBlue;
  FCommentAttri.Style := [fsBold];
end;

(* Setters for attributes / This allows using in Object inspector*)
procedure TSynERDMakerHL.SetKeywordAttri(AValue: TSynHighlighterAttributes);
begin
  FKeywordAttri.Assign(AValue);
end;

procedure TSynERDMakerHL.SetSymbolAttri(AValue: TSynHighlighterAttributes);
begin
  FSymbolAttri.Assign(AValue);
end;

procedure TSynERDMakerHL.SetConstantAttri(AValue: TSynHighlighterAttributes);
begin
  FConstantAttri.Assign(AValue);
end;

procedure TSynERDMakerHL.SetCommentAttri(AValue: TSynHighlighterAttributes);
begin
  FCommentAttri.Assign(AValue);
end;

procedure TSynERDMakerHL.SetIdentifierAttri(AValue: TSynHighlighterAttributes);
begin
  FIdentifierAttri.Assign(AValue);
end;

procedure TSynERDMakerHL.SetLine(const NewValue: String; LineNumber: Integer);
begin
  inherited;
  FLineText := NewValue;
  // Next will start at "FTokenEnd", so set this to 1
  FTokenEnd := 1;
  Next;
end;

procedure TSynERDMakerHL.Next;
var
  l: Integer;
begin
  // FTokenEnd should be at the start of the next Token (which is the Token we want)
  FTokenPos := FTokenEnd;
  // assume empty, will only happen for EOL
  FTokenEnd := FTokenPos;

  // Scan forward
  // FTokenEnd will be set 1 after the last char. That is:
  // - The first char of the next token
  // - or past the end of line (which allows GetEOL to work)

  l := length(FLineText);
  If FTokenPos > l then
    // At line end
    exit
  else
  if FLineText[FTokenEnd] in [#9, ' '] then
    // At Space? Find end of spaces
    while (FTokenEnd <= l) and (FLineText[FTokenEnd] in [#0..#32]) do Inc(FTokenEnd)
  else
    // At None-Space? Find end of None-spaces
    begin
      case FLineText[FTokenPos] of
        '#': while (FTokenEnd <= l) do Inc(FTokenEnd);
        'a'..'z','A'..'Z','0'..'9','_':
          while (FTokenEnd <= l) and (FLineText[FTokenEnd] in ['a'..'z','A'..'Z','0'..'9','_']) do Inc(FTokenEnd);
        '''': begin
          Inc(FTokenEnd);
          while (FTokenEnd <= l) and (FLineText[FTokenEnd] <> '''') do Inc(FTokenEnd);
          Inc(FTokenEnd);
        end;
        otherwise
          while (FTokenEnd <= l) and not(FLineText[FTokenEnd] in ['a'..'z','A'..'Z','0'..'9','_',#0..#32]) do Inc(FTokenEnd);
      end;
    end;
end;

function TSynERDMakerHL.GetEol: Boolean;
begin
  Result := FTokenPos > length(FLineText);
end;

procedure TSynERDMakerHL.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenStart := @FLineText[FTokenPos];
  TokenLength := FTokenEnd - FTokenPos;
end;

function TSynERDMakerHL.GetTokenAttribute: TSynHighlighterAttributes;
var
  FirstChar: Char;
  Token: String;
begin
  // Match the text, specified by FTokenPos and FTokenEnd

  FirstChar := LowerCase(FLineText[FTokenPos]);
  Token := LowerCase(Copy(FLineText, FTokenPos, FTokenEnd - FTokenPos));

  Result := SymbolAttri;

  case FirstChar of
    '0','1','m','n': if Length(Token) = 1 then Result := ConstantAttri;
    '#'            : Result := CommentAttri;
  end;

  if Result = SymbolAttri then
    case Token of
      'diagram','entities','relationships': Result := KeywordAttri;
      otherwise
        if FirstChar in ['''','a'..'z','0'..'9','_'] then
          Result := IdentifierAttri;
    end;
end;

function TSynERDMakerHL.GetToken: String;
begin
  Result := Copy(FLineText, FTokenPos, FTokenEnd - FTokenPos);
end;

function TSynERDMakerHL.GetTokenPos: Integer;
begin
  Result := FTokenPos - 1;
end;

function TSynERDMakerHL.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  Result := nil;
end;

function TSynERDMakerHL.GetTokenKind: integer;
var
  a: TSynHighlighterAttributes;
begin
  // Map Attribute into a unique number
  a := GetTokenAttribute;
  Result := 0;
  if a = FIdentifierAttri then Result := 1;
  if a = FSymbolAttri then Result := 2;
  if a = FConstantAttri then Result := 3;
  if a = FKeywordAttri then Result := 4;
  if a = FCommentAttri then Result := 5;
end;

end.

