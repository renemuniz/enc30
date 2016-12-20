{$G-}

{Information:
* Code Size = 2001 Bytes
* Stack Size = 0 Bytes
* Data Size = 0 Bytes
* Number of lines = 438}

Unit MouseControl; { OOP Mouse Implementation }
Interface
Type Mode=(CrtMode,GraphMode);
     FaceMasks=Array[0..1,0..15] Of Word;

     MouseInfo=Record
     DriverLo,DriverHi,IRQ:Byte;
     MouseType:String[12];
     End;

     Mouse=Object
     X,Y,Bt:Word; {Hold the current status}
     MouseFound:Boolean; {Is mouse present?}
     MouseInfo:MouseInfo; {Some mouse information}
     Buttons:Byte; {Number of buttons}
     Mode:Mode;    {Working mode - Text or Graph}
     FaceMasks:FaceMasks; {Used internaly}
     Procedure Init;
     Procedure InitMouse;
     Procedure CloseMouse;
     Procedure GetMouseState;
     Procedure GetMouseInfo;
     Procedure SetSpeed(Xs,Ys,Thr:Word);
     Procedure MoveCursor(X1,Y1:Word);
     Procedure MouseWindow(X1,Y1,X2,Y2:Byte);
     Procedure RestoreFullWindow;
     Procedure SetTextCursor(Back,Color:Byte);
     Procedure BlinkCursor(Up,Down:Word);
     Function MousePressed:Boolean;
     Procedure HandMouse;
     Procedure ArrowMouse;
     Procedure CandyMouse;
     Procedure SmileMouse;
     End;

Implementation
Uses Dos;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'MouseControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Procedure Mouse.Init;  { Initialize Default Options }
Begin
X:=0;
Y:=0;
Bt:=0;
Buttons:=0;
Mode:=CrtMode;
  With MouseInfo Do Begin
  DriverLo:=0;
  DriverHi:=0;
  IRQ:=0;
  MouseType:='None';
  End;
End;
(*--------------------------------------------------*)
{Initialize the mouse driver}
Procedure Mouse.InitMouse;
Var Ax1,Bx1:Word;
Begin
  Asm
  XOr Ax,Ax
  Int 33h
  Mov Ax1,Ax
  Mov Bx1,Bx
  End;
    If (Ax1=$0000) Then Begin
    MouseFound:=False;
    Exit;
    End
      Else If (Ax1=$FFFF) Then Begin
      MouseFound:=True;
        Asm
        Mov Ax,1 { Show mouse pointer if mousefound is true }
        Int 33h
        End;
          Case Bx1 Of
          2:Buttons:=2;
          0:Buttons:=255;  { Unknown number of buttons (other than 2) }
          3:Buttons:=3;
          $FFFF:Buttons:=2;
          End;
      End;
End;
(*--------------------------------------------------*)
{Hide mouse pointer}
Procedure Mouse.CloseMouse;Assembler;
Asm
Mov Ax,2
Int 33h
End;
(*--------------------------------------------------*)
{Get the mouse state of buttons and position of cursor}
{Note:Remember to specify the working mode. i.e CrtMode or GraphMode}
Procedure Mouse.GetMouseState;
Var Bt1,X1,Y1:Word;
Begin
  Asm
  Mov Ax,3
  Int 33h
  Mov Bt1,Bx
  Mov X1,Cx
  Mov Y1,Dx
  End;
    If (Mode=CrtMode) Then Begin
    Bt:=Bt1;
    X:=(X1+8) Div 8;
    Y:=(Y1+8) Div 8;
    End
      Else Begin
      Bt:=Bt1;
      X:=X1;
      Y:=Y1;
      End;
End;
(*--------------------------------------------------*)
{Gets mouse information and return in variables associated}
Procedure Mouse.GetMouseInfo;
Var Bl1,Bh1,Cl1,Ch1:Byte;
Begin
  Asm
  Mov Ax,24h
  Int 33h
  Cmp Ax,$FFFF
  Jne @Success
  Mov Bl1,255
  Mov Bh1,255
  Mov Cl1,255
  Mov Ch1,255 { Error Condition:Registers=255 }
  Jmp @Error
  @Success:
  Mov Bl1,Bl
  Mov Bh1,Bh
  Mov Cl1,Cl
  Mov Ch1,Ch
  @Error:
  End;
    If (Bh1<>255) And (Bl1<>255) Then Begin
    MouseInfo.DriverLo:=Bh1;
    MouseInfo.DriverHi:=Bl1;
    End
      Else Begin
      MouseInfo.DriverLo:=0;   { If zero then error! }
      MouseInfo.DriverHi:=0;
      End;
        Case Ch1 Of
        255:MouseInfo.MouseType:='Unknown';
        1: MouseInfo.MouseType:='Bus Mouse';
        2: MouseInfo.MouseType:='Serial Mouse';
        3: MouseInfo.MouseType:='InPort Mouse';
        4: MouseInfo.MouseType:='PS/2 Mouse';
        5: MouseInfo.MouseType:='HP Mouse';
        End;
          If (Cl1<>255) Then Begin
            If (Cl1=0) Then Begin
            MouseInfo.IRQ:=0; {If zero then=PS/2}
            End
              Else Begin
              MouseInfo.IRQ:=Cl1;
              End;
          End;
