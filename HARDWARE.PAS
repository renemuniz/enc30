Unit HardwareTools;      {General Hardware Detect Tools}

{Information
* Code Size = 4978
* Data Size = 130
* Heap Size = 0
* Number of Lines = 951}

Interface
Type Str25=String[25];
     Str12=String[12];
     Str7=String[7];
     Str8=String[8];
     Str42=String[42];
     Str3=String[3];
     Str4=String[4];
     Str10=String[10];
     Buf=Array[1..1024] Of Byte;
     Buffer=^Buf;
     WinModeType=(NoWin,RealStd,Enhanced);
       HDRec=Record
       Size:LongInt;
       Free:LongInt;
       Bytes_Per_Sector:Word;
       Sectors_Per_Cluster:Word;
       Total_Number_Clusters:Word;
       Empty_Clusters:Word;
       End;
         EquipRec=Record
         SerialPorts:Byte;
         ParPorts:Byte;
         FloppyNumber:Byte;
         End;
           CMOSRec = Record
           Found     : Boolean;  { was a CMOS found to exist }
           VideoType : Str10;    { Type of video found in CMOS }
           Coproc    : Boolean;  { does CMOS report a math coprocessor }
           FloppyA   : Str12;    { type of floppy drive for A }
           FloppyB   : Str12;    { Type of floppy drive for B }
           Hard0     : Byte;     { Type of hard drive for drive 0 }
           Hard1     : Byte;     { Type of hard drive for Drive 1 }
           ConvenRam : Word;     { amount of conventional ram indicated }
           ExtendRam : Word;     { amount of extended Ram indicated }
           CheckSum  : Boolean;  { Did checksum pass }
           End;
Const Hexa : Array [0..15] of Char =
      ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

Function GetMachineID:Str42;
Function GetEquipList:Word;
Function LastDrive:Char;
Function FixedDisks:Byte;
Function FirstCD:Byte;
Function TotalCD:Byte;
Function CDPresent:Boolean;
Function GetDefaultDrive:Byte;
Function GetBootDrive:Byte;
Function DriveValid(Drive:Char):Boolean;
Procedure SelectDrive(Drive:Char);
Function Drives:String;
Function WhatCPU:Byte;
Function PCIPresent:Boolean;
Function CoProcessor:Boolean;
Function GameAdapter:Boolean;
Function XMS:Boolean;
Function EMS:Boolean;
Function IsAnsiSys:Boolean;
Function IsAppend:Boolean;
Function IsAssign:Boolean;
Function IsDblSpace:Boolean;
Function IsDesqView:Boolean;
Function IsDos4G:Boolean;
Function IsDosKey:Boolean;
Function IsDoubleDos:Boolean;
Function IsDriverSys:Boolean;
Function IsEmm386:Boolean;
Function IsEMS:Boolean;
Function IsKeyb:Boolean;
Function IsNlsFunc:Boolean;
Function IsShare:Boolean;
Function IsSmartDrv:Boolean;
Function IsXMS:Boolean;
Function IsWinEnh:Boolean;
Procedure ReturnCPUType(WhatCPU:Byte;Var CPU:Str7);
Procedure TestFloppy(DriveSpec:Char;Var DriveReady:Boolean;Var Status:Str12);
Procedure DeviceType(Drive:Byte;Var DeviceCode:Byte;Var Error:Byte);
Procedure ReturnDeviceType(DeviceCode:Byte;Var S:Str25);
Procedure HDInfo(HD:Char;Var HDRec:HDRec);
Procedure EquipList(Var Equip:EquipRec);
Procedure GetBIOSDate(Var Date:Str8);
Procedure SVGA(Var Present:Boolean;Var Fabr:String;Var VersionLo,VersionHi:Byte);
Procedure _4DOS(Var Present:Boolean;Var Version:Str3);
Procedure MemInfo(Var BaseRam:Word;Var ExtRam:Word);
Function ReadCMOS(Addr:Byte):Byte;
Function CMOSCheckSum:Boolean;
Procedure GetCMOS(Var CMOS:CMOSRec);
Procedure ClockOn(Var Result:Real);
Function DiskBenchMark(Drive:Char):Real;
Function VidSeg:Word;
Function Word2Hex(Number:Word):Str4;
Function CheckForWin:WinModeType;
Function FirstHD:Char;
Function FileExists(FileName:String):Boolean;

