Unit AdvancedCrtControl;   {Advanced Graphics in Crt Mode}

{Information
* Code Size = 7858
* Data Size = 4
* StackSize = 0
* Number of Lines = 822}

Interface
Uses KeyboardControl;
Type ButtonCaption=String[16];
     ExitMode=(NormalExit,CancelExit,TabExit,Working,ByPassed);
     DataType=(Numeric,TextOnly,Mixed);
     Str75=String[75];

(*****************************************************************************
Object Button:
* Description - Allow to user create buttons with professional aparence.
* Internal variables and proper use of then:
1)Button Caption - A string that contain the caption of the button;
2)ButtonColor and ButtonTextColor - Hold the attributes of the button (i.e.co-
lor and background;
3)ShortCutColor - The color assigned to the "shortcut key";
4)ShortCutKey - Hold the current shortcut key, always is the first character
of button caption;
5)PosX,PosY - The coordinates of the button;
6)CurrentBack - Current background hold the background color of the window,
this is used internaly by the intrinsic methods.
* Internal Methods:
1)Procedure Init - Initialize some default options;
2)Procedure SetDefaultOptions - This procedure is a powerfull toll to select
the most common options for buttons saving a lot of time;
3)Procedure DrawButton - Draw button with selected options and initialize the
shortcut key;
4)Procedure RunButton - This will animate the button and you can start the e-
vent associated with the button down action.
*****************************************************************************)

     Button=Object
     ButtonCaption:ButtonCaption;
     ButtonColor,ButtonTextColor:Byte;
     ShortCutColor:Byte;
     ShortCutKey:Char;
     XPos,YPos,CurrentBack:Byte;
     Procedure Init;
     Procedure SetDefaultOptions(Choice:Byte);
     Procedure DrawButton;
     Procedure RunButton;
     End;

(*****************************************************************************
Object DataBox:
* Description - Allow to user create imput boxes with good aparence and can
read strings up to 255 characters shifting right the string in the predefined
window.
* Internal variables and proper use of then:
1)X1,Y1,X2 - This variables point to the current position of the box, and de-
fine the total length of the window through X2. Length:=(X2-X1);
2)BoxColor,BoxTextColor - The attributes of data imput box;
3)ArrowColor - The color of the arrow that indicates a string too long and
could't showed. A good option is (LightGreen+Blink);
4)BoxText - Hold the current string on the box;
5)ExitMode - This is similar to Pascal's ExitCode and indicates the status of
last exit operation;
6)ByPassKeys - An array  that contain the codes assigned to keys that can in-
terrupt  the  current  action of databox. After interrupt you MUST return the
command to databox;
7)ByPassedKey - This variable hold the scancode for bypassedkeys and you will
use this to take the correct action;
8)UseMouse - Set it to TRUE if you want to use a mouse. I'ts FALSE by default;
9)MouseByPass - Hold  the  coordinates  designed to exit temporaly of the box
procedure. The form is Xmin..Xmax,Y; make sure the mouse is INSTALED;
10)MouseByPassed - After  the procedure  is exited, the ExitMode is set to By-
Passed and this variable hold the current mouse position.
* Internal Methods:
1)Procedure Init - Initialize the variables. Important: you MUST call this rou
tine JUST ONE TIME or the variables will be trashed;
2)Procedure DataBox - Draw  the  box and  read the string. Return the ExitMode
and the current string. Suported keys are:
- Esc
- Enter
- Number and Text keys
- Tab
- BackSpace
- SpaceBar
*****************************************************************************)

     DataBox=Object
     X1,Y1,X2:Byte;
     BoxColor,BoxTextColor,ArrowColor:Byte;
     BoxText:String;
     ExitMode:ExitMode;
     ByPassKeys:Array [1..15] Of Keys;
     ByPassedKey:Keys;
     UseMouse:Boolean;
     MouseByPass:Array [1..15,1..3] Of Byte; {Xmin,Xmax,Y}
     MouseByPassed:Array [1..2] Of Byte;     {X,Y}
     Procedure Init;
     Procedure OpenDataBox;
     End;

