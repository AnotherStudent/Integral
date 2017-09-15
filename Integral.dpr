program Integral;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {FormMain},
  Vcl.Themes,
  Vcl.Styles,
  CalcIntegral in 'CalcIntegral.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