Implementation
Uses Dos;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'HardwareControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Function LastDrive:Char;Assembler;
Asm
Mov Ah,19h
Int 21h
Push Ax         { save default drive }
Mov Ah,0Eh
Mov Dl,19h
Int 21h
Mov Cl,Al
Dec Cx
@@CheckDrive:
Mov Ah,0Eh       { check if drive valid }
Mov Dl,Cl
Int 21h
Mov Ah,19h
Int 21h
Cmp Cl,Al
Je @@Valid
Dec Cl            { check next lovest drive number }
Jmp @@CheckDrive
@@Valid:
Pop Ax
Mov Dl,Al
Mov Ah,0Eh
Int 21h           { restore default drive }
Mov Al,Cl
Add Al,'A'
End;


Procedure DeviceType(Drive:Byte;Var DeviceCode:Byte;Var Error:Byte);
Var TmpA:Array[0..31] Of Byte;
    Regs:Registers;
Begin
Regs.Ax:=$440D;
Regs.Bx:=Word(Drive);
Regs.Cx:=$0860;
Regs.Dx:=Ofs(TmpA);
Regs.Ds:=Seg(TmpA);
MsDos(Regs);
  If (Regs.Flags And FCarry<>0) Then Begin
  DeviceCode:=$FF; {Error!}
  Error:=Regs.AL
  End
    Else Begin
    DeviceCode:=TmpA[1];
    Error:=0;
    End;
End;

Procedure ReturnDeviceType(DeviceCode:Byte;Var S:Str25);
Begin
  Case DeviceCode Of
  0: S:='320/360 KBytes Floppy';
  1: S:='1.2 MBytes Floppy';
  2: S:='720 KBytes Floppy';
  3: S:='8" Single Density Floppy';
  4: S:='8" Double Density Floppy';
  5: S:='Hard Disk';
  6: S:='Tape Drive';
  7: S:='1.44 MBytes Floppy';
  8: S:='Optical Disk';
  9: S:='2.88 MBytes Floppy';
  Else S:='UnKnown Device';
  End;
End;

Function FixedDisks:Byte;
Begin
FixedDisks:=Mem[$0000:$0475];
End;

Function FirstCD:Byte;Assembler;
Asm
Mov Ax,1500h
XOr Bx,Bx
Int 2Fh
Mov Al,Cl
End;

Function CDPresent:Boolean;Assembler;
Asm
Mov Ax,1500h
XOr Bx,Bx
Int 2Fh
Mov Al,1
Cmp Bx,0
Jne @CDPresent
Mov Al,0
@CdPresent:
End;

Function TotalCD:Byte;Assembler;
Asm
Mov Ax,1500h
XOr Bx,Bx
Int 2Fh
Mov Al,Bl
End;

Function GetDefaultDrive:Byte;Assembler;
Asm
Mov Ah,19h
Int 21h
End;

Function GetBootDrive:Byte;Assembler;
Asm
Mov Ax,3305h
Int 21h
Mov Al,Dl
End;

Function DriveValid(Drive:Char):Boolean;Assembler;
Asm
Mov  Ah,19h
Int  21h
Mov  Bl,Al     {Save Default Drive in Bl}
Mov  Dl,Drive
Sub  Dl,'A'
Mov  Ah,0Eh
Int  21h
Mov  Ah,19h
Int  21h
Mov  Cx,0
Cmp  Al,Dl
Jne  @@1
Mov  Cx,1
Mov  Dl,Bl
Mov  Ah,0Eh
Int  21h
@@1:
Xchg Ax,Cx
End;

