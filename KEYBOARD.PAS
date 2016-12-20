Unit KeyboardControl;  {OOP Keyboard Implementation}

{Information:
* Code Size = 2262 Bytes
* Stack Size = 0 Bytes
* Data Size = 0 Bytes
* Number of lines = 274}

Interface
Uses Crt;
Type Keys=(NullKey,F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,
           Enter,Tab,ShiftTab,Bksp,UpArrow,
           DownArrow,RightArrow,LeftArrow,DeleteKey,
           InsertKey,HomeKey,Esc,EndKey,TextKey,
           NumberKey,Space,PgUp,PgDn,ShiftF1,ShiftF2,
           ShiftF3,ShiftF4,ShiftF5,ShiftF6,ShiftF7,ShiftF8,
           CtrF1,CtrF2,CtrF3,CtrF4,CtrF5,CtrF6,CtrF7,CtrF8,
           AltF1,AltF2,AltF3,AltF4,AltF5,AltF6,AltF7,AltF8,
           Ctr_A,Ctr_B,Ctr_C,Ctr_D,Ctr_E,Ctr_F,Ctr_G,Ctr_H,
           Ctr_I,Ctr_J,Ctr_K,Ctr_L,Ctr_M,Ctr_N,Ctr_O,Ctr_P,
           Ctr_Q,Ctr_R,Ctr_S,Ctr_T,Ctr_U,Ctr_V,Ctr_X,Ctr_Z,
           Alt_A,Alt_B,Alt_C,Alt_D,Alt_E,Alt_F,Alt_G,Alt_H,
           Alt_I,Alt_J,Alt_K,Alt_L,Alt_M,Alt_N,Alt_O,Alt_P,
           Alt_Q,Alt_R,Alt_S,Alt_T,Alt_U,Alt_V,Alt_X,Alt_Z);

     Keyboard=Object
     Scroll_Lock,Caps_Lock,Num_Lock,Ins,Alt,Ctrl,Left_Shift,
     Right_Shift,FunctionKey:Boolean; {Hold special keys status}
     Ch:Char; {Hold the ASCII value for keypressed}
     Key:Keys; {Important combination of keystroke}
     Procedure Init;
     Procedure ClearKbdBuf;
     Procedure Inkey;
     Procedure DisableKeyb;
     Procedure EnableKeyb;
     Procedure GetSpecialKeysStatus;
     Procedure SetCaps(Enable:Boolean);
     Procedure SetNum(Enable:Boolean);
     Procedure SetScroll(Enable:Boolean);
     Function KeyPress:Boolean;
     Function ReadChar:Char;
     End;

