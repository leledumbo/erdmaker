unit emlcopt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, cmdopts;

type

  { TInputFileOption }

  TInputFileOption = class(TCommandLineOption)
  private
    FName: String;
  public
    property Name: String read FName;
    constructor Create;
    procedure Execute; override;
  end;

  { TOutputFileOption }

  TOutputFileOption = class(TCommandLineOption)
  private
    FName: String;
  public
    property Name: String read FName;
    constructor Create;
    procedure Execute; override;
  end;

  { THelpOption }

  THelpOption = class(TCommandLineOption)
  public
    constructor Create;
    procedure Execute; override;
  end;

var
  CommandLineOptions: TCommandLineOptions;
  InputFileOption: TInputFileOption;
  OutputFileOption: TOutputFileOption;
  HelpOption: THelpOption;

implementation

{ TInputFileOption }

constructor TInputFileOption.Create;
begin
  inherited Create('i','input','Input filename. If not specified, read from standard input without waiting',true);
  FName := '<stdin>';
end;

procedure TInputFileOption.Execute;
begin
  FName := FArgument;
end;

{ TOutputFileOption }

constructor TOutputFileOption.Create;
begin
  inherited Create('o','output','Output filename. If not specified, write to standard output',true);
  FName := '<stdout>';
end;

procedure TOutputFileOption.Execute;
begin
  FName := FArgument;
end;

{ THelpOption }

constructor THelpOption.Create;
begin
  inherited Create('h','help','Show this message',false);
end;

procedure THelpOption.Execute;
begin
  WriteLn('ERD Maker Language Compiler v0.9');
  WriteLn('usage: ' + ExtractFileName(ParamStr(0)) + ' {options}');
  WriteLn('options:');
  WriteLn(CommandLineOptions.ToString);
end;

initialization
  CommandLineOptions := TCommandLineOptions.Create;
  InputFileOption := TInputFileOption.Create;
  OutputFileOption := TOutputFileOption.Create;
  HelpOption := THelpOption.Create;
  with CommandLineOptions.Options do begin
    Add(InputFileOption);
    Add(OutputFileOption);
    Add(HelpOption);
  end;
  CommandLineOptions.GetOptions;

finalization
  CommandLineOptions.Free;

end.