End;
(*--------------------------------------------------*)
{Sets mouse speed}
Procedure Mouse.SetSpeed(Xs,Ys,Thr:Word);Assembler;
Asm
Mov Ax,001Ah
Mov Bx,Xs
Shl Bx,1
Shl Bx,1
Shl Bx,1
Mov Cx,Ys
Shl Cx,1
Shl Cx,1
Shl Cx,1
Mov Dx,Thr
Int 33h
end;
(*--------------------------------------------------*)
{Move mouse cursor to a coordinate specified}
Procedure Mouse.MoveCursor(X1,Y1:Word);
Begin
  If (Mode=GraphMode) Then Begin
    Asm
    Mov Ax,4
    Mov Cx,X1
    Mov Dx,Y1
    Int 33h
    End;
  End
    Else Begin
      Asm
      Mov Ax,X1
      XOr Dx,Dx
      Mov Bx,8
      Mul Bx
      Sub Ax,8
      Mov Cx,Ax
      Mov Ax,Y1
      XOr Dx,Dx
      Mov Bx,8
      Mul Bx
      Sub Ax,8
      Mov Dx,Ax
      Mov Ax,4
      Int 33h
      End;
    End;
End;
(*--------------------------------------------------*)
Procedure Mouse.MouseWindow(X1,Y1,X2,Y2:Byte);Assembler;
Asm
Mov Ax,7
XOr Ch,Ch
XOr Dh,Dh
Mov Cl,X1
Shl Cx,1
Shl Cx,1
Shl Cx,1
Mov Dl,X2
Shl Dx,1
Shl Dx,1
Shl Dx,1
Int 33h
Mov Ax,8
XOr Ch,Ch
XOr Dh,Dh
Mov Cl,Y1
Shl Cx,1
Shl Cx,1
Shl Cx,1
Mov Dl,Y2
Shl Dx,1
Shl Dx,1
Shl Dx,1
Int 33h
End;
(*--------------------------------------------------*)
Procedure Mouse.RestoreFullWindow;
Begin
MouseWindow(0,0,79,24);
End;
(*--------------------------------------------------*)
{Sets text cursor for textmode only}
Procedure Mouse.SetTextCursor(Back,Color:Byte);
Var Temp:Word;
Begin
  If ((Back<16) And (Color<16)) Then Begin
  Temp:=(Color*256)+(Back*4096);
    Asm
    Mov Bx,0
    Mov Cx,00FFh
    Mov Dx,Temp
    Mov Ax,000Ah
    Int 33h
    End;
  End;
End;
(*--------------------------------------------------*)
{Show a blinking cursor - textmode only}
Procedure Mouse.BlinkCursor(Up,Down:Word);Assembler;
Asm
Mov Bx,1
Mov Cx,Up
Mov Dx,Down
Mov Ax,000Ah
Int 33h
End;
(*--------------------------------------------------*)
{Return true if a button is pressed}
Function Mouse.MousePressed:Boolean;
Begin
MousePressed:=False;
GetMouseState;
  If (Bt<>0) Then Begin
  MousePressed:=True;
  End;
End;
(*--------------------------------------------------*)
{Modify the mouse pointer to a "hand mouse"}
Procedure Mouse.HandMouse;
Var Regs:Registers;
Begin
FaceMasks[0,0] := $F3FF;    {1111001111111111}
FaceMasks[0,1] := $E1FF;    {1110000111111111}
FaceMasks[0,2] := $E1FF;    {1110000111111111}
FaceMasks[0,3] := $E1FF;    {1110000111111111}
FaceMasks[0,4] := $E1FF;    {1110000111111111}
FaceMasks[0,5] := $E07F;    {1110000001111111}
FaceMasks[0,6] := $C00F;    {1100000000001111}
FaceMasks[0,7] := $8001;    {1000000000000001}
FaceMasks[0,8] := $0000;    {0000000000000000}
FaceMasks[0,9] := $0000;    {0000000000000000}
FaceMasks[0,10] := $0000;   {0000000000000000}
FaceMasks[0,11] := $0000;   {0000000000000000}
FaceMasks[0,12] := $0000;   {0000000000000000}
FaceMasks[0,13] := $8000;   {1000000000000000}
FaceMasks[0,14] := $C001;   {1100000000000001}
FaceMasks[0,15] := $E001;   {1110000000000001}