Implementation

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'KeyboardControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Procedure Keyboard.InKey;
{Return the most important keys pressed}
Begin
FunctionKey:=False;
Ch:=ReadKey;
  If (Ch=#0) Then Begin
  FunctionKey:=True;
  Ch:=ReadKey;
  End;
    If FunctionKey Then Begin
      Case Ord(Ch) Of
      15:Key:=ShiftTab;
      72:Key:=UpArrow;
      80:Key:=DownArrow;
      82:Key:=InsertKey;
      75:Key:=LeftArrow;
      77:Key:=RightArrow;
      73:Key:=PgUp;
      81:Key:=PgDn;
      71:Key:=HomeKey;
      79:Key:=EndKey;
      83:Key:=DeleteKey;
      82:Key:=InsertKey;
      59:Key:=F1;
      60:Key:=F2;
      61:Key:=F3;
      62:Key:=F4;
      63:Key:=F5;
      64:Key:=F6;
      65:Key:=F7;
      66:Key:=F8;
      67:Key:=F9;
      68:Key:=F10;
      84:Key:=ShiftF1;
      85:Key:=ShiftF2;
      86:Key:=ShiftF3;
      87:Key:=ShiftF4;
      88:Key:=ShiftF5;
      89:Key:=ShiftF6;
      90:Key:=ShiftF7;
      91:Key:=ShiftF8;
      94:Key:=CtrF1;
      95:Key:=CtrF2;
      96:Key:=CtrF3;
      97:Key:=CtrF4;
      98:Key:=CtrF5;
      99:Key:=CtrF6;
      100:Key:=CtrF7;
      101:Key:=CtrF8;
      104:Key:=AltF1;
      105:Key:=AltF2;
      106:Key:=AltF3;
      107:Key:=AltF4;
      108:Key:=AltF5;
      109:Key:=AltF6;
      110:Key:=AltF7;
      111:Key:=AltF8;
      30:Key:=Alt_A;
      48:Key:=Alt_B;
      46:Key:=Alt_C;
      32:Key:=Alt_D;
      18:Key:=Alt_E;
      33:Key:=Alt_F;
      34:Key:=Alt_G;
      35:Key:=Alt_H;
      23:Key:=Alt_I;
      36:Key:=Alt_J;
      37:Key:=Alt_K;
      38:Key:=Alt_L;
      50:Key:=Alt_M;
      49:Key:=Alt_N;
      24:Key:=Alt_O;
      25:Key:=Alt_P;
      16:Key:=Alt_Q;
      19:Key:=Alt_R;
      31:Key:=Alt_S;
      20:Key:=Alt_T;
      22:Key:=Alt_U;
      47:Key:=Alt_V;
      45:Key:=Alt_X;
      44:Key:=Alt_Z;
      End;
    End;
        If (Not FunctionKey) Then Begin
          Case (Ord(Ch)) Of
          0:Key:=NullKey;
          8:Key:=Bksp;
          9:Key:=Tab;
          13:Key:=Enter;
          27:Key:=Esc;
          32:Key:=Space;
          33..44,47,58..254:Key:=TextKey;
          45,46,48..57:Key:=NumberKey;
          1:Key:=Ctr_A;
          2:Key:=Ctr_B;
          3:Key:=Ctr_C;
          4:Key:=Ctr_D;
          5:Key:=Ctr_E;
          6:Key:=Ctr_F;
          7:Key:=Ctr_G;
          8:Key:=Ctr_H;
          9:Key:=Ctr_I;
          10:Key:=Ctr_J;
          11:Key:=Ctr_K;
          12:Key:=Ctr_L;
          13:Key:=Ctr_M;
          14:Key:=Ctr_N;
          15:Key:=Ctr_O;
          16:Key:=Ctr_P;
          17:Key:=Ctr_Q;
          18:Key:=Ctr_R;
          19:Key:=Ctr_S;
          20:Key:=Ctr_T;
          21:Key:=Ctr_U;
          22:Key:=Ctr_V;
          24:Key:=Ctr_X;
          26:Key:=Ctr_Z;
          End;
        End;
End;
(*--------------------------------------------------*)
{Initialize the variables}
Procedure Keyboard.Init;
Begin
FunctionKey:=False;
Ch:=#0; {NullKey}
Key:=NullKey;
Scroll_Lock:=False;
Num_Lock:=False;
Caps_Lock:=False;
Alt:=False;
Ins:=False;
Left_Shift:=False;
Right_Shift:=False;
Ctrl:=False;
End;
(*--------------------------------------------------*)
{Clear the keyboard ciclic buffer}
Procedure Keyboard.ClearKbdBuf;
Begin
  Asm
  CLI;
  End;
MemW[$0000:$041C]:=MemW[$0000:$0041A];
  Asm
  STI;
  End;
End;
(*--------------------------------------------------*)
{Totaly disable the keyboard}
Procedure Keyboard.DisableKeyb;
Begin
Port[$21]:=$02;
End;
(*--------------------------------------------------*)
{Enable the keyboard}
Procedure Keyboard.EnableKeyb;
Begin
Port[$21]:=$00;
End;
(*--------------------------------------------------*)
{Get the status of some special keys and return in the pertinent variables}
Procedure Keyboard.GetSpecialKeysStatus;
Var Bios_Keys:Byte Absolute $40:$17;
Begin
Ins           := ((Bios_Keys And $80) = $80);
Caps_Lock     := ((Bios_Keys And $40) = $40);
Num_Lock      := ((Bios_Keys And $20) = $20);
Scroll_Lock   := ((Bios_Keys And $10) = $10);
Alt           := ((Bios_Keys And $8)  = $8);
Ctrl          := ((Bios_Keys And $4)  = $4);
Left_Shift    := ((Bios_Keys And $2)  = $2);
Right_Shift   := ((Bios_Keys And $1)  = $1);
End;
(*--------------------------------------------------*)
{Analog to Crt.Keypressed}
Function Keyboard.KeyPress: Boolean; Assembler;
  Asm
  Push Ds    {This function does not respond to Ctrl+Break}
  Push Sp    {It's analog to Crt.KeyPressed}
  Mov Ah,1
  Int 16h
  Cmp Al,0
  Jz @1
  Mov Al,1
@1:
  Pop Sp
  Pop Ds
End;
(*--------------------------------------------------*)
Function Keyboard.ReadChar:Char;
Var Al1:Byte;
Begin             {This function does not respond to Ctrl+Break}
  Asm             {It's analog to Crt.ReadKey}
  Mov Ah,7
  Int 21h
  Mov Al1,Al
  End;
ReadChar:=Char(Al1);
End;
(*--------------------------------------------------*)
{Enable or disable the CapsLock key}
Procedure Keyboard.SetCaps(Enable:Boolean);
Begin
 If Enable Then
   Mem[$40:$17] := Mem[$40:$17] Or $40
 Else
   Mem[$40:$17] := Mem[$40:$17] And $BF;
End;
(*--------------------------------------------------*)
{Enable or disable the NumLock key}
Procedure Keyboard.SetNum(Enable:Boolean);
Begin
 If Enable Then
   Mem[$40:$17] := Mem[$40:$17] Or $20
 Else
   Mem[$40:$17] := Mem[$40:$17] And $DF;
End;
(*--------------------------------------------------*)
{Enable or disable the ScrollLock key}
Procedure Keyboard.SetScroll(Enable:Boolean);
Begin
 If Enable Then
   Mem[$40:$17] := Mem[$40:$17] Or $10
 Else
   Mem[$40:$17] := Mem[$40:$17] And $EF;
End;
(*--------------------------------------------------*)
Begin
CopyRight;
End.