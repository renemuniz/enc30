Unit CrtControl;    {OOP Crt Implementation}

{Information:
* Code Size = 5660 Bytes
* Stack Size = 0 Bytes
* Data Size = 0 Bytes
* Number of lines = 727}

Interface
Type CardType = (None,Mono,Cga,EgaMono,EgaColor,
              VgaMono,VgaColor,McgaMono,McgaColor);
     CursorType = (Big,Normal,Small);
     Str = String[80];
     ScreenBuffer = Array[0..1999] Of Word;

     Screen = Object
     VideoCard:CardType;
     CursorSize:CursorType;
     SavedWindow:Pointer;
     CurrentX,CurrentY:Byte;
     CurrentColor,CurrentBack:Byte;
     CurWinX,CurWinY:Word;
     Procedure Init;
     Procedure DetectVideo;
     Procedure Cursor;
     Procedure DosReturn;
     Procedure BackASCII(C:Char;FColor,BColor:Byte);
     Procedure FastWrite(X,Y:Byte;Var S:Str;FColor,BColor:Byte);
     Procedure SaveScreen;
     Procedure RestoreScreen;
     Procedure GoXY(X,Y:Byte);
     Procedure FastClrScr;
     Procedure SetBlink(TurnOn:Boolean);
     Procedure FastBox(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure SimpleBox(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure Center(Y,Z:Byte;S:Str);
     Procedure Back(Color:Byte);
     Procedure CompleteWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure CompleteSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure OpenWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure TitleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
     Procedure OpenSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure StatusBar(X,Y,Compr,CI,BI:Byte;Parc,Tot:Real);
     Procedure StatusDiskBar(X,Y,Compr,CI,BI:Byte;Parc,Tot:LongInt);
     Procedure Wait(Ms:Word);
     Procedure ShadedWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure ShadedSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
     Procedure TitleShadedWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
     Procedure ScrollUp(LSE,LSD,CSE,CSD,BackG:Byte);
     Procedure ScrollDown(LSE,LSD,CSE,CSD,BackG:Byte);
     Procedure ScrollTextLine(X1,X2:Integer;Y:Integer;St:String);
     Procedure Beep(Freq,Time:Word);
     Procedure HighLightText(Text:String;X,Y,FColor,BColor,HColor:Byte);
     Function IsVgaOrEga:Boolean;
     Function IsVga:Boolean;
     Function IsMono:Boolean;
     Function LocX:Byte;
     Function LocY:Byte;
     End;

Implementation
Uses Crt;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'CRTControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

{Initialize all variables}
Procedure Screen.Init;
Begin
CurrentX:=1;
CurrentY:=1;
VideoCard:=None;
CursorSize:=Small;
SavedWindow:=Nil;
End;
(*--------------------------------------------------*)
{Detects how is the video hardware present and put your type in videocard}
{variable}
Procedure Screen.DetectVideo;
Var Bh1,Bl1,Code:Byte;
Begin
  Asm
  Mov Ah,001Ah
  XOr Al,Al
  Mov Bl1,255d
  Int 10h
  Cmp Al,001Ah
  Jne @Error
  Mov Bl1,Bl
  @Error:
  End;
    If (Bl1<>255) Then Begin
      Case Bl1 Of
      $00 : VideoCard := None;       (* no Graphic card *)
      $01 : VideoCard := Mono;        (* monochrome *)
      $02 : VideoCard := CGA;        (* cga *)
      $04 : VideoCard := EGAColor;   (* ega color *)
      $05 : VideoCard := EGAMono;    (* ega mono*)
      $07 : VideoCard := VGAMono;    (* vga mono *)
      $08 : VideoCard := VGAColor;   (* vga color *)
      $0A,
      $0C : VideoCard := MCGAColor;  (* mcga color *)
      $0B : VideoCard := MCGAMono;   (* mcga mono *)
        Else Begin
        VideoCard := CGA;
        End;
      End;
    End
      Else Begin
        Asm
        Mov Code,255
        Mov Ah,12h
        Mov Bx,10h     {Ask for Ega display}
        Int 10h
        Cmp Bx,10h     {Is Ega present?}
        Jne @EgaDetected
        Int 11h
        And Al,0030h
        Shr Al,1
        Shr Al,1
        Shr Al,1
        Shr Al,1
        Mov Code,Al
        Jmp @Exit
        @EgaDetected:
        Mov Ah,0012h
        Mov Bl,10h
        Int 10h
        Mov Bh1,Bh
        @Exit:
        End;
          If (Code=255) Then Begin
            If (Bh1=0) Then Begin
            VideoCard:=EgaColor;
            End
              Else Begin
              VideoCard:=EgaMono;
              End;
          End
            Else Begin
              If (Code=3) Then Begin
              VideoCard:=Mono;
              End
                Else Begin
                VideoCard:=Cga;
                End;
            End;
      End;
End;
(*--------------------------------------------------*)
{Return true if it detects a vga or a ega adapter}
Function Screen.IsVgaorEga:Boolean;Assembler;
  Asm
  Mov Ah,12h
  Mov Bl,10h
  Int 10h
  XOr Al,Al
  Cmp Bh,1
  Ja @Nope
  Cmp Bl,3
  Ja @Nope
  Inc Al
  @Nope:
  End;
(*--------------------------------------------------*)
{Return true if a vga adapter is detected}
Function Screen.IsVGA:Boolean;Assembler;
  Asm
  Mov Ah,12h
  XOr Al,Al
  Mov Bl,36h
  Int 10h
  XOr Ah,Ah
  Cmp Al,12h
  Jnz @Nope
  Inc Ah
  @Nope:
  End;
(*--------------------------------------------------*)
{Is Mono display?}
Function Screen.IsMono:Boolean;Assembler;
  Asm
  Mov Ah,000Fh
  Int 10h
  Cmp Al,7
  Jne @Color
  Mov Al,1
  Jmp @Exit
  @Color:
  XOr Al,Al
  @Exit:
  End;
(*--------------------------------------------------*)
{Controls the size of DOS cursor.Before call this routine assign the correct}
{value to the CursorSize variable}
Procedure Screen.Cursor;
Begin
  Case CursorSize Of
    Small:Begin
      Asm
      Mov Ah,0001h
      Mov Ch,0020h
      Mov Cl,0020h
      Int 10h
      End;
    End;
      Normal:Begin
        If IsMono Then Begin
          Asm
          Mov Ah,0001h
          Mov Ch,0012d
          Mov Cl,0013d
          Int 10h
          End;
        End
          Else Begin
            Asm
            Mov Ah,0001h
            Mov Ch,0006h
            Mov Cl,0007h
            Int 10h
            End;
          End;
      End;
        Big:Begin
          If IsMono Then Begin
            Asm
            Mov Ah,0001h
            XOr Ch,Ch
            Mov Cl,0013d
            Int 10h
            End;
          End
            Else Begin
              Asm
              Mov Ah,0001h
              XOr Ch,Ch
              Mov Cl,0007h
              Int 10h
              End;
            End;
        End;
  End;
End;
(*--------------------------------------------------*)
{Return to DOS with default association of color/background}
Procedure Screen.DosReturn;
Begin
Window(1,1,80,25);
TextColor(LightGray);
TextBackGround(Black);
CursorSize:=Normal;
Cursor;
ClrScr;
End;
(*--------------------------------------------------*)
{Fills the entire area of screen with a character}
Procedure Screen.BackASCII(C:Char;FColor,BColor:Byte);Assembler;
  Asm
  Mov Ah,0009d
  Mov Al,C         {Char}
  XOr Bh,Bh        {Page 0}
  XOr Bl,Bl
  Mov Bl,BColor    {Attribute}
  Shl Bl,1
  Shl Bl,1
  Shl Bl,1
  Shl Bl,1
  Add Bl,FColor
  And Bl,007Fh     {Turn off the "Blink" bit}
  Mov Ch,0007d     {CX=Number of times to repeat}
  Mov Cl,0208d
  Int 10h
  End;
(*--------------------------------------------------*)
{Writes directly to the video memory}
Procedure Screen.FastWrite(X,Y:Byte;Var S:Str;FColor,BColor:Byte);
Var W:Word;
    I,ColorAtt:Byte;
Begin
ColorAtt:=(BColor Shl 4)+FColor;
W:=((Y-1)*80+(X-1))*2;
  If (Not IsMono) Then Begin
    For i:=1 To Length(S) Do Begin
    MemW[$B800:W]:=(ColorAtt Shl 8)+Ord(S[i]);
    Inc(W,2);
    End;
  End
     Else Begin
       For i:=1 To Length(S) Do Begin
       MemW[$B000:W]:=(ColorAtt Shl 8)+Ord(S[i]);
       Inc(W,2);
       End;
     End;
End;
(*--------------------------------------------------*)
{Save a screen into a pointer variable - SavedWindow}
Procedure Screen.SaveScreen;   {Works only with a color display}
Var VideoScreen:ScreenBuffer Absolute $B800:$0000;
Begin
  If Not Assigned(SavedWindow) Then Begin
  GetMem(SavedWindow,4000);
  Move(VideoScreen,SavedWindow^,4000); {Get a full screen!}
  CurrentX:=WhereX;
  CurrentY:=WhereY;
  CurWinX:=WindMin;
  CurWinY:=WindMax;
  CurrentColor:=(TextAttr And $0F);
  CurrentBack:=(TextAttr And $F0) Shr 4;
  End;
End;
(*--------------------------------------------------*)
{Restore the original screen previously stored in SavedWindow internal varia-}
{ble. Note:No changes in color/back are done - be carefull...}
Procedure Screen.RestoreScreen;
Var VideoScreen:ScreenBuffer Absolute $B800:$0000;
Begin
  If Assigned(SavedWindow) Then Begin
  Move(SavedWindow^,VideoScreen,4000);
  Window(Lo(CurWinX)+1,Hi(CurWinX)+1,Lo(CurWinY)+1,Hi(CurWinY)+1);
  GoToXY(CurrentX,CurrentY);
  TextColor(CurrentColor);
  TextBackGround(CurrentBack);
  FreeMem(SavedWindow,4000);
  SavedWindow:=Nil;
  CurrentX:=1;
  CurrentY:=1;
  End;
End;
(*--------------------------------------------------*)
{The same of Crt.GotoXY Procedure}
Procedure Screen.GoXY(X,Y:Byte);Assembler;
  Asm
  Mov Dh,Y    { DH = Row (Y) }
  Mov Dl,X    { DL = Column (X) }
  Dec Dh       { Adjust For Zero-based Bios routines }
  Dec Dl       { Turbo Crt.GotoXY is 1-based }
  XOr Bh,Bh     { Display page 0 }
  Mov Ah,2     { Call For SET CURSOR POSITION }
  Int 10h
  End;
(*--------------------------------------------------*)
{The same of Crt.WhereX Function}
Function Screen.LocX:Byte;Assembler;
  Asm
  Mov Ah,3      {Ask For current cursor position}
  XOr Bh,Bh      { On page 0 }
  Int 10h       { Return inFormation in DX }
  Inc Dl        { Bios Assumes Zero-based. Crt.WhereX Uses 1 based }
  Mov Al,Dl    { Return X position in AL For use in Byte Result }
  End;
(*--------------------------------------------------*)
{The same of Crt.WhereY Function}
Function Screen.LocY:Byte;Assembler;
  Asm
  Mov Ah,3      {Ask For current cursor position}
  XOr Bh,Bh      { On page 0 }
  Int 10h       { Return inFormation in DX }
  Inc Dh        { Bios Assumes Zero-based. Crt.WhereX Uses 1 based }
  Mov Al,Dh    { Return X position in AL For use in Byte Result }
  End;
(*--------------------------------------------------*)
{Faster ClrScr procedure}
Procedure Screen.FastClrScr;Assembler;
  Asm
  Mov Ah,000Fh
  Int 10h
  XOr Ah,Ah
  Int 10h
  End;
(*--------------------------------------------------*)
{Sets the blink on/off to access 16 background colors}
Procedure Screen.SetBlink(TurnOn:Boolean);Assembler;
  Asm
  Mov Ax,1003h
  Mov Bl,TurnOn
  Int 10h
  End;
(*--------------------------------------------------*)
{Draws a simple box on screen at positions indicated}
Procedure Screen.FastBox(X1,Y1,X2,Y2,FColor,BColor:Byte);
Var i:Byte;
Begin
Window(1,1,80,25);
TextColor(FColor);
TextBackGround(BColor);
  For i:=(X1+1) To (X2-1) Do Begin
  GoToXY(i,Y1);
  Write(#205);  {Í}
  GoToXY(i,Y2);
  Write(#205);
  End;
    For i:=(Y1+1) To (Y2-1) Do Begin
    GoToXY(X1,i);
    Write(#186);   {º}
    GoToXY(X2,i);
    Write(#186);
    End;
GoToXY(X1,Y1);
Write(#201);  {É}
GoToXy(X2,Y1);
Write(#187);  {»}
GoToXY(X1,Y2);
Write(#200);  {È}
GoToXY(X2,Y2);
Write(#188);  {¼}
End;
(*--------------------------------------------------*)
{Draws a simple box on screen at positions indicated}
Procedure Screen.SimpleBox(X1,Y1,X2,Y2,FColor,BColor:Byte);
Var i:Byte;
Begin
Window(1,1,80,25);
TextColor(FColor);
TextBackGround(BColor);
  For i:=(X1+1) To (X2-1) Do Begin
  GoToXY(i,Y1);
  Write(#196);
  GoToXY(i,Y2);
  Write(#196);  {Ä}
  End;
    For i:=(Y1+1) To (Y2-1) Do Begin
    GoToXY(X1,i);
    Write(#179);   {³}
    GoToXY(X2,i);
    Write(#179);
    End;
GoToXY(X1,Y1);
Write(#218);  {Ú}
GoToXy(X2,Y1);
Write(#191);  {¿}
GoToXY(X1,Y2);
Write(#192);  {À}
GoToXY(X2,Y2);
Write(#217);  {Ù}
End;
(*--------------------------------------------------*)
Procedure Screen.Center(Y,Z:Byte;S:Str);
Var X:Byte;
Begin
X:=(Y-Length(S)) Div 2;
GoToXY(X,Z);
Write(s);
End;
(*--------------------------------------------------*)
Procedure Screen.Back(Color:Byte);
Begin
TextBackGround(Color);
ClrScr;
End;
(*--------------------------------------------------*)
{Do a window including shade}
Procedure Screen.CompleteWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
Window(X1+2,Y1+1,X2+2,Y2+1);
TextBackGround(Black);
ClrScr;
Window(X1,Y1,X2,Y2);
TextBackGround(BColor);
TextColor(FColor);
ClrScr;
Window(1,1,80,25);
FastBox(X1,Y1,X2,Y2,FColor,BColor);
Window(X1+1,Y1+1,X2-1,Y2-1);
End;
(*--------------------------------------------------*)
Procedure Screen.CompleteSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
Window(X1+2,Y1+1,X2+2,Y2+1);
TextBackGround(Black);
ClrScr;
Window(X1,Y1,X2,Y2);
TextBackGround(BColor);
TextColor(FColor);
ClrScr;
Window(1,1,80,25);
SimpleBox(X1,Y1,X2,Y2,FColor,BColor);
Window(X1+1,Y1+1,X2-1,Y2-1);
End;
(*--------------------------------------------------*)
{Do a window without shading}
Procedure Screen.OpenWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
TextColor(FColor);
TextBackGround(BColor);
FastBox((X1-1),(Y1-1),(X2+1),(Y2+1),FColor,BColor);
Window(X1,Y1,X2,Y2);
ClrScr;
End;
(*--------------------------------------------------*)
Procedure Screen.TitleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
Begin
OpenWindow(X1,Y1,X2,Y2,FColor,BColor);
Window(X1-1,Y1-1,X2+1,Y2+1);
Center((X2-X1+4),1,(' '+Title+' '));
Window(X1,Y1,X2,Y2);
End;
(*--------------------------------------------------*)
Procedure Screen.OpenSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
TextColor(FColor);
TextBackGround(BColor);
SimpleBox((X1-1),(Y1-1),(X2+1),(Y2+1),FColor,BColor);
Window(X1,Y1,X2,Y2);
ClrScr;
End;
(*--------------------------------------------------*)
{Graphic status bar}
Procedure Screen.StatusBar(X,Y,Compr,CI,BI:Byte;Parc,Tot:Real);
Var S,i:Byte;             {X,Y = Position}
    P:Real;               {Compr = Length}
Begin                     {CI,BI = Initial color/background}
TextBackGround(Blue);     {Parc = Parcial value}
GoToXY(X,Y);              {Tot = total value}
  For i:=1 To Compr Do Begin
  Write(#176);
  End;
TextBackGround(BI);
P:=(100*Parc)/Tot;        {Ocuped percent}
S:=Round((Compr*P)/100);  {number of "squares" ocuped}
GoToXY(X,Y);
TextColor(Yellow);
  For i:=1 To S Do Begin
  Write(#219);
  End;
TextColor(White);
GoToXY((X+Compr+1),Y);
Write(P:0:1,'%');
TextColor(CI);
End;
(*--------------------------------------------------*)
{Used for Hard disks operations}
Procedure Screen.StatusDiskBar(X,Y,Compr,CI,BI:Byte;Parc,Tot:LongInt);
Var S,i:Byte;
    P:Real;
Begin
TextBackGround(Blue);
GoToXY(X,Y);
  For i:=1 To Compr Do Begin
  Write(#176);
  End;
TextBackGround(BI);
P:=(100*Parc)/Tot;
S:=Round((Compr*P)/100);
GoToXY(X,Y);
TextColor(Yellow);
  For i:=1 To S Do Begin
  Write(#219);
  End;
TextColor(White);
GoToXY((X+Compr+1),Y);
Write(P:0:1,'%');
TextColor(CI);
End;
(*--------------------------------------------------*)
Procedure Screen.Wait(Ms:Word);Assembler;
  Asm        {machine independent Delay Function}
  Mov Ax,1000;
  Mul Ms;
  Mov Cx,Dx;
  Mov Dx,Ax;
  Mov Ah,86h;
  Int 15h;
  End;
(*--------------------------------------------------*)
Function ReadChar:Byte;Assembler;
  Asm
  Mov Ah,0008h
  XOr Bh,Bh
  Int 10h
  End;
(*--------------------------------------------------*)
Procedure Screen.ShadedWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Var i:Byte;
    Temp:Byte;
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
TextColor(LightGray);
TextBackGround(Black);
  For i:=(X1+2) To (X2+2) Do Begin
  GoXY(i,(Y2+1));
  Write(Chr(ReadChar));
  End;
    For i:=(Y1+1) To (Y2+1) Do Begin
    GoXY(X2+1,i);
    Write(Chr(ReadChar));
    GoXY(X2+2,i);
    Write(Chr(ReadChar));
    End;
Window(X1,Y1,X2,Y2);
TextBackGround(BColor);
TextColor(FColor);
ClrScr;
Window(1,1,80,25);
FastBox(X1,Y1,X2,Y2,FColor,BColor);
Window(X1+1,Y1+1,X2-1,Y2-1);
End;
(*--------------------------------------------------*)
Procedure Screen.ShadedSimpleWindow(X1,Y1,X2,Y2,FColor,BColor:Byte);
Var i:Byte;
    Temp:Byte;
Begin
Window(1,1,80,25);
CursorSize:=Small;
Cursor;
TextColor(LightGray);
TextBackGround(Black);
  For i:=(X1+2) To (X2+2) Do Begin
  GoXY(i,(Y2+1));
  Write(Chr(ReadChar));
  End;
    For i:=(Y1+1) To (Y2+1) Do Begin
    GoXY(X2+1,i);
    Write(Chr(ReadChar));
    GoXY(X2+2,i);
    Write(Chr(ReadChar));
    End;
Window(X1,Y1,X2,Y2);
TextBackGround(BColor);
TextColor(FColor);
ClrScr;
Window(1,1,80,25);
SimpleBox(X1,Y1,X2,Y2,FColor,BColor);
Window(X1+1,Y1+1,X2-1,Y2-1);
End;
(*--------------------------------------------------*)
Procedure Screen.TitleShadedWindow(X1,Y1,X2,Y2,FColor,BColor:Byte;Title:String);
Begin
ShadedWindow(X1,Y1,X2,Y2,FColor,BColor);
Window(X1-1,Y1-1,X2+1,Y2+1);
Center((X2-X1+4),2,(' '+Title+' '));
Window(X1+1,Y1+1,X2-1,Y2-1);
End;
(*--------------------------------------------------*)
{Scrolls the screen up - Assign with the DownArrow key}
Procedure Screen.ScrollUp(LSE,LSD,CSE,CSD,BackG:Byte);Assembler;
  Asm
  Sub LSE,1
  Sub LSD,1
  Sub CSE,1
  Sub CSD,1
  Mov Al,1
  Mov Ah,0006h
  Mov Ch,LSE
  Mov Cl,CSE
  Mov Dh,LSD
  Mov Dl,CSD
  XOr Bh,Bh
  Mov Bh,BackG
  Shl Bh,1
  Shl Bh,1
  Shl Bh,1
  Shl Bh,1
  Int 10h
  End;
(*--------------------------------------------------*)
{Scrolls the screen Down - Assign with the UpArrow key}
Procedure Screen.ScrollDown(LSE,LSD,CSE,CSD,BackG:Byte);Assembler;
  Asm
  Sub LSE,1
  Sub LSD,1
  Sub CSE,1
  Sub CSD,1
  Mov Al,1
  Mov Ah,0007h
  Mov Ch,LSE
  Mov Cl,CSE
  Mov Dh,LSD
  Mov Dl,CSD
  XOr Bh,Bh
  Mov Bh,BackG
  Shl Bh,1
  Shl Bh,1
  Shl Bh,1
  Shl Bh,1
  Int 10h
  End;
(*--------------------------------------------------*)
{Very Cool scroller}
Procedure Screen.ScrollTextLine(X1,X2:Integer;Y:Integer;St:String);
Begin
  While Length(St)<(X2-X1+1) Do Begin
  St:=St+' ' ;
    While Not KeyPressed Do Begin
    GotoXY(X1,Y) ;
    Write(Copy(St,1,X2-X1+1)) ;
    Delay(90) ;
    St:=Copy(St,2,Length(St)-1)+St[1] ;
    End ;
  End;
End ;
(*--------------------------------------------------*)
{Sound Procedure}
Procedure Screen.Beep(Freq,Time:Word);
Begin
Sound(Freq);
Delay(Time);
NoSound;
End;
(*--------------------------------------------------*)
{HighLight a string character previously marked with a '~'}
Procedure Screen.HighLightText(Text:String;X,Y,FColor,BColor,HColor:Byte);
Var HPos,i:Byte;
Begin
HPos:=Pos('~',Text);
  If (HPos=0) Then Begin
  Exit;
  End
    Else Begin
    Delete(Text,HPos,1);
    End;
TextBackGround(BColor);
GoToXY(X,Y);
TextColor(FColor);
  For i:=1 To (HPos-1) Do Begin
  Write(Text[i]);
  End;
TextColor(HColor);
Write(Text[HPos]);
TextColor(FColor);
  For i:=(HPos+1) To Length(Text) Do Begin
  Write(Text[i]);
  End;
End;
(*--------------------------------------------------*)
Begin
Copyright;
End.