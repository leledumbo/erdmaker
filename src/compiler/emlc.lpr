program emlc;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, IOStream,
  emllexer, emlparser, emlast, emlcopt, emlerrors;

var
  InputStream: TStream;
  i: Integer;
  CodeLines: TStringList;
  Lexer: TEMLLexer;
  Parser: TEMLParser;
  AST: TEMLERD;
  Errors: TEMLErrorList;
begin
  if not HelpOption.IsSet then
    try
      try
        if InputFileOption.IsSet then
          InputStream := TFileStream.Create(InputFileOption.Name,fmOpenRead)
        else
          InputStream := TIOStream.Create(iosInput);
        Errors := TEMLErrorList.Create(true);
        Lexer := TEMLLexer.Create(InputStream,Errors);
        Parser := TEMLParser.Create(Lexer,Errors);
        AST := Parser.Parse;
        if Errors.Count > 0 then
          for i := 0 to Errors.Count - 1 do
            WriteLn(StdErr,InputFileOption.Name + ' ' + Errors[i].Message)
        else
          try
            CodeLines := TStringList.Create;
            AST.GetCode(CodeLines);
            if OutputFileOption.IsSet then
              with TFileStream.Create(OutputFileOption.Name,fmCreate) do
                try
                  Write(CodeLines.Text[1],Length(CodeLines.Text));
                finally
                  Free;
                end
            else
              WriteLn(CodeLines.Text);
          finally
            CodeLines.Free;
          end;
      finally
        AST.Free;
        Parser.Free;
        Lexer.Free;
        Errors.Free;
        InputStream.Free;
      end;
    except
      on e: Exception do begin
        WriteLn(StdErr,e.Message);
      end;
    end;
end.