Procedure SelectDrive(Drive:Char);Assembler;
Asm
Mov  Dl,Drive
Sub  Dl,'A'
Mov  Ah,0Eh
Int  21h
End;

Procedure TestFloppy(DriveSpec:Char;Var DriveReady:Boolean;Var Status:Str12);
Var Result:Word;
    Drive,Number,Logical:Word;
    Buf:Array[1..512] Of Byte;
Begin
Drive:=Ord(UpCase(DriveSpec))-65;  { 0=a, 1=b, etc }
  If (Drive>1) Or (Drive<0) Then Begin
  Exit; {Do not work on a hard disk}
  End;
DriveReady:=True;
Status:='DriveReady';
Number:=1;
Logical:=1;
Inline (
$55 /                       { PUSH BP         ; Interrupt 25 trashes all}
$1E /                       { PUSH DS         ; Store DS                }
$33 / $C0 /                 { xor  AX,AX      ; set AX to zero          }
$89 / $86 / Result /        { MOV  Result, AX ; Move AX to Result       }
$8A / $86 / Drive /         { MOV  AL, Drive  ; Move Drive to AL        }
$8B / $8E / Number /        { MOV  CX, Number ; Move Number to CX       }
$8B / $96 / Logical /       { MOV  DX, Logical; Move Logical to DX      }
$C5 / $9e / Buf /           { LDS  BX, Buf    ; Move Buf to DS:BX       }
$CD / $25 /                 { INT  25h        ; Call interrupt $25      }
$5B /                       { POP  BX         ; Remove the flags from heap}
$1F /                       { POP  DS         ; Restore DS              }
$5D /                       { POP  BP         ; Restore BP              }
$73 / $04 /                 { JNB  Done       ; Jump ...                }
$89 / $86 / result);        { MOV  Result, AX ; move error code to AX   }
{ Done: }
DriveReady:=(Result=0);
  If (Result<>0) Then Begin
    Case Lo(Result) Of
    0     : Status:='WriteProtect';
    1..4  : Status:='DoorOpen';
    5..12 : Status:='NoFormat';
    Else Status:='DoorOpen';
    End;
  End;
End;

Function Drives:String;Assembler;
Var
   DriveInfo:   Array[1..2]  Of Char;
   Buffer:      Array[1..40] Of Char;
   DriveString: Array[1..25] Of Char;
Asm
Push   Si                     { Save Important Registers }
Push   Di
Push   Es
Push   Ds

