unit CompProc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type

  TOnCompilerMessage = procedure (const AMessage: String) of object;
  TOnCompilerOutput = procedure (AStream: TStream) of object;

  { TCompilerProcessor }

  TCompilerProcessor = class(TThread)
  private
    FOnCompilerMessage: TOnCompilerMessage;
    FOnCompilerOutput: TOnCompilerOutput;
    FInputFile: String;
    FCurrentCompilerMessage: String;
    FOutputStream: TStream;
    procedure SyncCompilerMessages;
    procedure SyncCompilerOutput;
  protected
    procedure Execute; override;
  public
    constructor Create(AOnCompilerMessage: TOnCompilerMessage;
      AOnCompilerOutput: TOnCompilerOutput;
      AOnTerminate: TNotifyEvent; const AInputFile: String);
  end;

implementation

{ TCompilerProcessor }

constructor TCompilerProcessor.Create(AOnCompilerMessage: TOnCompilerMessage;
  AOnCompilerOutput: TOnCompilerOutput; AOnTerminate: TNotifyEvent;
  const AInputFile: String);
begin
  inherited Create(true);
  FreeOnTerminate := true;
  OnTerminate := AOnTerminate;
  FOnCompilerMessage := AOnCompilerMessage;
  FOnCompilerOutput := AOnCompilerOutput;
  FInputFile := AInputFile;
  Start;
end;

procedure TCompilerProcessor.SyncCompilerMessages;
begin
  if Assigned(FOnCompilerMessage) then
    FOnCompilerMessage(FCurrentCompilerMessage);
end;

procedure TCompilerProcessor.SyncCompilerOutput;
begin
  if Assigned(FOnCompilerOutput) then
    FOnCompilerOutput(FOutputStream);
end;

procedure TCompilerProcessor.Execute;
var
  OutBuf: String;
  OutBufWritePos: Integer;
  HasError: Boolean;
  AProc: TProcess;

  procedure ReadStderrAndOutput1;
  var
    BytesAvailable: DWord;
  begin
    // read error messages
    BytesAvailable := AProc.Stderr.NumBytesAvailable;
    if BytesAvailable > 0 then begin
      SetLength(FCurrentCompilerMessage,BytesAvailable);
      AProc.Stderr.Read(FCurrentCompilerMessage[1],BytesAvailable);
      Synchronize(@SyncCompilerMessages);
      HasError := true;
    end;
    // read output
    BytesAvailable := AProc.Output.NumBytesAvailable;
    if BytesAvailable > 0 then begin
      OutBufWritePos := Length(OutBuf) + 1;
      SetLength(OutBuf,Length(OutBuf) + BytesAvailable);
      AProc.Output.Read(OutBuf[OutBufWritePos],BytesAvailable);
    end;
  end;

  procedure ReadStderrAndOutput2;
  var
    BytesAvailable: DWord;
  begin
    // read error messages
    BytesAvailable := AProc.Stderr.NumBytesAvailable;
    if BytesAvailable > 0 then begin
      SetLength(FCurrentCompilerMessage,BytesAvailable);
      AProc.Stderr.Read(FCurrentCompilerMessage[1],BytesAvailable);
      Synchronize(@SyncCompilerMessages);
      HasError := true;
    end;
    // read output
    BytesAvailable := AProc.Output.NumBytesAvailable;
    if BytesAvailable > 0 then begin
      SetLength(OutBuf,BytesAvailable);
      AProc.Output.Read(OutBuf[1],BytesAvailable);
      FOutputStream.Write(OutBuf[1],BytesAvailable);
    end;
  end;

begin
  HasError := false;
  AProc := TProcess.Create(nil);
  with AProc do
    try
      Options := [poUsePipes,poNoConsole];
      Executable := 'emlc';
      Parameters.Add('-i');
      Parameters.Add(FInputFile);
      Execute;
      while Running do begin
        ReadStderrAndOutput1;
      end;
      ReadStderrAndOutput1;
    finally
      AProc.Free;
    end;
  // execute dot if no error
  if not HasError then begin
    FOutputStream := TMemoryStream.Create;
    AProc := TProcess.Create(nil);
    with AProc do
      try
        Options := [poUsePipes,poNoConsole];
        Executable := 'dot';
        Parameters.Add('-Tpng');
        Execute;
        // feed emlc output
        Input.Write(OutBuf[1],Length(OutBuf));
        // dot will wait until EOF, this is a way to do it
        CloseInput;
        while Running do begin
          ReadStderrAndOutput2;
        end;
        ReadStderrAndOutput2;
      finally
        Free;
      end;
    FOutputStream.Seek(0,soFromBeginning);
    Synchronize(@SyncCompilerOutput);
  end;
  FOutputStream.Free;
end;

end.

