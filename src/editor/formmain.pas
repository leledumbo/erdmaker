unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterAny, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, PairSplitter, IniPropStorage, ActnList,
  Buttons, ComCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    PairSplitterTopBottom: TPairSplitter;
    PairSplitterTop: TPairSplitterSide;
    PairSplitterBottom: TPairSplitterSide;
    PairSplitterLeftRight: TPairSplitter;
    PairSplitterLeft: TPairSplitterSide;
    PairSplitterRight: TPairSplitterSide;
    PropStorageMainForm: TIniPropStorage;
    GBEditor: TGroupBox;
    SynEditEditor: TSynEdit;
    GBPreview: TGroupBox;
    GBOutput: TGroupBox;
    MemoLog: TMemo;
    ActionListMainForm: TActionList;
    ActionFileOpen: TAction;
    OpenDialogEditor: TOpenDialog;
    SaveDialogEditor: TSaveDialog;
    ActionFileSave: TAction;
    ImageListMainForm: TImageList;
    MainToolBar: TToolBar;
    ActionFileNew: TAction;
    ActionFileExecute: TAction;
    TBNew: TToolButton;
    TBOpen: TToolButton;
    TBSave: TToolButton;
    TBExecute: TToolButton;
    ScrollBoxPreview: TScrollBox;
    ImagePreview: TImage;
    ButtonSaveImage: TButton;
    SaveDialogImage: TSaveDialog;
    ActionImageSave: TAction;
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormCreate(Sender: TObject);
    procedure ActionFileOpenExecute(Sender: TObject);
    procedure ActionFileSaveExecute(Sender: TObject);
    procedure SynEditEditorChange(Sender: TObject);
    procedure ActionFileNewExecute(Sender: TObject);
    procedure ActionFileExecuteExecute(Sender: TObject);
    procedure ActionImageSaveExecute(Sender: TObject);
  private
    { private declarations }
    FCurrentFileName: String;
    function HandleUnsavedChanges: TModalResult;
    procedure OpenFile(const AFileName: String);
    procedure SaveFile;
    procedure LogToMemo(const AMessage: String);
    procedure EnableControls(Sender: TObject);
    procedure ToggleControls(const AEnable: Boolean);
    procedure DisplayImage(AStream: TStream);
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  SynERDMakerSyn,CompProc;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
begin
  OpenFile(FileNames[0]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  SynERDMakerHL: TSynERDMakerHL;
begin
  SynERDMakerHL := TSynERDMakerHL.Create(Self);
  SynEditEditor.Highlighter := SynERDMakerHL;
  FCurrentFileName := '';
  ActionFileSave.Enabled := false;
end;

procedure TMainForm.ActionFileNewExecute(Sender: TObject);
begin
  if HandleUnsavedChanges <> mrCancel then begin
    SynEditEditor.Lines.Clear;
    FCurrentFileName := '';
    ActionFileSave.Enabled := false;
    MemoLog.Lines.Clear;
    ImagePreview.Picture.Clear;
    ButtonSaveImage.Enabled := false;
  end;
end;

procedure TMainForm.ActionFileExecuteExecute(Sender: TObject);
begin
  if FCurrentFileName = '' then
    if SaveDialogEditor.Execute then begin
      FCurrentFileName := SaveDialogEditor.FileName;
    end;
  if FCurrentFileName <> '' then begin
    SaveFile;
    ToggleControls(false);
    MemoLog.Lines.Clear;
    TCompilerProcessor.Create(@LogToMemo,@DisplayImage,@EnableControls,FCurrentFileName);
  end else begin
    MessageDlg('Error','Cannot compile unnamed file!',mtError,[mbOK],0);
  end;
end;

procedure TMainForm.ActionImageSaveExecute(Sender: TObject);
begin
  if SaveDialogImage.Execute then begin
    ImagePreview.Picture.SaveToFile(SaveDialogImage.FileName);
  end;
end;

procedure TMainForm.ActionFileOpenExecute(Sender: TObject);
begin
  if OpenDialogEditor.Execute then begin
    OpenFile(OpenDialogEditor.FileName);
  end;
end;

procedure TMainForm.ActionFileSaveExecute(Sender: TObject);
begin
  if FCurrentFileName = '' then
    if SaveDialogEditor.Execute then begin
      FCurrentFileName := SaveDialogEditor.FileName;
    end;
  if FCurrentFileName <> '' then
    SaveFile;
end;

procedure TMainForm.SynEditEditorChange(Sender: TObject);
begin
  ActionFileSave.Enabled := true;
end;

function TMainForm.HandleUnsavedChanges: TModalResult;
begin
  while ActionFileSave.Enabled do begin
    Result := MessageDlg('Unsaved Changes Detected','There are unsaved change in the editor.' +
      LineEnding + 'Do you want to save it first?',mtConfirmation,mbYesNoCancel,0);
    if Result = mrYes then
      ActionFileSaveExecute(nil)
    else
      Break;
  end;
end;

procedure TMainForm.OpenFile(const AFileName: String);
begin
  if HandleUnsavedChanges <> mrCancel then begin
    SynEditEditor.Lines.LoadFromFile(AFileName);
    FCurrentFileName := AFileName;
    ActionFileSave.Enabled := false;
    MemoLog.Lines.Clear;
    ImagePreview.Picture.Clear;
    ButtonSaveImage.Enabled := false;
  end;
end;

procedure TMainForm.SaveFile;
begin
  SynEditEditor.Lines.SaveToFile(FCurrentFileName);
  ActionFileSave.Enabled := false;
end;

procedure TMainForm.LogToMemo(const AMessage: String);
begin
  MemoLog.Lines.Text := MemoLog.Lines.Text + AMessage;
end;

procedure TMainForm.EnableControls(Sender: TObject);
begin
  ToggleControls(true);
end;

procedure TMainForm.ToggleControls(const AEnable: Boolean);
begin
  ActionFileNew.Enabled := AEnable;
  ActionFileOpen.Enabled := AEnable;
  ActionFileExecute.Enabled := AEnable;
end;

procedure TMainForm.DisplayImage(AStream: TStream);
begin
  ImagePreview.Picture.LoadFromStream(AStream);
  ButtonSaveImage.Enabled := true;
end;

end.