Mov    Si,Ss                 { The Stack Segment (SS) points to the }
Mov    Ds,Si                 { VAR's above.  Point DS to it... }
Push   Ds
Pop    Es                     { ...and ES as well. }

Lea    Si,DriveInfo          { DS:SI - Where we test each drive letter }
Lea    Di,Buffer             { ES:DI - FCB Buffer }
Lea    Bx,DriveString        { DS:BX - Our resultant string }

Mov    Byte Ptr [Si],'@'     { The character before 'A' }
XOr    Cx,Cx                 { Zero out CX }

@Scan:
Inc    Byte Ptr [Si]          { Next Drive Letter }
Mov    Byte Ptr [Si+1],':'
Mov    Ax,2906h               { DOS Function 29h - Parse Filename }
Int    21h                    {   DS:SI - String to be parsed }
                                   {   ES:DI - FCB }
Lea    Si,DriveInfo           { DS:SI }
Cmp    Al,00FFh                 { AL = FFh if function fails (invalid }
Je     @NotValid              {     drive letter) }

Inc    Cx                     { Add one more to our string length... }
Push   Cx                     { ...and save it. }
Mov    Cl,Byte Ptr Ds:[Si]    { Grab the valid drive letter... }
Mov    [BX],Cl                { ...and stuff it into our result }
Inc    Bx                     { Next position in result string }
Pop    Cx                     { Get our length counter back }

@NotValid:
Cmp    Byte Ptr [Si],'Z'      { Did we go through all letters? }
Jne    @Scan                  { Nope, so next letter }

Lea    Si,DriveString         { Store DriveString to #Result }
Les    Di,@Result
Inc    Di
Rep    MovSb

XChg   Ax,Di                  { This is the only way to store the }
Mov    Di,Word Ptr @Result    { length that I can get to work. }
Sub    Ax,Di
Dec    Ax
StosB

Pop Ds                        { Restore Important Registers }
Pop Es
Pop Di
Pop Si
End;

Function WhatCPU:Byte;
Begin
  If (Test8086=2) Then         { RTL check stops at 2 = 386}
  Asm
             Inc    Test8086     { 3 = 386, for consistency }
    { Do we have a 386 or a 486? }
    { Does pushf/popf preserve the Alignment Check bit? (386=no, 486=yes) }
             Mov    Bx, Sp       { save current stack pointer }
             And    Sp, Not 3    { align stack to avoid AC fault }
    Db $66;  Pushf
    Db $66;  Pop    Ax
    Db $66;  Mov    Cx, Ax
    Db $66, $35; Dd $40000       { xor AC bit in EFLAGS }
    Db $66;  Push   Ax
    Db $66;  Popf
    Db $66;  Pushf
    Db $66;  Pop    Ax
    Db $66;  XOr    Ax, Cx       { Is AC bit toggled? }
             Je @@1              { if not, we have a 386 }
             And    Sp, Not 3    { align stack to avoid AC fault }
    Db $66;  Push   Cx
    Db $66;  Popf                { restore original AC bit }
             Mov    Sp, Bx       { restore original stack pointer }
             Mov  Test8086, 4    { we know we have at least a 486 }

    { Do we have a 486 or a Pentium? }
    { Does Pushf/Popf preserve the CPUID bit? (486=no, P5=yes) }
    Db $66;  Mov    Ax, Cx       { get original EFLAGS}
    Db $66, $35; Dd $200000      { XOR id bit in flags}
    Db $66;  Push   Ax
    Db $66;  Popf
    Db $66;  Pushf
    Db $66;  Pop    Ax
    Db $66;  XOr    Ax, Cx      { Is CPUID bit toggled? }
             Je @@1             { if not, we have a 486 }
    Db $66;  XOr    Ax, Ax
    Db $F,$A2                   { CPUID, Ax = 0 (get CPUID caps) }
    Db $66;  Cmp    Ax, 1
             Jl @@1             { if < 1, then exit }
    Db $66;  XOr    Ax, Ax
    Db $66;  Inc    Ax
    Db $F,$A2                   { CPUID, Ax = 1 (get CPU info)   }
             And    Ax, $f00    { mask out all but family id }
             Push Cx
             XOr Cx,Cx
             Mov Cl,8
             Shr Ax,Cl
             Pop Cx
             Mov Test8086, Al      { Pentium family = 5 }
   @@1:
  End;
WhatCPU:=Test8086;
End;

Procedure ReturnCPUType(WhatCPU:Byte;Var CPU:Str7);
Begin
CPU:='UnKnown';
  Case WhatCPU Of
  0: CPU:='8086';
  1: CPU:='80286';
  2: CPU:='80386';
  3: CPU:='80386';
  4: CPU:='80486';
  5: CPU:='Pentium';
  End;
End;

Function GetMachineId:Str42;
Var Model : Byte Absolute $F000:$FFFE;
Begin
GetMachineID:='UnKnown Machine type';
  Case Model Of
  $9A : GetMachineID:=('COMPAQ Plus');
  $FF : GetMachineID:=('IBM PC');
  $FE : GetMachineID:=('PC XT, Portable PC');
  $FD : GetMachineID:=('PCjr');
  $FC : GetMachineID:=('Personal Computer AT, PS/2 Models 50 and 60');
  $FB : GetMachineID:=('PC XT (after 1/10/86)');
  $FA : GetMachineID:=('PS/2 Model 30');
  $F9 : GetMachineID:=('Convertible PC');
  $F8 : GetMachineID:=('PS/2 Model 80');
  End;
End;

Procedure HDInfo(HD:Char;Var HDRec:HDRec);
Var Drive:Byte;
    Ax1,Bx1,Cx1,Dx1:Word;
Begin
Drive:=Ord(UpCase(HD))-64;  { 1=a, 2=b, etc }
  Asm
  Mov Ah,0036h
  Mov Dl,Drive
  Int 21h
  Mov Ax1,Ax
  Mov Bx1,Bx
  Mov Cx1,Cx
  Mov Dx1,Dx
  End;
    If (Ax1=$FFFF) Then Begin {Error}
    FillChar(HDRec,SizeOf(HDRec),0);
    Exit;
    End;
HDRec.Size:=LongInt(Ax1)*Cx1*Dx1;
HDRec.Free:=LongInt(Ax1)*Bx1*Cx1;
HDRec.Bytes_Per_Sector:=Cx1;
HDRec.Sectors_Per_Cluster:=Ax1;
HDRec.Total_Number_Clusters:=Dx1;
HDRec.Empty_Clusters:=Bx1;
End;

Function GetEquipList:Word;Assembler;
Asm
Int 11h
End;

Procedure EquipList(Var Equip:EquipRec);
Var Temp:Byte;
    EquipList:Word;
Begin
EquipList:=GetEquipList;
Temp:=Hi(EquipList) Shr 6;
Equip.ParPorts:=Temp;
Temp:=Hi(EquipList) And $0F Shr 1;
Equip.SerialPorts:=Temp;
Equip.FloppyNumber:=0;
  If (Lo(EquipList) And $01)=1 Then Begin
  Temp:=Lo(EquipList) Shr 6 +1;
  Equip.FloppyNumber:=Temp;
  End;
End;

Procedure GetBIOSDate(Var Date:Str8);
Var i:Byte;
Begin
Date:='';
  For i:=1 To 8 Do Begin
  Date:=Date+Chr(Mem[$F000:$FFF4+i])
  End;
End;

Function PCIPresent:Boolean;
  Function PCI:Byte;Assembler;
  Asm
  Mov Ax,0B101h
  Int 001Ah
  Mov Al,Ah
  End;
Begin
  If (PCI=0) Then PCIPresent:=True
    Else PCIPresent:=False;
End;

Function CoProcessor:Boolean;
Var Temp:Byte;
Begin
Temp:=Mem[$0000:$0410];
  If (Temp And 2)=2 Then CoProcessor:=True
    Else CoProcessor:=False;
End;

Function GameAdapter:Boolean;
Var Temp:Byte;
Begin
Temp:=Mem[$0000:$0411];
  If (Temp And 6)=6 Then GameAdapter:=True
    Else GameAdapter:=False;
End;

Function XMS:Boolean;
  Function CheckXMS:Byte;Assembler;
  Asm
  Mov Ax,4300h
  Int 2Fh
  End;
Begin
  If (CheckXMS=$80) Then XMS:=True
    Else XMS:=False;
End;

Function EMS:Boolean;
Var i:Byte;
Const Name:String[8]='EMMXXXX0';
  Function AddrEMS:Word;Assembler;
  Asm
  Mov Ax,3567h
  Int 21h
  Mov Ax,Es
  End;
Begin
EMS:=True;
  For i:=10 To 17 Do Begin
    If Chr(Mem[AddrEMS:i])<>Name[i-9] Then EMS:=False;
  End;
End;

Procedure SVGA(Var Present:Boolean;Var Fabr:String;Var VersionLo,VersionHi:Byte);
Var InfoPtr:Pointer; {Pointer where the cards gives us its info}
    InfoSeg:Word;
    S,D:Word;
    i:Byte;
  Function IsVESA:Byte;Assembler;
  Asm
  Mov Ax,InfoSeg
  Mov Es,Ax
  XOr Di,Di
  Mov Ax,4F00h
  Int 10h
  XChg Ah,Al
  End;
Begin
GetMem(InfoPtr,257); {Reserve memory for card's info}
InfoSeg:=Seg(InfoPtr^);
  If (IsVESA<>0) Then Begin
  Present:=False;
  Fabr:='N/A';
  Exit;
  End
    Else Begin
    Present:=True;
    VersionLo:=Mem[InfoSeg:5];
    VersionHi:=Mem[InfoSeg:4];
    D:=MemW[InfoSeg:6];
    S:=MemW[InfoSeg:8];
    i:=0;
      Repeat
      Inc(i);
      Fabr[i]:=Chr(Mem[S:D+i-1]);
      Until (Mem[S:D+i-1]=0);
    Fabr[0]:=Chr(i);
    FreeMem(InfoPtr,257);
    End;
End;

Procedure _4DOS(Var Present:Boolean;Var Version:Str3);
  Function _4Check:Word;Assembler;
  Asm
  Mov Ax,0D44Dh
  XOr Bh,Bh
  Int 2Fh
  End;

  Function Major:Byte;Assembler;
  Asm
  Mov Ax,0D44Dh
  XOr Bh,Bh
  Int 2Fh
  Mov Al,Bl
  End;

  Function Minor:byte;Assembler;
  Asm
  Mov Ax,0D44Dh
  XOr Bh,Bh
  Int 2Fh
  Mov Al,Bh
  End;
Begin
  If (_4Check<>$44DD) Then Begin
  Present:=False;
  Exit;
  End
    Else Begin
    Present:=True;
    Version:=Chr(Major)+'.'+Chr(Minor);
    End;
End;

Function IsAnsiSys:Boolean;Assembler;
Asm
Mov Ax,1A00H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsAppend:Boolean;Assembler;
Asm
Mov Ax,0B700H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsAssign:Boolean;Assembler;
Asm
Mov Ax,0600H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsDblSpace:Boolean;Assembler;
Asm
Mov Ax,4A11H
XOR BX,BX
Int 2FH
Cmp Ax,0
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsDesqView:Boolean;Assembler;
Asm
Mov AH,2BH
Mov CX,4445H
Mov DX,5351H
Mov Al,1
Int 21H
Cmp Al,0FFH
Je  @NOTINST
Mov Al,1
Jmp @END
@NOTINST: Mov Al,0
@END:
End;

Function IsDos4G:Boolean;Assembler;
Asm
Mov Ax, 0FF00H
Mov DX,0078H
Int 21H
Cmp Al,0
Jne @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsDosKey:Boolean;Assembler;
Asm
Mov Ax,4800H
Int 2FH
Cmp Al,0
Jne  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsDoubleDos:Boolean;Assembler;
Asm
Mov Ax,0E400H
Int 21H
Cmp Al,0
Jne @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsDriverSys:Boolean;Assembler;
Asm
Mov Ax,0800H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsEmm386:Boolean;Assembler;
Asm
Mov Ax,0FFA5H
Int 67H
Cmp Ax,845AH
Jne @SECCmp
@OK:
Mov Al,1
Jmp @END
@SECCmp:
Cmp Ax,84A5H
Je @OK
XOR Al,Al
@END:
End;

Function IsEMS:Boolean;Assembler;
Asm
Mov AH,46H
Int 67H
Cmp AH,00H
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsKeyb:Boolean;Assembler;
Asm
Mov Ax,0AD80H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsNlsFunc:Boolean;Assembler;
Asm
Mov Ax,1400H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsShare:Boolean;Assembler;
Asm
Mov Ax,1000H
Int 2FH
Cmp Al,0FFH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsSmartDrv:Boolean;Assembler;
Asm
Mov Ax,4A10H
Mov BX,0
Mov CX,0EBABH
Int 2FH
Cmp Ax,0BABEH
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsXMS:Boolean;Assembler;
Asm
Mov Ax, 4300H
Int 2FH
Cmp Al,80H
Je  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function IsWinEnh:Boolean;Assembler;
Asm
Mov Ax,1600H
Int 2FH
Cmp Al,0
Jne  @OK
Mov Al,0
Jmp @END
@OK: Mov Al,1
@END:
End;

Function ReadCMOS(Addr:Byte):Byte;Assembler;
Asm
Cli
XOr Ax,Ax
Mov Al,Addr
Out 70h,Al
In Al,71h
Sti
End;

Function CmosCheckSum:Boolean;
{ performs checksum on CMOS and returns true if ok }
Var CheckSum1,CheckSum2:Word;
    Count:Byte;
Begin
CheckSum1:=0;
  For Count:=$10 To $2D Do
  Inc(CheckSum1,ReadCMOS(Count));
CheckSum2:=(Word(256)*ReadCMOS($2E))+ReadCMOS($2F);
  If (CheckSum1=CheckSum2) Then
  CmosCheckSum:=True
    Else
    CmosCheckSum:=False;
End;


Procedure GetCMOS(Var CMOS:CMOSRec);
Var Regs:Registers;
    Floppy:Byte;
Const ScreenName:Array [0..3] Of String[10]=('EGA/VGA','CGA 40col',
                                             'CGA 80col','Monochrome');
      FloppyName:Array [0..5] Of String[11]=('None','5.25" 360K',
                                           '5.25" 1.2M','3.5" 720K',
                                           '3.5" 1.44M','3.5" 2.88M');
  Function BitIsSet(CheckWord:Word;AndValue:Word):Boolean;
  Begin
  BitIsSet:=(CheckWord And AndValue)=AndValue;
  End;

    Function NoCarry:Boolean;
    Begin
    NoCarry:=(Regs.Flags AND fCarry)=$0000
    End;

Begin
FillChar(CMOS,SizeOf(CMOS),0);
Regs.Ah:=$C0;
Intr($15,Regs);
  If NoCarry Or (Mem[$F000:$FFFE]<=$FC) Then Begin
    With CMOS Do Begin
    Found:=True;
    VideoType:=ScreenName[(readCMOS ($14) SHR 4) AND 3];
    CoProc:=BitIsSet(ReadCMOS($14),1);
    Floppy:=ReadCMOS($10);
      If (Floppy Shr 4)<5 Then
      FloppyA:=FloppyName[Floppy Shr 4]
      Else
      FloppyA:='Unknown';
        If (Floppy And $0F)<5 Then
        FloppyB:=FloppyName[Floppy And $0F]
        Else
        FloppyB:='Unknown';
    Hard0:=ReadCMOS($12);
    Hard0:=Hard0 Shr 4;
    Hard1:=ReadCmos($12);
    Hard1:=Hard1 And $0F;
      If (Hard0=$F) Then
      Hard0:=ReadCMOS($19)
      Else Hard0:=$FF; {None->Remenber to check!}
        If (Hard1=$F) Then
        Hard1:=ReadCMOS($1A)
        Else Hard1:=$FF;
    ConvenRam:=Word(256)*ReadCMOS($16)+ReadCMOS($15); { value in K }
    ExtendRam:=Word(256)*ReadCMOS($18)+ReadCMOS($17); { value in K }
    CheckSum:=CmosCheckSum;
    End;
  End
    Else Begin
    CMOS.Found:=False;
    End;
End;

Procedure MemInfo(Var BaseRam:Word;Var ExtRam:Word);
Const Int15:LongInt=$F000F859;
Var Base,Ext:Word;
Begin
  Asm
  Int 12h
  Mov Base,Ax
  Mov Ah,88h
  PushF
  Call Int15
  Mov Ext,Ax
  End;
BaseRam:=Base;
ExtRam:=Ext;
End;

Procedure ClockOn(Var Result:Real);
Var H,M,S,S100:Word;
Begin
GetTime(H,M,S,S100);
Result:=(H*3600)+(M*60)+S+(S100/100);
End;

Function DiskBenchMark(Drive:Char):Real;
Var CurDir:String;
    Buff:Buffer;
    TestFile:File;
    WriteTime,ReadTime,T1,T2:Real;
    Cont:Word;
Begin
DiskBenchMark:=0;
  If DriveValid(Drive) Then Exit;
  If (DiskFree(Ord(UpCase(Drive))-64)<1648576) Then Exit;
  If (MaxAvail<SizeOf(Buff)) Then Exit;
GetDir(0,CurDir);
SelectDrive(Drive);
New(Buff);
FillChar(Buff^,SizeOf(Buff^),100);
Assign(TestFile,'Test.Tmp');
Rewrite(TestFile,1);
ClockOn(T1);
  For Cont:=1 To 1024 Do Begin
  BlockWrite(TestFile,Buff^,SizeOf(Buff^)); {Write 1Mb To Disk}
  End;
ClockOn(T2);
WriteTime:=(T2-T1);
Reset(TestFile,1);
ClockOn(T1);
  For Cont:=1 To 1024 Do Begin
  BlockRead(TestFile,Buff^,SizeOf(Buff^)); {Read 1Mb from Disk}
  End;
ClockOn(T2);
ReadTime:=(T2-T1);
DiskBenchMark:=2/(WriteTime+ReadTime);
Dispose(Buff);
ChDir(CurDir);
Erase(TestFile);
End;

Function VidSeg:Word;
Begin
  If Mem[$0000:$00449]=7 Then Begin
  VidSeg:=$B000;
  End
    Else Begin
    VidSeg:=$B800;
    End;
End;

Function Word2Hex(Number:Word):Str4;
Var Ch1 , Ch2 : Byte;
    Ch3 , Ch4 : Byte;
Begin
Ch1 := (Number Shr 8) Shr 4;
Ch2 := (Number Shr 8) - (Ch1 Shl 4);
Ch3 := (Number And $FF) Shr 4;
Ch4 := (Number And $FF) - (Ch3 Shl 4);
Word2Hex := Hexa[Ch1]+Hexa[Ch2]+Hexa[Ch3]+Hexa[Ch4];
End;

Function CheckForWin:WinModeType; Assembler;
Asm
Mov Ax,1600h
Int 2Fh
Cmp Al,1
Jbe @@CheckRealStd
Cmp Al,80h
Jae @@CheckRealStd
Mov Al,2
Jmp @@ExitPoint
@@CheckRealStd:
Mov Ax,4680h
Int 2Fh
Or Ax,Ax
Jnz @@NotWin
Mov Al,1
Jmp @@ExitPoint
@@NotWin:
Xor Al,Al
@@ExitPoint:
End;

Function FirstHD:Char;
Var LDrive:String;
    i:Byte;
    Device,Error:Byte;
Begin
LDrive:=Drives;
  For i:=1 To Length(LDrive) Do Begin
  DeviceType(Ord(UpCase(LDrive[i]))-63,Device,Error);
    If (Device=5) Then Begin
    FirstHD:=LDrive[i];
    End;
  End;
End;

Function FileExists(FileName:String):Boolean;Assembler;
Asm
PUSH DS          {Save DS                         }
LDS  SI,Filename {DS:SI => Filename               }
XOR  BX,BX       {Clear BX                        }
MOV  BL,[SI]     {BX = Length(Filename)           }
INC  SI          {DS:SI => Filename[1]            }
MOV  DX,SI       {DS:DX => Filename[1]            }
MOV  [SI+BX],BH  {Append Ascii 0 to Filename      }
MOV  AX,4300h    {Get Attribute Function Code     }
INT  21h         {Get File Attributes             }
MOV  AL,BH       {Default Result = FALSE          }
ADC  CL,CL       {Attribute * 2 + Carry Flag      }
AND  CL,31h      {Directory or VolumeID or Failed }
JNZ  @@Done      {Yes - Exit                      }
INC  AL          {No - Change Result to TRUE      }
@@Done:
  POP  DS          {Restore DS                      }
End; {FileExists}

Begin
CopyRight;
End.