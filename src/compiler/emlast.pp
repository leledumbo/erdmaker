unit emlast;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  { TEMLTreeNode }

  TEMLTreeNode = class abstract(TObject)
  public
    procedure GetCode(CodeLines: TStringList); virtual; abstract;
  end;

  { TEMLField }

  TEMLField = class(TObject)
  private
    FName: String;
    FIsPrimary: Boolean;
  public
    property Name: String read FName;
    property IsPrimary: Boolean read FIsPrimary;
    constructor Create(const AName: String; const AIsPrimary: Boolean);
    destructor Destroy; override;
  end;

  TEMLFieldList = specialize TFPGObjectList<TEMLField>;

  { TEMLEntity }

  TEMLEntity = class(TEMLTreeNode)
  private
    FLine,FCol: LongWord;
    FName: String;
    FFieldList: TEMLFieldList;
    function GetFields(const i: Integer): TEMLField;
  public
    property Line: LongWord read FLine;
    property Col: LongWord read FCol;
    property Name: String read FName;
    property Fields[const i: Integer]: TEMLField read GetFields;
    constructor Create(const ALine,ACol: LongWord; const AName: String; AFieldList: TEMLFieldList);
    destructor Destroy; override;
    procedure GetCode(CodeLines: TStringList); override;
  end;

  TEMLEntityList = specialize TFPGObjectList<TEMLEntity>;

  { TEMLEntities }

  TEMLEntities = class(TEMLTreeNode)
  private
    FEntityList: TEMLEntityList;
    function GetEntities(const i: Integer): TEMLEntity;
  public
    property Entities[const i: Integer]: TEMLEntity read GetEntities;
    constructor Create;
    destructor Destroy; override;
    procedure AddEntity(AEntity: TEMLEntity);
    procedure GetCode(CodeLines: TStringList); override;
  end;

  { TEMLQuantifier }

  TEMLQuantifier = class(TObject)
  private
    FLowerBound,FUpperBound: Char;
  public
    property LowerBound: Char read FLowerBound;
    property UpperBound: Char read FUpperBound;
    constructor Create(const ALowerBound,AUpperBound: Char);
    constructor Create(const AUpperBound: Char);
    destructor Destroy; override;
  end;

  { TEMLRelationship }

  TEMLRelationship = class(TEMLTreeNode)
  private
    FName: String;
    FEntity1,FEntity2: TEMLEntity;
    FQuantifier1,FQuantifier2: TEMLQuantifier;
  public
    constructor Create(const AName: String; AEntity1,AEntity2: TEMLEntity; AQuantifier1,
      AQuantifier2: TEMLQuantifier);
    destructor Destroy; override;
    procedure GetCode(CodeLines: TStringList); override;
  end;

  TEMLRelationshipList = specialize TFPGObjectList<TEMLRelationship>;

  { TEMLRelationships }

  TEMLRelationships = class(TEMLTreeNode)
  private
    FRelationshipList: TEMLRelationshipList;
    function GetRelationship(const i: Integer): TEMLRelationship;
  public
    property Relationships[const i: Integer]: TEMLRelationship read GetRelationship;
    constructor Create;
    destructor Destroy; override;
    procedure AddRelationship(ARelationship: TEMLRelationship);
    procedure GetCode(CodeLines: TStringList); override;
  end;

  { TEMLERD }

  TEMLERD = class(TEMLTreeNode)
  private
    FTitle: String;
    FEntities: TEMLEntities;
    FRelationships: TEMLRelationships;
  public
    property Title: String read FTitle;
    constructor Create(const ATitle: String; AEntities: TEMLEntities;
      ARelationships: TEMLRelationships);
    destructor Destroy; override;
    procedure GetCode(CodeLines: TStringList); override;
  end;

implementation

uses
  utils;

{ TEMLField }

constructor TEMLField.Create(const AName: String; const AIsPrimary: Boolean);
begin
  FName := AName;
  FIsPrimary := AIsPrimary;
end;

destructor TEMLField.Destroy;
begin
  inherited Destroy;
end;

{ TEMLEntity }

function TEMLEntity.GetFields(const i: Integer): TEMLField;
begin
  Result := FFieldList[i];
end;

constructor TEMLEntity.Create(const ALine, ACol: LongWord; const AName: String;
  AFieldList: TEMLFieldList);
begin
  FLine := ALine;
  FCol := ACol;
  FName := AName;
  FFieldList := AFieldList;
end;

destructor TEMLEntity.Destroy;
begin
  FFieldList.Free;
  inherited Destroy;
end;

procedure TEMLEntity.GetCode(CodeLines: TStringList);
var
  i: Integer;
  EntityName,FieldName: String;
begin
  EntityName := Format('e_%s',[ReplaceSpacesWithUnderscores(FName)]);
  with CodeLines do begin
    Add(Format('  %s [label="%s",shape=box];',[EntityName,FName]));
    for i := 0 to FFieldList.Count - 1 do begin
      FieldName := Format('f_%s_%s',[
        EntityName,
        ReplaceSpacesWithUnderscores(FFieldList[i].Name)
      ]);
      if FFieldList[i].IsPrimary then begin
        Add(Format('  %s [label=<<u>%s</u>>,shape=ellipse];',
          [FieldName,FFieldList[i].Name]));
      end else begin
        Add(Format('  %s [label="%s",shape=ellipse];',
          [FieldName,FFieldList[i].Name]));
      end;
      Add(Format('  %s -- %s;',[FieldName,EntityName]));
    end;
  end;