(*****************************************************************************
Object FixedDataBox:
* Description - Allow to user create imput boxes with good aparence and can
read strings up to 75 characters. It's analog to DataBox except to the fact
that routine does not shift the string on window and support more keys then
DataBox.
* Internal variables and proper use of then:
1)X1,Y1,X2 - This variables point to the current position of the box, and de-
fine the total length of the window through X2. Length:=(X2-X1);
2)BoxColor,BoxTextColor - The attributes of data imput box;
3)BoxText - Hold the current string on the box;
4)ExitMode - This is similar to Pascal's ExitCode and indicates the status of
last exit operation;
5)ByPassKeys - An array  that contain the codes assigned to keys thar can in-
terrupt  the  current  action of databox. After interrupt you MUST return the
command to databox;
6)ByPassedKey - This variable hold the scancode for bypassedkeys and you will
use this to take the correct action;
7)DataType - Filter the keys pressed; use Text for text-only strings, Numeric
for number-only strings and Mixed for free strings;
8)Masked - If is set to TRUE then the normal characters will be displayed as a
'*'. This is a powerfull  feature  to read confidential information like pass-
words etc;
9)UseMouse - Set it to TRUE if you want to use a mouse. I'ts FALSE by default;
10)MouseByPass - Hold  the  coordinates  designed to exit temporaly of the box
procedure. The form is Xmin..Xmax,Y; make sure the mouse is INSTALED;
11)MouseByPassed - After  the procedure  is exited, the ExitMode is set to By-
Passed and this variable hold the current mouse position.
* Internal Methods:
1)Procedure Init - Initialize the variables. Important: you MUST call this rou
tine JUST ONE TIME or the variables will be trashed;
2)Procedure DataBox - Draw  the  box and  read the string. Return the ExitMode
and the current string. Suported keys are:
- Esc
- Enter
- Number and Text keys
- Tab
- BackSpace
- SpaceBar
- ArrowKeys
- HomeKey
- EndKey
- DeleteKey
*****************************************************************************)

     FixedDataBox=Object
     X1,Y1,X2:Byte;
     BoxColor,BoxTextColor:Byte;
     BoxText:Str75;
     ExitMode:ExitMode;
     ByPassKeys:Array [1..15] Of Keys;
     ByPassedKey:Keys;
     DataType:DataType;
     Masked:Boolean;
     UseMouse:Boolean;
     MouseByPass:Array [1..15,1..3] Of Byte; {Xmin,Xmax,Y}
     MouseByPassed:Array [1..2] Of Byte;     {X,Y}
     Procedure Init;
     Procedure OpenDataBox;
     End;
