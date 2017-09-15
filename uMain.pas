// ВНИМАНИЕ - ЭТО ПРИМЕР ПРИЛОЖЕНИЯ,
// НЕ ДЛЯ ИСПОЛЬЗОВАНИЯ В РЕАЛЬНЫХ ЗАДАЧАХ!!!
// MIT License
unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ES.BaseControls, ES.Switch,
  ES.Layouts, Vcl.ExtCtrls, ES.RegexControls, ES.Hints, ES.ExGraphics, System.Math;

type
  TIntType = (itForSteps, itForAccuracy, itMixed);
  TIntMethod = (imLeftRect, imRightRect, imTrapeze, imSimpson);

  TFormMain = class(TForm)
    LayoutPrefs: TEsLayout;
    RadioGroupMethod: TRadioGroup;
    EditSteps: TEsRegexEdit;
    LabelSteps: TLabel;
    LayoutFunction: TEsLayout;
    LabelB: TLabel;
    EditB: TEsRegexEdit;
    LabelA: TLabel;
    EditA: TEsRegexEdit;
    LayoutAns: TEsLayout;
    EditAns: TEdit;
    LabelAns: TLabel;
    EditFunction: TEdit;
    LabelFunction: TLabel;
    LabelAccuracy: TLabel;
    EditAccuracy: TEsRegexEdit;
    RadioGroupType: TRadioGroup;
    LayoutPrefsContainer: TEsLayout;
    LayoutSteps: TEsLayout;
    LayoutAccuracy: TEsLayout;
    Bevel1: TBevel;
    Bevel2: TBevel;
    LabelAbout: TLabel;
    Bevel3: TBevel;
    procedure FormCreate(Sender: TObject);
    procedure RadioGroupMethodClick(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure RadioGroupTypeClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    a, b: Double;
    Steps: Integer;
    Accuracy: Double;
    IntMethod: TIntMethod;
    Func: AnsiString;
    IntType: TIntType;

    IsCreating: Boolean;

    CalcThread: TThread;

    procedure Calc;
    function Fx(x: Double): Double;
    procedure PrintAns(s: string);
    procedure RealignLayouts;
    function EnterParams: Boolean;
    procedure TerminateCalcThread;
  public
    { Public declarations }
  end;

// parser dll
function function_x(exp: PAnsiChar; x_val: Double): Double; cdecl; external 'MathParserDll' name '_exp_function_x';
function is_syntax_error: Boolean; cdecl; external 'MathParserDll' name '_exp_is_syntax_error';

var
  FormMain: TFormMain;

implementation

uses
  CalcIntegral;

{$R *.dfm}

type TBadSyntax = class(Exception);

function TFormMain.Fx(x: Double): Double;
begin
  Result := function_x(PAnsiChar(Func), x);

  if is_syntax_error then
    raise TBadSyntax.Create('Синтаксическая ошибка');

  if IsNan(Result) then
    Result := 0;
end;

//procedure TFormMain.PaintBoxPaint(Sender: TObject);
//const
//  Size = 128;
//
//var
//  cx, cy: Integer;
//  w, h: integer;
//  c: Double;
//  maxY: Double;
//  minY: Double;
//  I, l: Integer;
//
//  function GetX(x: Integer): Double;
//  begin
//    Result := Fx((x / (w - 1)) * (b - a));
//  end;
//
//  function GetCy(x: Integer): Integer;
//  begin
//    Result := Trunc(h - (h / (maxY - minY)) * (GetX(I) - minY));
//  end;
//
//begin
//  try
//    w := MulDiv(Size, Self.GetParentCurrentDpi, 96) - 1;
//    h := PaintBox.Height - 1;
//    l := PaintBox.Width div 2 - w div 2;
//
//    maxY := GetX(0);
//    minY := maxY;
//    for I := 1 to w - 1 do
//    begin
//      c := GetX(I);
//      if c > maxY then
//        maxY := c;
//      if c < minY then
//        minY := c;
//    end;
//
//    if SameValue(maxY - minY, 0) then
//      Exit;
//
//    PaintBox.Canvas.Pen.Color := RGB(140, 140, 255);
//    PaintBox.Canvas.Pen.Style := TPenStyle.psSolid;
//    I := 0;
//    for cx := l to l + w do
//    begin
//      cy := GetCy(I);
//      PaintBox.Canvas.Line(cx, h, cx, cy);
//      Inc(I);
//    end;
//
//    cy := Trunc(h - (h / (maxY - minY)) * -minY);
//    PaintBox.Canvas.Pen.Color := clRed;
//    PaintBox.Canvas.Pen.Style := psDash;
//    PaintBox.Canvas.Brush.Style := bsClear;
//    PaintBox.Canvas.Line(l, cy, PaintBox.Width - l - 1 + 10, cy);
//    PaintBox.Canvas.Line(l, 0, l, h);
//  except
//    on TBadSyntax do;
//  end;
//end;

procedure TFormMain.Calc;
var
  IntFunc: TIntFunc;
begin
  // выходим если форма еще не настроена
  if IsCreating then
    Exit;

  // останавливаем вычислительный поток
  TerminateCalcThread;

  // попытка считать входные данные провалилась
  if not EnterParams then
    Exit;

  // создаем вычичлительный поток
  CalcThread := TThread.CreateAnonymousThread(procedure
  var
    Ans: Double;
  begin
    try
      PrintAns('Вычисление...');
      try
        case IntMethod of
          imLeftRect: IntFunc := IntLeftRect;
          imRightRect: IntFunc := IntRightRect;
          imTrapeze: IntFunc := IntTrapeze;
          imSimpson: IntFunc := IntSimpson;
        end;

        case IntType of
          itForSteps: Ans := IntFunc(Fx, a, b, Steps);
          itForAccuracy: Ans := IntDoubleCalc(IntFunc, Fx, a, b, Accuracy);
          itMixed: Ans := IntMixedCalc(Fx, a, b, Accuracy);
        end;

        // если поток остановили принудительно то сразу выходим
        if TThread.Current.CheckTerminated then
          Exit;

        // округляем
        if IntType in [itForAccuracy, itMixed] then
          Ans := RoundTo(Ans, -Ceil(-Ln(Accuracy) / Ln(10)));

        PrintAns(Ans.ToString);
      except
        on TBadSyntax do
            PrintAns('Формула некорректна!');

        on EIntNotConverge do
            PrintAns('Интеграл не сходится!');
      end;
    finally
      CalcThread := nil;
    end;
  end);

  // запускаем поток
  CalcThread.Start;
end;

procedure TFormMain.EditChange(Sender: TObject);
begin
  Calc;
end;

function TFormMain.EnterParams: Boolean;
begin
  Result := False;

  // integral
  Func := AnsiString(EditFunction.Text);
  a := function_x(PAnsiChar(AnsiString(EditA.Text)), 0);
  b := function_x(PAnsiChar(AnsiString(EditB.Text)), 0);
  if IsNaN(a) or IsNaN(b) or (a >= b) then
  begin
    PrintAns('Ошибка, неверно указан отрезок [a, b]');
    Exit;
  end;

  // steps
  if IntType = itForSteps then
    try
      Steps := StrToInt(EditSteps.Text);

      if (Steps < 10) or (Steps > 100000) then
        raise Exception.Create('');
    except
      PrintAns('Ошибка, допустимый диапазон шагов: 10...100000');
      Exit;
    end
  else
  // accuracy
    try
      Accuracy := StrToFloat(EditAccuracy.Text);

      if (Accuracy > 1) or (Accuracy < 0.00000001) then
        raise Exception.Create('');
    except
      PrintAns('Ошибка, допустимый диапазон точности: 1-0.00000001');
      Exit;
    end;

  Result := True;
end;

procedure TFormMain.PrintAns(s: string);
begin
  TThread.Synchronize(TThread.Current, procedure
  begin
    EditAns.Text := s;
  end);
end;

procedure TFormMain.FormCreate(Sender: TObject);
  procedure Defaults;
  begin
    a := 0;
    b := 1;
    Accuracy := 0.0001;
    Steps := 100;
    IntMethod := imLeftRect;
    IntType := itForSteps;
    Func := 'sin(x)';
  end;

begin
  IsCreating := True;

  FormatSettings.DecimalSeparator := '.';

  Defaults;

  // integral
  EditFunction.Text := string(Func);
  EditA.Text := FloatToStr(a);
  EditB.Text := FloatToStr(b);

  // prefs
  EditSteps.Text := IntToStr(Steps);
  EditAccuracy.Text := FloatToStr(Accuracy);
  RadioGroupMethod.ItemIndex := Integer(IntMethod);
  RadioGroupType.ItemIndex := Integer(IntType);

  IsCreating := False;

  Calc;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  ClientHeight := LabelAbout.BoundsRect.Bottom + LabelAbout.Margins.Bottom;
end;

procedure TFormMain.RadioGroupMethodClick(Sender: TObject);
begin
  IntMethod := TIntMethod(RadioGroupMethod.ItemIndex);
  Calc;
end;

procedure TFormMain.RadioGroupTypeClick(Sender: TObject);
begin
  IntType := TIntType(RadioGroupType.ItemIndex);
  RealignLayouts;
  Calc;
end;

procedure TFormMain.RealignLayouts;
begin
  case IntType of

    itForSteps:
    begin
      LayoutSteps.Visible := True;
      LayoutAccuracy.Visible := False;
      RadioGroupMethod.Visible := True;
    end;

    itForAccuracy:
    begin
      LayoutSteps.Visible := False;
      LayoutAccuracy.Visible := True;
      RadioGroupMethod.Visible := True;
    end;

    itMixed:
    begin
      LayoutSteps.Visible := False;
      LayoutAccuracy.Visible := True;
      RadioGroupMethod.Visible := False;
    end;
  end;

  // сортируем
  LayoutAccuracy.Top := 0;
  LayoutSteps.Top := 0;
  RadioGroupMethod.Top := 0;

  ClientHeight := LabelAbout.BoundsRect.Bottom + LabelAbout.Margins.Bottom;
end;

// оповещаем поток о завершении и ждем пока он завершиться
procedure TFormMain.TerminateCalcThread;
begin
  if CalcThread <> nil then
  begin
    CalcThread.Terminate;
    while(CalcThread <> nil) do
      Sleep(0);
  end;
end;

end.
