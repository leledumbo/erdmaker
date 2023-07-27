unit cmdopts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  { TCommandLineOption }

  TCommandLineOption = class
  protected
    FShortOption: String;
    FLongOption: String;
    FDescription: String;
    FIsSet: Boolean;
    FRequiresArgument: Boolean;
    FArgument: String;
  public
    property ShortOption: String read FShortOption;
    property LongOption: String read FLongOption;
    property Description: String read FDescription;
    property IsSet: Boolean read FIsSet write FIsSet;
    property Argument: String read FArgument write FArgument;
    property RequiresArgument: Boolean read FRequiresArgument;
    constructor Create(const AShortOption,ALongOption,ADescription: String;
      const ARequiresArgument: Boolean);
    procedure Execute; virtual; abstract;
    function ToString: String; override;
  end;

  TOptions = specialize TFPGObjectList<TCommandLineOption>;

  { TCommandLineOptions }

  TCommandLineOptions = class(TObject)
  private
    FOptions: TOptions;
  public
    property Options: TOptions read FOptions;
    constructor Create;
    destructor Destroy; override;
    procedure GetOptions;
    function ToString: String; override;
  end;

implementation

{ TCommandLineOption }

constructor TCommandLineOption.Create(const AShortOption, ALongOption,
  ADescription: String; const ARequiresArgument: Boolean);
begin
  FShortOption := AShortOption;
  FLongOption := ALongOption;
  FDescription := ADescription;
  FIsSet := false;
  FRequiresArgument := ARequiresArgument;
end;

function TCommandLineOption.ToString: String;
begin
  Result := '';
  if FShortOption <> '' then
    Result := '-' + FShortOption;
  if FLongOption <> '' then
    if Result <> '' then
      Result := Result + ',--' + FLongOption
    else
      Result := '--' + FLongOption;
  Result := Result + #9 + FDescription;
end;

{ TCommandLineOptions }

constructor TCommandLineOptions.Create;
begin
  FOptions := TOptions.Create(true);
end;

destructor TCommandLineOptions.Destroy;
begin
  FOptions.Free;
  inherited Destroy;
end;

procedure TCommandLineOptions.GetOptions;
var
  i,j: Integer;
  TempCmd: TCommandLineOption;
  Param: String;
begin
  i := 1;
  while i <= ParamCount do begin
    Param := ParamStr(i);
    if (Length(Param) >= 2) and (Param[1] = '-') then
      if Param[2] = '-' then // long option
        for j := 0 to FOptions.Count - 1 do begin
          TempCmd := FOptions[j];
          if TempCmd.LongOption = Copy(Param,3,Length(Param) - 2) then begin
            TempCmd.IsSet := true;
            if TempCmd.RequiresArgument then begin
              Inc(i);
              TempCmd.Argument := ParamStr(i);
            end;
            TempCmd.Execute;
          end;
        end
      else // short options
        for j := 0 to FOptions.Count - 1 do begin
          TempCmd := TCommandLineOption(FOptions[j]);
          if TempCmd.ShortOption = Copy(Param,2,Length(Param) - 1) then begin
            TempCmd.IsSet := true;
            if TempCmd.RequiresArgument then begin
              Inc(i);
              TempCmd.Argument := ParamStr(i);
            end;
          TempCmd.Execute;
          end;
        end;
    Inc(i);
  end;
end;

function TCommandLineOptions.ToString: String;
var
  i: Integer;
begin
  with TStringList.Create do
    try
      for i := 0 to FOptions.Count - 1 do
        Add(FOptions[i].ToString);
      Result := Text;
    finally
      Free;
    end;

end;

end.

