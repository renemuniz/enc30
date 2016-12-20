Unit StopHack;   {Anti-Debug Unit}

Interface
Procedure HaltDebug;

Implementation
Var
{Direct interrupt access}
Int01: Pointer Absolute $0000:$0004; {Trace Int}
Int03: Pointer Absolute $0000:$000C; {BreakPoint Int}
IntXX: Pointer Absolute $0000:$0080; {New interrupt, Int20=$80}
{Saved interrupts}
SaveInt01,SaveInt03:Pointer;
{Old ExitProc}
SavedExit:Pointer;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'StopHack Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Procedure HaltDebug;Assembler;
Asm
  {Wait until clock timer changes}
  Push Ds
  XOr Ax,Ax
  Mov Ds,Ax
  Mov Ah,[046Ch]
@@TimerWait:
  Mov Al,[046Ch]
  Cmp Al,Ah
  Je @@TimerWait
  Pop Ds
End;

Procedure Cli; InLine($FA); {Clear interrupt flag}
Procedure Sti; InLine($FB); {Set interrupt flag}

Procedure ExitHandler;Far;
Begin
ExitProc:=SavedExit;
Cli;
Int01:=SaveInt01;
Int03:=SaveInt03;
Sti;
End;

{Initialization}
Begin
CopyRight;
{Try to mess up debuggers}
HaltDebug;
{Save interrupts}
SaveInt01:=Int01;
SaveInt03:=Int03;
SavedExit:=ExitProc;
Cli;
Int03:=IntXX;
Int01:=IntXX;
Sti;
ExitProc:=@ExitHandler;
End.
