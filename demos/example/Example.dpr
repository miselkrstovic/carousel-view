program Example;

uses
  Forms,
  main in 'main.pas' {frmMain} ,
  JvCarouselView in '..\..\src\JvCarouselView.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