{ Cursor Mask }

FaceMasks[1,0] := $0000;    {0000000000000000}
FaceMasks[1,1] := $0C00;    {0000110000000000}
FaceMasks[1,2] := $0C00;    {0000110000000000}
FaceMasks[1,3] := $0C00;    {0000110000000000}
FaceMasks[1,4] := $0C00;    {0000110000000000}
FaceMasks[1,5] := $0C00;    {0000110000000000}
FaceMasks[1,6] := $0D80;    {0000110110000000}
FaceMasks[1,7] := $2DB0;    {0010110110110000}
FaceMasks[1,8] := $6DB6;    {0110110110110110}
FaceMasks[1,9] := $6DB6;    {0110110110110110}
FaceMasks[1,10] := $6DB6;   {0110110110110110}
FaceMasks[1,11] := $7FFE;   {0111111111111110}
FaceMasks[1,12] := $7FFE;   {0111111111111110}
FaceMasks[1,13] := $3FFE;   {0011111111111110}
FaceMasks[1,14] := $1FFC;   {0001111111111100}
FaceMasks[1,15] := $0000;   {0000000000000000}
Regs.Ax := 9;
Regs.Bx := 1;
Regs.Cx := 0;
Regs.Dx := Ofs(FaceMasks);
Regs.Es := Seg(FaceMasks);
Intr(51,Regs);
End;
(*--------------------------------------------------*)
{Restore the default mouse pointer}
Procedure Mouse.ArrowMouse;
Var Regs:Registers;
Begin
FaceMasks[0,0] := $9FFF;    {1001111111111111}
FaceMasks[0,1] := $8FFF;    {1000111111111111}
FaceMasks[0,2] := $87FF;    {1000011111111111}
FaceMasks[0,3] := $83FF;    {1000001111111111}
FaceMasks[0,4] := $81FF;    {1000000111111111}
FaceMasks[0,5] := $80FF;    {1000000011111111}
FaceMasks[0,6] := $807F;    {1000000001111111}
FaceMasks[0,7] := $803F;    {1000000000111111}
FaceMasks[0,8] := $801F;    {1000000000011111}
FaceMasks[0,9] := $800F;    {1000000000001111}
FaceMasks[0,10] := $80FF;   {1000000011111111}
FaceMasks[0,11] := $887F;   {1000100001111111}
FaceMasks[0,12] := $987F;   {1001100001111111}
FaceMasks[0,13] := $FC3F;   {1111110000111111}
FaceMasks[0,14] := $FC3F;   {1111110000111111}
FaceMasks[0,15] := $FE3F;   {1111111000111111}

{ Cursor Mask }

FaceMasks[1,0] := $0000;    {0000000000000000}
FaceMasks[1,1] := $2000;    {0010000000000000}
FaceMasks[1,2] := $3000;    {0011000000000000}
FaceMasks[1,3] := $3800;    {0011100000000000}
FaceMasks[1,4] := $3C00;    {0011110000000000}
FaceMasks[1,5] := $3E00;    {0011111000000000}
FaceMasks[1,6] := $3F00;    {0011111100000000}
FaceMasks[1,7] := $3F80;    {0011111110000000}
FaceMasks[1,8] := $3FC0;    {0011111111000000}
FaceMasks[1,9] := $3E00;    {0011111000000000}
FaceMasks[1,10] := $3600;   {0011011000000000}
FaceMasks[1,11] := $2300;   {0010001100000000}
FaceMasks[1,12] := $0300;   {0000001100000000}
FaceMasks[1,13] := $0180;   {0000000110000000}
FaceMasks[1,14] := $0180;   {0000000110000000}
FaceMasks[1,15] := $0000;   {0000000000000000}
Regs.Ax := 9;
Regs.Bx := 1;
Regs.Cx := 0;
Regs.Dx := Ofs(FaceMasks);
Regs.Es := Seg(FaceMasks);
Intr(51,Regs);
End;
(*--------------------------------------------------*)
Procedure Mouse.CandyMouse;
Var Regs:Registers;
Begin
{ Screen Mask }
FaceMasks[0,0] := $E007;    {1110000000000111}
FaceMasks[0,1] := $8001;    {1000000000000001}
FaceMasks[0,2] := $0000;    {0000000000000000}
FaceMasks[0,3] := $0000;    {0000000000000000}
FaceMasks[0,4] := $0000;    {0000000000000000}
FaceMasks[0,5] := $0000;    {0000000000000000}
FaceMasks[0,6] := $8001;    {1000000000000001}
FaceMasks[0,7] := $E007;    {1110000000000111}
FaceMasks[0,8] := $FC3F;    {1111110000111111}
FaceMasks[0,9] := $FC3F;    {1111110000111111}
FaceMasks[0,10] := $FC3F;   {1111110000111111}
FaceMasks[0,11] := $FC3F;   {1111110000111111}
FaceMasks[0,12] := $FC3F;   {1111110000111111}
FaceMasks[0,13] := $FC3F;   {1111110000111111}
FaceMasks[0,14] := $FC3F;   {1111110000111111}
FaceMasks[0,15] := $FE7F;   {1111111001111111}

