// errorsoft(c)
// MIT License
// this unit is thread safe
unit CalcIntegral;

interface

uses
  System.SysUtils;

type
  // �� ���������� ��������
  EIntNotConverge = class(Exception);
  // ������������� �������
  TXFunc = reference to function (x: Double): Double;
  // ������� ����������� �������� ��� "n" �����
  TIntFunc = function(fx: TXFunc; a, b: Double; n: Integer): Double;

const
  // ��������� ���������� ��������� ��� ������� � ���������� �����
  DefualtN = 20;
  // ��������� �������
  DefaultTimeOut = 60000;// 60 seconds

// ����� ����� ���������������
function IntLeftRect(fx: TXFunc; a, b: Double; n: Integer): Double;

// ����� ������ ���������������
function IntRightRect(fx: TXFunc; a, b: Double; n: Integer): Double;

// ����� ��������� ���������������
function IntMedianRect(fx: TXFunc; a, b: Double; n: Integer): Double;

// ����� ��������
function IntTrapeze(fx: TXFunc; a, b: Double; n: Integer): Double;

// ����� ��������(�������)
function IntSimpson(fx: TXFunc; a, b: Double; n: Integer): Double;

// ������� ��������
function IntDoubleCalc(IntFunc: TIntFunc; fx: TXFunc; a, b: Double; Epsilon: Double;
  n: Integer = DefualtN): Double;

// mixed function
function IntMixedCalc(fx: TXFunc; a, b: Double; Epsilon: Double;
  n: Integer = DefualtN): Double;

// ���������� ���-�� ��������� ��� ���������� ������������ ���������
function GetLastInterationCount: Integer;

// �������
threadvar
  TimeOut: Integer;

implementation

uses
  System.Classes, System.Math, System.Diagnostics;

threadvar
  InterationCount: Integer;
  Time: TStopwatch;

function GetLastInterationCount: Integer;
begin
  Result := InterationCount;
end;

// ���������� true ���� ����� "����"
function IsTerminated: Boolean; inline;
begin
  Result := TThread.Current.CheckTerminated;
end;

procedure StartCalculation;
begin
  Time := TStopwatch.StartNew;
end;

function IsTimeOut: Boolean;
begin
  Result := Time.ElapsedMilliseconds > DefaultTimeOut;
end;

function IntLeftRect(fx: TXFunc; a, b: Double; n: Integer): Double;
var
  x, s, h: Double;
begin
  s := 0;

  h := (b - a) / n;
  x := a;

  while x < b do
  begin
    s := s + fx(x);
    x := x + h;

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  end;

  Result := h * s
end;

function IntRightRect(fx: TXFunc; a, b: Double; n: Integer): Double;
var
  x, s, h: Double;
begin
  s := 0;

  h := (b - a) / n;
  x := a + h;

  while x < b + h do
  begin
    s := s + fx(x);
    x := x + h;

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  end;

  Result := h * s
end;

function IntMedianRect(fx: TXFunc; a, b: Double; n: Integer): Double;
var
  x, s, h: Double;
begin
  s := 0;

  h := (b - a) / n;
  x := a + h * 0.5;

  while x < b do
  begin
    s := s + fx(x);
    x := x + h;

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  end;

  Result := h * s
end;

function IntTrapeze(fx: TXFunc; a, b: Double; n: Integer): Double;
var
  y1, y2: Double;
  x, s, h: Double;
begin
  s := 0;

  h := (b - a) / n;

  y1 := fx(a);
  y2 := fx(b);

  x := a + h;
  while x < b do
  begin
    s := s + fx(x);
    x := x + h;

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  end;

  Result := h * ((y1 + y2) / 2 + s)
end;

function IntSimpson(fx: TXFunc; a, b: Double; n: Integer): Double;
var
  h: Double;
  s: Double;
  i: Integer;

begin
  h := (b - a) / n;
  s := 0;

  i := 1;
  while i <= n - 1 do
  begin
    s := s + fx(a + (i + 1) * h) + fx(a + (i - 1) * h);// s1
    s := s + 4 * fx(a + i * h);// s2

    i := i + 2;

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  end;

  Result := s * (h / 3);
end;

function IntDoubleCalc(IntFunc: TIntFunc; fx: TXFunc; a, b: Double; Epsilon: Double;
  n: Integer = DefualtN): Double;
var
  s, s2: Double;
begin
  StartCalculation;
  InterationCount := n;

  s2 := IntFunc(fx, a, b, n);
  repeat
    s := s2;
    n := n * 2;
    s2 := IntFunc(fx, a, b, n);

    Inc(InterationCount, n);

    // ���� ���������� ���������� ������� �����, �� �������� �� ���������
    if IsTimeOut then
      raise EIntNotConverge.Create('Integral does not converge');

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  until Abs(s - s2) <= Epsilon;

  Result := s2;
end;

//      ______  ______  ______  ______
//     /      \/      \/      \/      \ <- s1
// (a)*---$---*---$---*---$---*---$---*---$---#(b)
//   -->  \______/\______/\______/\______/ <- s2
//  shift
// �����������������
function IntMixedCalc(fx: TXFunc; a, b: Double; Epsilon: Double;
  n: Integer = DefualtN): Double;

  function Int(fx: TXFunc; a, b: Double; n: Integer; IsShift: Boolean): Double;
  var
    x, s, h: Double;
  begin
    s := 0;

    h := (b - a) / n;
    x := a;

    if IsShift then
      x := x + h * 0.5;

    while x < b do
    begin
      s := s + fx(x);
      x := x + h;

      // ���� ����� "����" ������� �� ������� �� ����������
      if IsTerminated then
        Exit(NaN);
    end;

    Result := s;
  end;

var
  s: Double;
  i1, i2: Double;
  ns: Integer;
begin
  StartCalculation;
  InterationCount := n * 2;


  s := Int(fx, a, b, n, False);
  s := s + Int(fx, a, b, n, True);
  ns := 0;
  i1 := s;
  repeat
    i2 := i1;

    ns := ns + n * 2;
    n := n * 2;

    s := s + Int(fx, a, b, n, True);

    i1 := s * ((b - a) / ns);

    Inc(InterationCount, n);

    // ��������� �� ����������
    if IsTimeOut then
      raise EIntNotConverge.Create('Integral does not converge');

    // ���� ����� "����" ������� �� ������� �� ����������
    if IsTerminated then
      Exit(NaN);
  until Abs(i1 - i2) <= Epsilon;

  Result := i1;
end;

initialization
  TimeOut := DefaultTimeOut;

end.