end;

{ TEMLEntities }

function TEMLEntities.GetEntities(const i: Integer): TEMLEntity;
begin
  Result := FEntityList[i];
end;

constructor TEMLEntities.Create;
begin
  FEntityList := TEMLEntityList.Create(true);
end;

destructor TEMLEntities.Destroy;
begin
  FEntityList.Free;
  inherited Destroy;
end;

procedure TEMLEntities.AddEntity(AEntity: TEMLEntity);
begin
  FEntityList.Add(AEntity);
end;

procedure TEMLEntities.GetCode(CodeLines: TStringList);
var
  i: Integer;
begin
  for i := 0 to FEntityList.Count - 1 do begin
    FEntityList[i].GetCode(CodeLines);
  end;
end;

{ TEMLQuantifier }

constructor TEMLQuantifier.Create(const ALowerBound, AUpperBound: Char);
begin
  FLowerBound := ALowerBound;
  FUpperBound := AUpperBound;
end;

constructor TEMLQuantifier.Create(const AUpperBound: Char);
begin
  Create(#0,AUpperBound);
end;

destructor TEMLQuantifier.Destroy;
begin
  inherited Destroy;
end;

{ TEMLRelationship }

constructor TEMLRelationship.Create(const AName: String; AEntity1,
  AEntity2: TEMLEntity; AQuantifier1, AQuantifier2: TEMLQuantifier);
begin
  FName := AName;
  FEntity1 := AEntity1;
  FEntity2 := AEntity2;
  FQuantifier1 := AQuantifier1;
  FQuantifier2 := AQuantifier2;
end;

destructor TEMLRelationship.Destroy;
begin
  FQuantifier1.Free;
  FQuantifier2.Free;
  inherited Destroy;
end;

procedure TEMLRelationship.GetCode(CodeLines: TStringList);
var
  Entity1Name,Entity2Name,RelationshipName: String;
begin
  Entity1Name := Format('e_%s',[ReplaceSpacesWithUnderscores(FEntity1.Name)]);
  Entity2Name := Format('e_%s',[ReplaceSpacesWithUnderscores(FEntity2.Name)]);
  RelationshipName := Format('r_%s_%s_%s',[
    Entity1Name,
    ReplaceSpacesWithUnderscores(FName),
    Entity2Name
  ]);
  with CodeLines do begin
    // Relation
    Add(Format('  %s [label="%s",shape=diamond];',[RelationshipName,FName]));
    // Quantifier 1
    if FQuantifier1.LowerBound <> #0 then
      Add(Format('  %s -- %s [label="(%s,%s)"];',[
        Entity1Name,
        RelationshipName,
        FQuantifier1.LowerBound,
        FQuantifier1.UpperBound
      ]))
    else
      Add(Format('  %s -- %s [label="%s"];',[
        Entity1Name,
        RelationshipName,
        FQuantifier1.UpperBound
      ]));
    // Quantifier 2
    if FQuantifier2.LowerBound <> #0 then
      Add(Format('  %s -- %s [label="(%s,%s)"];',[
        RelationshipName,
        Entity2Name,
        FQuantifier2.LowerBound,
        FQuantifier2.UpperBound
      ]))
    else
      Add(Format('  %s -- %s [label="%s"];',[
        RelationshipName,
        Entity2Name,
        FQuantifier2.UpperBound
      ]));
  end;
end;

{ TEMLRelationships }

function TEMLRelationships.GetRelationship(const i: Integer): TEMLRelationship;
begin
  Result := FRelationshipList[i];
end;

constructor TEMLRelationships.Create;
begin
  FRelationshipList := TEMLRelationshipList.Create(true);
end;

destructor TEMLRelationships.Destroy;
begin
  FRelationshipList.Free;
  inherited Destroy;
end;

procedure TEMLRelationships.AddRelationship(ARelationship: TEMLRelationship);
begin
  FRelationshipList.Add(ARelationship);
end;

procedure TEMLRelationships.GetCode(CodeLines: TStringList);
var
  i: Integer;
begin
  for i := 0 to FRelationshipList.Count - 1 do begin
    FRelationshipList[i].GetCode(CodeLines);
  end;
end;

{ TEMLERD }

constructor TEMLERD.Create(const ATitle: String; AEntities: TEMLEntities;
  ARelationships: TEMLRelationships);
begin
  FTitle := ATitle;
  FEntities := AEntities;
  FRelationships := ARelationships;
end;

destructor TEMLERD.Destroy;
begin
  FRelationships.Free;
  FEntities.Free;
  inherited Destroy;
end;

procedure TEMLERD.GetCode(CodeLines: TStringList);
begin
  with CodeLines do begin
    Add('graph "' + FTitle + '" {');
    Add('  labelloc="t";');
    Add('  label="' + FTitle + '";');
    Add('  overlap="scale";');
    Add('  splines="true";');
    FEntities.GetCode(CodeLines);
    FRelationships.GetCode(CodeLines);
    Add('}');
  end;
end;

end.

