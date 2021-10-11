program Unerase;

{%ToDo 'Unerase.todo'}

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  FileDetails in 'FileDetails.pas' {FileDetailsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'NTFS File Recovery';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFileDetailsForm, FileDetailsForm);
  Application.Run;
end.
