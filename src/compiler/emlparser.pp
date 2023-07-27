unit emlparser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl,
  emllexer, emlast, emlerrors;

type

  TEntityMap = specialize TFPGMap<String,TEMLEntity>;

  { TEMLParser }

  TEMLParser = class
  private
    FLexer: TEMLLexer;
    FErrorList: TEMLErrorList;
    FPrevToken: TToken;
    FEntityMap: TEntityMap;
    function ParseERD: TEMLERD;
    function ParseEntities: TEMLEntities;
    function ParseEntity: TEMLEntity;
    function ParseFields: TEMLFieldList;
    function ParseField: TEMLField;
    function ParseRelationships: TEMLRelationships;
    function ParseRelationship: TEMLRelationship;
    function Accepted(const TokenKind: TTokenKind): Boolean;
    function Expected(const TokenKind: TTokenKind): Boolean;
  public
    constructor Create(ALexer: TEMLLexer; AErrorList: TEMLErrorList);
    destructor Destroy; override;
    function Parse: TEMLERD;
  end;

implementation

{ TEMLParser }

function TEMLParser.ParseERD: TEMLERD;
var
  Title: String = '';
  Entities: TEMLEntities;
  Relationships: TEMLRelationships;
begin
  Expected(tkDiagram);
  if Accepted(tkIdentifier) then
    Title := FPrevToken.Lexeme;
  Expected(tkOpenBlock);
  Entities := ParseEntities;
  Relationships := ParseRelationships;
  Expected(tkCloseBlock);

  Result := TEMLERD.Create(Title,Entities,Relationships);
end;

function TEMLParser.ParseEntities: TEMLEntities;
begin
  Result := TEMLEntities.Create;

  Expected(tkEntities);
  Expected(tkOpenBlock);
  while not Accepted(tkCloseBlock) and not Accepted(tkEOF) do
    Result.AddEntity(ParseEntity);
end;

function TEMLParser.ParseEntity: TEMLEntity;
var
  EntityName: String;
  EntityLine,EntityCol,Idx: Integer;
  Fields: TEMLFieldList;
begin
  EntityName := '';
  if Expected(tkIdentifier) then
    EntityName := FPrevToken.Lexeme;
  EntityLine := FPrevToken.Line;
  EntityCol := FPrevToken.Col;
  Idx := FEntityMap.IndexOf(EntityName);
  if Idx <> -1 then
    FErrorList.Add(TSemanticError.Create(
      FPrevToken.Line,
      FPrevToken.Col,
      Format('Entity "%s" already declared in (%d,%d)',[
        FPrevToken.Lexeme,
        FEntityMap[EntityName].Line,
        FEntityMap[EntityName].Col
      ])
    ));
  Expected(tkOpenBlock);
  Fields := ParseFields;
  Expected(tkCloseBlock);

  Result := TEMLEntity.Create(EntityLine,EntityCol,EntityName,Fields);
  FEntityMap.Add(EntityName,Result);
end;

function TEMLParser.ParseField: TEMLField;
var
  Name: String;
  IsPrimary: Boolean;
begin
  if Expected(tkIdentifier) then
    Name := FPrevToken.Lexeme;
  IsPrimary := false;
  if Accepted(tkAsterisk) then
    IsPrimary := true;
  Result := TEMLField.Create(Name,IsPrimary);
end;

function TEMLParser.ParseFields: TEMLFieldList;
begin
  Result := TEMLFieldList.Create;

  Result.Add(ParseField);
  while Accepted(tkComma) do
    Result.Add(ParseField);
end;

function TEMLParser.ParseRelationships: TEMLRelationships;
begin
  Result := TEMLRelationships.Create;

  Expected(tkRelationships);
  Expected(tkOpenBlock);
  while not Accepted(tkCloseBlock) and not Accepted(tkEOF) do
    Result.AddRelationship(ParseRelationship);
end;

function TEMLParser.ParseRelationship: TEMLRelationship;
var
  Q1,Q2: Char;
  Quantifier1,Quantifier2: TEMLQuantifier;
  Entity1,Entity2: TEMLEntity;
  RelationshipName: String;
  Idx: Integer;
begin
  if Expected(tkQuantifier) then
    Q1 := FPrevToken.Lexeme[1];
  if Accepted(tkComma) then begin
    if Expected(tkQuantifier) then
      Q2 := FPrevToken.Lexeme[1];
      Quantifier1 := TEMLQuantifier.Create(Q1,Q2);
  end else
    Quantifier1 := TEMLQuantifier.Create(Q1);
  if Expected(tkIdentifier) then begin
    Idx := FEntityMap.IndexOf(FPrevToken.Lexeme);
    if Idx <> -1 then
      Entity1 := FEntityMap.Data[Idx]
    else
      FErrorList.Add(TSemanticError.Create(
        FPrevToken.Line,
        FPrevToken.Col,
        'Entity "' + FPrevToken.Lexeme + '" doesn''t exist'
      ));
  end;
  if Expected(tkIdentifier) then
    RelationshipName := FPrevToken.Lexeme;
  if Expected(tkQuantifier) then
    Q1 := FPrevToken.Lexeme[1];
  if Accepted(tkComma) and Expected(tkQuantifier) then begin
    Q2 := FPrevToken.Lexeme[1];
    Quantifier2 := TEMLQuantifier.Create(Q1,Q2);
  end else
    Quantifier2 := TEMLQuantifier.Create(Q1);
  if Expected(tkIdentifier) then begin
    Idx := FEntityMap.IndexOf(FPrevToken.Lexeme);
    if Idx <> -1 then
      Entity2 := FEntityMap.Data[Idx]
    else
      FErrorList.Add(TSemanticError.Create(
        FPrevToken.Line,
        FPrevToken.Col,
        'Entity "' + FPrevToken.Lexeme + '" doesn''t exist'
      ));
  end;

  Result := TEMLRelationship.Create(RelationshipName,Entity1,Entity2,
    Quantifier1,Quantifier2);
end;

function TEMLParser.Accepted(const TokenKind: TTokenKind): Boolean;
begin
  Result := FLexer.CurrentToken.Kind = TokenKind;
  if Result then begin
    FPrevToken := FLexer.CurrentToken;
    FLexer.NextToken;
  end;
end;

function TEMLParser.Expected(const TokenKind: TTokenKind): Boolean;
var
  KindStr1,KindStr2: String;
begin
  Result := Accepted(TokenKind);
  if not Result then begin
    Str(TokenKind,KindStr1);
    Str(FLexer.CurrentToken.Kind,KindStr2);
    FErrorList.Add(TParseError.Create(
      FLexer.CurrentToken.Line,
      FLexer.CurrentToken.Col,
      KindStr1 + ' expected, but ' + KindStr2 + '("' + FLexer.
        CurrentToken.Lexeme + '") found'));
    while not(FLexer.CurrentToken.Kind in [tkCloseBlock,tkEOF]) do
      FLexer.NextToken;
  end;
end;

constructor TEMLParser.Create(ALexer: TEMLLexer; AErrorList: TEMLErrorList);
begin
  FLexer := ALexer;
  FErrorList := AErrorList;
  FEntityMap := TEntityMap.Create;
end;

destructor TEMLParser.Destroy;
begin
  FEntityMap.Free;
  inherited Destroy;
end;

function TEMLParser.Parse: TEMLERD;
begin
  Result := ParseERD;
end;

end.