{ Cursor Mask }

FaceMasks[1,0] := $0000;    {0000000000000000}
FaceMasks[1,1] := $1FF8;    {0001111111111000}
FaceMasks[1,2] := $7F0E;    {0111111100001110}
FaceMasks[1,3] := $7FE6;    {0111111111100110}
FaceMasks[1,4] := $7FF6;    {0111111111110110}
FaceMasks[1,5] := $7FFE;    {0111111111111110}
FaceMasks[1,6] := $1FF8;    {0001111111111000}
FaceMasks[1,7] := $0000;    {0000000000000000}
FaceMasks[1,8] := $0000;    {0000000000000000}
FaceMasks[1,9] := $0180;    {0000000110000000}
FaceMasks[1,10] := $0180;   {0000000110000000}
FaceMasks[1,11] := $0180;   {0000000110000000}
FaceMasks[1,12] := $0180;   {0000000110000000}
FaceMasks[1,13] := $0180;   {0000000110000000}
FaceMasks[1,14] := $0180;   {0000000110000000}
FaceMasks[1,15] := $0000;   {0000000000000000}
Regs.Ax := 9;
Regs.Bx := 1;
Regs.Cx := 0;
Regs.Dx := Ofs(FaceMasks);
Regs.Es := Seg(FaceMasks);
Intr(51,Regs);
End;
(*--------------------------------------------------*)
Procedure Mouse.SmileMouse;
Var Regs:Registers;
Begin
Facemasks[0,0] := $C003;    {1100000000000011}
FaceMasks[0,1] := $8001;    {1000000000000001}
FaceMasks[0,2] := $0000;    {0000000000000000}
FaceMasks[0,3] := $0000;    {0000000000000000}
FaceMasks[0,4] := $0000;    {0000000000000000}
FaceMasks[0,5] := $03C0;    {0000001111000000}
FaceMasks[0,6] := $0180;    {0000000110000000}
FaceMasks[0,7] := $07E0;    {0000011111100000}
FaceMasks[0,8] := $0660;    {0000011001100000}
FaceMasks[0,9] := $03C0;    {0000001111000000}
FaceMasks[0,10] := $0000;   {0000000000000000}
FaceMasks[0,11] := $0000;   {0000000000000000}
FaceMasks[0,12] := $0000;   {0000000000000000}
FaceMasks[0,13] := $0000;   {0000000000000000}
FaceMasks[0,14] := $8001;   {1000000000000001}
FaceMasks[0,15] := $C003;   {1100000000000011}

{ Cursor Mask }

FaceMasks[1,0] := $0000;    {0000000000000000}
FaceMasks[1,1] := $1FF8;    {0001111111111000}
FaceMasks[1,2] := $3FFC;    {0011111111111100}
FaceMasks[1,3] := $700E;    {0111000000001110}
FaceMasks[1,4] := $67E6;    {0110011111100110}
FaceMasks[1,5] := $6FF6;    {0110111111110110}
FaceMasks[1,6] := $6996;    {0110100110010110}
FaceMasks[1,7] := $6FF6;    {0110111111110110}
FaceMasks[1,8] := $6FF6;    {0110111111110110}
FaceMasks[1,9] := $6BD6;    {0110101111010110}
FaceMasks[1,10] := $6C36;   {0110110000110110}
FaceMasks[1,11] := $67E6;   {0110011111100110}
FaceMasks[1,12] := $700E;   {0111000000001110}
FaceMasks[1,13] := $3FFC;   {0011111111111100}
FaceMasks[1,14] := $1FF8;   {0001111111111000}
FaceMasks[1,15] := $0000;   {0000000000000000}
Regs.Ax := 9;
Regs.Bx := 1;
Regs.Cx := 0;
Regs.Dx := Ofs(FaceMasks);
Regs.Es := Seg(FaceMasks);
Intr(51,Regs);
End;
(*--------------------------------------------------*)
Begin
CopyRight;
End.