(*************************** Stand-Alone Routines ***************************)
{This routine is analog to the ShowMessage of Borland Delphi}
Procedure MessageBox(X1,Y1,X2,Y2:Byte;Title,Message:String);
{This routine draw's a TVision window style}
Procedure DrawWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
(****************************************************************************)

Implementation
Uses Crt,CrtControl,MouseControl;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'AdvancedCRTControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Procedure Button.Init;
Begin
ButtonCaption:='';
ButtonColor:=0;
ButtonTextColor:=0;
ShortCutColor:=0;
ShortCutKey:='O';
XPos:=0;
YPos:=0;
End;

Procedure Button.SetDefaultOptions(Choice:Byte);
Begin
ButtonColor:=Green;
ButtonTextColor:=Yellow;
ShortCutColor:=LightCyan;
ShortCutKey:='O';
  Case Choice Of
    1:ButtonCaption:='   Ok   ';
    2:ButtonCaption:='  Help  ';
    3:ButtonCaption:=' Cancel ';
    4:ButtonCaption:=' Ajuda ';
    5:ButtonCaption:=' Cancelar ';
  End;
End;

Procedure Button.DrawButton;
Var Base:String[16];
    i:Byte;
    Done:Boolean;
Const BaseSymbol='ß';
      RightSymbol='Ü';
Begin
Base:='';
Done:=False;
  For i:=1 To Length(ButtonCaption) Do Begin
  Base:=Base+BaseSymbol;
  End;
GoToXY(XPos,YPos);
TextColor(ButtonTextColor);
TextBackGround(ButtonColor);
  For i:=1 To Length(ButtonCaption) Do Begin
    If ((ButtonCaption[i]<>' ') And (Not Done)) Then Begin
    TextColor(ShortCutColor);
    Write(ButtonCaption[i]);
    ShortCutKey:=ButtonCaption[i];
    TextColor(ButtonTextColor);
    Done:=True;
    End
      Else Begin
      Write(ButtonCaption[i]);
      End;
  End;
TextColor(Black);
TextBackGround(CurrentBack);
GoToXY((XPos+1),(YPos+1));
Write(Base);
GoToXY((WhereX-1),(WhereY-1));
Write(RightSymbol);
End;

Procedure Button.RunButton;
Var Base:String[16];
    i:Byte;
Begin
Base:='';
  For i:=1 To Length(ButtonCaption) Do Begin
  Base:=Base+' ';
  End;
GoToXY(XPos,YPos);
TextBackGround(CurrentBack);
Write(' ');
TextBackGround(ButtonColor);
TextColor(ButtonTextColor);
Write(ButtonCaption);
TextBackGround(CurrentBack);
GoToXY((XPos+1),(YPos+1));
Write(Base);
End;

Procedure MessageBox(X1,Y1,X2,Y2:Byte;Title,Message:String);
Var Bt:Button;
    M:Mouse;
    S:Screen;
    Keyb:Keyboard;
    Continue,ExitOK:Boolean;
    ActiveX,ActiveY:Byte;
Begin
Bt.Init;
M.Init;
S.Init;
Keyb.Init;
Window((X1+1),Y1,(X2+3),(Y2+2));
TextBackGround(Black);
ClrScr;
S.TitleWindow(X1,Y1,X2,Y2,White,White,Title);
Window((X1-1),(Y1-1),(X2+1),(Y2+1));
GoToXY(3,1);
Write('[');
TextColor(LightGreen);
Write('þ');
TextColor(White);
Write(']');
Window(X1,Y1,X2,Y2);
GoToXY(3,2);
TextColor(Black);
Write(Message);
Bt.XPos:=((X2-X1)-6) Div 2;
Bt.YPos:=((Y2-Y1));
Bt.CurrentBack:=White;
Bt.SetDefaultOptions(1);
Bt.DrawButton;
ActiveX:=(Bt.XPos+X1-1);
ActiveY:=(Bt.YPos+Y1-1);
Continue:=False;
ExitOK:=True;
  Repeat {Infinite Loop}
    If KeyPressed Then Begin
    Keyb.InKey;
      If (Keyb.Key=Esc) Or (Keyb.Key=Enter) Or (UpCase(Keyb.Ch)=Bt.ShortCutKey) Then Begin
      Bt.RunButton;
      Delay(100);
      Bt.DrawButton;
      Delay(50);
      Exit;
      End;
    End;
  M.GetMouseState;
    If (M.Bt=1) Then Begin
      If (M.X In [ActiveX..ActiveX+Length(Bt.ButtonCaption)-1]) And (M.Y=ActiveY) Then Begin
      Bt.RunButton;
        While (M.Bt=1) Do Begin
        M.GetMouseState;
        End;
      Bt.DrawButton;
      Delay(100);
      Exit;
      End;
        If (M.X=(X1+2)) And (M.Y=Y1-1) Then Begin
        TextColor(LightRed);
        Window((X1-1),(Y1-1),(X2+1),(Y2+1));
        GoToXY(4,1);
        Write('*');
          While (M.Bt=1) Do Begin
          M.GetMouseState;
          End;
        GoToXY(4,1);
        TextColor(LightGreen);
        Write('þ');
        Delay(100);
        Exit;
        End;
    End;
  Until Continue;
End;

Procedure DrawWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
Var S:Screen;
Begin
S.Init;
S.CursorSize:=Small;
S.Cursor;
S.TitleShadedWindow(X1,Y1,X2,Y2,FColor,BColor,Title);
Window((X1-1),(Y1-1),(X2+1),(Y2+1));
GoToXY(4,2);
Write('[');
TextColor(LightGreen);
Write('þ');
TextColor(White);
Write(']');
Window(X1,Y1,X2,Y2);
End;

Procedure DataBox.Init;
Begin
BoxText:='';
BoxColor:=Blue;
BoxTextColor:=White;
ArrowColor:=(LightGreen+Blink);
ExitMode:=Working;
FillChar(ByPassKeys,SizeOf(ByPassKeys),NullKey);
UseMouse:=False;
FillChar(MouseByPass,SizeOf(MouseByPass),100);
End;

Procedure DataBox.OpenDataBox;
Var i,Aux:Byte;
    K:Keyboard;
    M:Mouse;
    TempStr:String;
Const CharCont:Byte=0; {Current Number of Chars on Text}
      StrPos:Byte=0;   {Current position of cursor on Text}

      Procedure WriteArrow;
      Var TempX:Byte;
      Begin
      TempX:=WhereX;
      TextColor(ArrowColor);
      GoToXY(X1-1,Y1);
      Write(#17);
      TextColor(BoxTextColor);
      GoToXY(TempX,Y1);
      End;

      Procedure ArrowOff;
      Var TempX:Byte;
      Begin
      TempX:=WhereX;
      GoToXY(X1-1,Y1);
      Write(' ');
      GoToXY(TempX,Y1);
      End;
Begin
ExitMode:=Working;
ByPassedKey:=NullKey;
FillChar(MouseByPassed,SizeOf(MouseByPassed),100);
Aux:=(X2-X1);
StrPos:=Length(BoxText);
CharCont:=Length(BoxText);
K.Init;
M.Init;
TextBackGround(BoxColor);
TextColor(BoxTextColor);
  For i:=X1-1 To X2 Do Begin
  GoToXY(i,Y1);
  Write(' ');
  End;
GoToXY(X1,Y1);
  If (CharCont<=Aux) Then Begin
  Write(BoxText);
  End
    Else Begin
    WriteArrow;
    i:=(CharCont Mod Aux);
    TempStr:=Copy(BoxText,i+1,(CharCont-i));
    Write(TempStr);
    End;
  Repeat
    While (Not KeyPressed) And (UseMouse) Do Begin
    M.GetMouseState;
      If (M.Bt=1) Then Begin {Left Button Pressed}
        For i:=1 To 15 Do Begin
          If (MouseByPass[i,1]<>100) Then Begin
            If (M.X In [MouseByPass[i,1]..MouseByPass[i,2]]) And (M.Y=MouseByPass[i,3]) Then Begin
            MouseByPassed[1]:=M.X;
            MouseByPassed[2]:=M.Y;
            ExitMode:=ByPassed;
            Exit;
            End;
          End;
        End;
      End;
    End;
  K.Inkey;
    Case K.Key Of
    TextKey:Begin
        If (StrPos=255) Then Begin
        Sound(3000);
        Delay(1);
        NoSound;
        End;
      If (WhereX<X2) And (StrPos<255) Then Begin
      Insert(K.Ch,BoxText,StrPos+1);
      Write(K.Ch);
      Inc(CharCont);
      Inc(StrPos);
      End
        Else If (WhereX>=X2) And (StrPos<255) Then Begin
        WriteArrow;
        TempStr:=Copy(BoxText,(StrPos-Aux+2),(Aux-1));
        GoToXY(X1,Y1);
        Write(TempStr);
        Write(K.Ch);
        Insert(K.Ch,BoxText,StrPos+1);
        Inc(CharCont);
        Inc(StrPos);
        End;
    End;
      BkSp:Begin
        If (CharCont<=Aux) And (WhereX>X1) Then Begin
        ArrowOff;
        Delete(BoxText,StrPos,1);
        GoToXY((WhereX-1),Y1);
        Write(' ');
        Dec(CharCont);
        Dec(StrPos);
        GoToXY((WhereX-1),Y1);
        End
          Else If (CharCont>Aux) And (WhereX>X1) Then Begin
            If (CharCont=(Aux+1)) Then Begin
            ArrowOff;
            End;
          TempStr:=Copy(BoxText,(StrPos-Aux),Aux);
          GoToXY(X1,Y1);
          Write(TempStr);
          Delete(BoxText,StrPos,1);
          Dec(CharCont);
          Dec(StrPos);
          End;
      End;
        Enter:Begin
        ExitMode:=NormalExit;
        Exit;
        End;
          Esc:Begin
          BoxText:='';
          ExitMode:=CancelExit;
            For i:=X1-1 To X2 Do Begin
            GoToXY(i,Y1);
            Write(' ');
            End;
          GoToXY(X1,Y1);
          Exit;
          End;
            Tab:Begin
            ExitMode:=TabExit;
            Exit;
            End;
              NumberKey:Begin
                  If (StrPos=255) Then Begin
                  Sound(3000);
                  Delay(1);
                  NoSound;
                  End;
                If (WhereX<X2) And (StrPos<255) Then Begin
                Insert(K.Ch,BoxText,StrPos+1);
                Write(K.Ch);
                Inc(CharCont);
                Inc(StrPos);
                End
                  Else If (WhereX>=X2) And (StrPos<255) Then Begin
                  TempStr:=Copy(BoxText,(StrPos-Aux+2),(Aux-1));
                  GoToXY(X1,Y1);
                  Write(TempStr);
                  Write(K.Ch);
                  Insert(K.Ch,BoxText,StrPos+1);
                  Inc(CharCont);
                  Inc(StrPos);
                  End;
              End;
                Space:Begin
                  If (WhereX<X2) And (StrPos<255) Then Begin
                  Insert(K.Ch,BoxText,StrPos+1);
                  Write(K.Ch);
                  Inc(CharCont);
                  Inc(StrPos);
                  End
                    Else If (WhereX>=X2) And (StrPos<255) Then Begin
                    TempStr:=Copy(BoxText,(StrPos-Aux+2),(Aux-1));
                    GoToXY(X1,Y1);
                    Write(TempStr);
                    Write(K.Ch);
                    Insert(K.Ch,BoxText,StrPos+1);
                    Inc(CharCont);
                    Inc(StrPos);
                    End;
                End;
    End; {Case End}
      For i:=1 To 15 Do Begin
        If (ByPassKeys[i]<>NullKey) Then Begin
          If (ByPassKeys[i]=K.Key) Then Begin
          ExitMode:=ByPassed;
          ByPassedKey:=K.Key;
          Exit;
          End;
        End;
      End;
  Until (CharCont=-1); {Infinite Loop}
End;

Procedure FixedDataBox.Init;
Begin
BoxText:='';
BoxColor:=Blue;
BoxTextColor:=White;
ExitMode:=Working;
DataType:=Mixed;
Masked:=False;
UseMouse:=False;
FillChar(ByPassKeys,SizeOf(ByPassKeys),NullKey);
FillChar(MouseByPass,SizeOf(MouseByPass),100);
End;

Procedure FixedDataBox.OpenDataBox;
Var i,Aux,TempX:Byte;
    K:Keyboard;
    TempStr:Str75;
    M:Mouse;
Const CharCont:Byte=0;
      StrPos:Byte=0;
Begin
ExitMode:=Working;
ByPassedKey:=NullKey;
FillChar(MouseByPassed,SizeOf(MouseByPassed),100);
Aux:=(X2-X1);
TextColor(BoxTextColor);
TextBackGround(BoxColor);
StrPos:=Length(BoxText);
CharCont:=Length(BoxText);
K.Init;
M.Init;
  For i:=(X1-1) To (X2+1) Do Begin
  GoToXY(i,Y1);
  Write(' ');
  End;
GoToXY(X1,Y1);
  If Not Masked Then Begin
  Write(BoxText);
  End
    Else Begin
      For i:=1 To CharCont Do Begin
      Write('*');
      End;
    End;
  Repeat
    While (Not KeyPressed) And (UseMouse) Do Begin
    M.GetMouseState;
      If (M.Bt=1) Then Begin {Left Button Pressed}
        For i:=1 To 15 Do Begin
          If (MouseByPass[i,1]<>100) Then Begin
            If (M.X In [MouseByPass[i,1]..MouseByPass[i,2]]) And (M.Y=MouseByPass[i,3]) Then Begin
            MouseByPassed[1]:=M.X;
            MouseByPassed[2]:=M.Y;
            ExitMode:=ByPassed;
            Exit;
            End;
          End;
        End;
      End;
    End;
  K.InKey;
    Case K.Key Of
      TextKey:Begin
          If (DataType=Mixed) Or (DataType=TextOnly) Then Begin
        If (CharCont<=Aux) Then Begin
          If (StrPos=CharCont) Then Begin
          Insert(K.Ch,BoxText,(CharCont+1));
            If Masked Then Begin
            Write('*');
            End
              Else Begin
              Write(K.Ch);
              End;
          Inc(CharCont);
          Inc(StrPos);
          End
            Else Begin
              If (CharCont<=Aux) Then Begin
              Insert(K.Ch,BoxText,(StrPos+1));
              TempX:=WhereX;
                If Not Masked Then Begin
                GoToXY(X1,Y1);
                Write(BoxText);
                End
                  Else Begin
                  GoToXY(X1+CharCont,Y1);
                  Write('*');
                  End;
              GoToXY(TempX+1,Y1);
              Inc(CharCont);
              Inc(StrPos);
              End;
            End;
        End
          Else Begin
          Sound(3000);
          Delay(1);
          NoSound;
          End;
            End;
      End;
        LeftArrow:Begin
          If (WhereX>X1) And (CharCont>=1) Then Begin
          GoToXY(WhereX-1,Y1);
          Dec(StrPos);
          End;
        End;
          RightArrow:Begin
            If (WhereX<=X2) And (CharCont>=1) Then Begin
              If (StrPos<CharCont) Then Begin
              GoToXY(WhereX+1,Y1);
              Inc(StrPos);
              End;
            End;
          End;
            BkSp:Begin
              If (StrPos=CharCont) And (CharCont<=Aux+1) And (CharCont>0) Then Begin
              Delete(BoxText,StrPos,1);
              GoToXY((WhereX-1),Y1);
              Write(' ');
              GoToXY((WhereX-1),Y1);
              Dec(StrPos);
              Dec(CharCont);
              End
                Else If (StrPos<CharCont) And (WhereX>X1) Then Begin
                TempX:=WhereX;
                Delete(BoxText,StrPos,1);
                  If Not Masked Then Begin
                    For i:=X1 To X2 Do Begin
                    GoToXY(i,Y1);
                    Write(' ');
                    End;
                  GoToXY(X1,Y1);
                  Write(BoxText);
                  End
                    Else Begin
                    GoToXY(X1+CharCont-1,Y1);
                    Write(' ');
                    End;
                GoToXY(TempX-1,Y1);
                Dec(StrPos);
                Dec(CharCont);
                End;
            End;
              DeleteKey:Begin
                If (StrPos=(CharCont-1)) And (CharCont>0) Then Begin
                Delete(BoxText,CharCont,1);
                Write(' ');
                GoToXY((WhereX-1),Y1);
                Dec(CharCont);
                End
                  Else If (StrPos<(CharCont-1)) And (WhereX>=X1) Then Begin
                  TempX:=WhereX;
                  Delete(BoxText,(StrPos+1),1);
                    If Not Masked Then Begin
                      For i:=X1 To X2 Do Begin
                      GoToXY(i,Y1);
                      Write(' ');
                      End;
                    GoToXY(X1,Y1);
                    Write(BoxText);
                    End
                      Else Begin
                      GoToXY(X1+CharCont-1,Y1);
                      Write(' ');
                      End;
                  GoToXY(TempX,Y1);
                  Dec(CharCont);
                  End;
              End;
                HomeKey:Begin
                  If (CharCont>0) And (StrPos>0) Then Begin
                  GoToXY(X1,Y1);
                  StrPos:=0;
                  End;
                End;
                  EndKey:Begin
                    If (CharCont>0) And (StrPos<CharCont) Then Begin
                    GoToXY((X1+CharCont),Y1);
                    StrPos:=CharCont;
                    End;
                  End;
                    NumberKey:Begin
                        If (DataType=Mixed) Or (DataType=Numeric) Then Begin
                      If (CharCont<=Aux) Then Begin
                        If (StrPos=CharCont) Then Begin
                        Insert(K.Ch,BoxText,(CharCont+1));
                          If Not Masked Then Begin
                          Write(K.Ch);
                          End
                            Else Begin
                            Write('*');
                            End;
                        Inc(CharCont);
                        Inc(StrPos);
                        End
                          Else Begin
                            If (CharCont<=Aux) Then Begin
                            Insert(K.Ch,BoxText,(StrPos+1));
                            TempX:=WhereX;
                              If Not Masked Then Begin
                              GoToXY(X1,Y1);
                              Write(BoxText);
                              End
                                Else Begin
                                GoToXY(X1+CharCont,Y1);
                                Write('*');
                                End;
                            GoToXY(TempX+1,Y1);
                            Inc(CharCont);
                            Inc(StrPos);
                            End;
                          End;
                      End
                        Else Begin
                        Sound(3000);
                        Delay(1);
                        NoSound;
                        End;
                          End;
                    End;
                      Enter:Begin
                      ExitMode:=NormalExit;
                      Exit;
                      End;
                        Esc:Begin
                        BoxText:='';
                        ExitMode:=CancelExit;
                          For i:=X1-1 To X2 Do Begin
                          GoToXY(i,Y1);
                          Write(' ');
                          End;
                        GoToXY(X1,Y1);
                        Exit;
                        End;
                          Tab:Begin
                          ExitMode:=TabExit;
                          Exit;
                          End;
                            Space:Begin
                                If (DataType<>Numeric) Then Begin
                              If (WhereX<=X2) And (CharCont<=Aux) Then Begin
                              TempX:=WhereX;
                              Insert(K.Ch,BoxText,StrPos+1);
                                If Not Masked Then Begin
                                  For i:=X1 To X2 Do Begin
                                  GoToXY(i,Y1);
                                  Write(' ');
                                  End;
                                GoToXY(X1,Y1);
                                Write(BoxText);
                                End
                                  Else Begin
                                  GoToXY(X1+CharCont,Y1);
                                  Write('*');
                                  End;
                              GoToXY(TempX+1,Y1);
                              Inc(CharCont);
                              Inc(StrPos);
                              End
                                Else Begin
                                Sound(3000);
                                Delay(1);
                                NoSound;
                                End;
                                  End;
                            End;
    End; {Case End}
      For i:=1 To 15 Do Begin
        If (ByPassKeys[i]<>NullKey) Then Begin
          If (ByPassKeys[i]=K.Key) Then Begin
          ExitMode:=ByPassed;
          ByPassedKey:=K.Key;
          Exit;
          End;
        End;
      End;
  Until (CharCont=-1); {Infinite Loop}
End;

Begin
CopyRight;
End.
