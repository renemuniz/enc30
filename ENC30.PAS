{$M 16384,10240,653600}    (* Stack=16K; Heap=10,640K*)
{$R-,S+,G-,A+}
Program Encryptor;
Uses Crt,Dos,
     CrtControl,
     AdvancedCrtControl,
     MouseControl,
     KeyboardControl,
     HardwareTools,
     EncryptControl,
     CRCControl,
     StopHack;

Type Str20=String[20];
     Str28=String[28];
     Buf=String[80];
     Buff=Array [1..110] Of Buf;
     Buffer=^Buff;

     HeaderInfo=Record
     Signature,CRC:String[8];
     Extension:String[3];
     Seed1,Seed2:Word;
     Method:Byte;
     End;

Const DaysOfWeek:Array[0..6] Of String[13]=('Domingo','Segunda-Feira','Terca-Feira','Quarta-Feira','Quinta-Feira',
                                            'Sexta-Feira','S bado');
      KeyValue=$1E;
Var Scr:Screen;
    Keyb:Keyboard;
    M:Mouse;
    ErrorCode,i,OrigMode,Choice,PointPos:Byte;
    D,Month,Y,DoW:Word;
    Error,KeyboardOK,MouseOK:Boolean;
    CPath:String;
    Method:Byte;
    SourcePath,DestPath,TempPath:String;
    Password:Str20;
    SourceFile,DestFile:File;
    Attrib,Seed1,Seed2:Word;
    Header:HeaderInfo;
    CRC:LongInt;
    CRCStr:String8;
    HlpFile:File;
    ExitSave:Pointer;
Label HelpStart,ExitGo,GoEncode,GoDecode,Jump,ReDraw;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'Encryptor V3.0 (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Procedure InitScreen;
Begin
Scr.Init;
OrigMode:=LastMode;
TextMode(CO80);
Scr.SetBlink(True);
TextBackGround(Black);
TextColor(LightGray);
ClrScr;
GoToXY(2,25);
Write('Encryptor - por Rene M.Corrˆa Muniz');
Scr.OpenWindow(24,9,55,15,White,Green);
Scr.Center(33,1,'Encryptor');
Scr.Center(33,2,'ÄÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÄ');
Scr.Center(33,3,'Release 3.0');
Scr.Center(33,4,'15/07/1998');
Scr.Center(33,5,'ÄÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÄ');
TextColor(Yellow);
Scr.Center(36,6,'Please wait...');
M.Init;
M.InitMouse;
M.MoveCursor(56,25);
M.SetTextCursor(Blue,Yellow);
M.MouseWindow(0,24,79,24);
Keyb.Init;
Delay(700);
Scr.DosReturn;
End;

Procedure CheckResources;
Begin
  If Scr.IsMono Then Begin
  Scr.DosReturn;
  WriteLn('Este programa foi desenvolvido para ser usado com uma placa gr fica colorida.');
  Halt(1);
  End;
    If (MaxAvail<10240) Then Begin
    Scr.DosReturn;
    WriteLn('Mem¢ria insuficiente. Vocˆ deve ter pelo menos 10Kb de mem¢ria para acessar o programa.');
    Halt(1);
    End;
End;

Procedure ExitP;Far;
Begin
ExitProc:=ExitSave;
M.CloseMouse;
Scr.DosReturn;
TextMode(OrigMode);
Scr.DosReturn;
WriteLn('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
WriteLn('º    **  Obrigado por usar Encryptor V3.0 - Todos os direitos reservados **   º');
WriteLn('º                                                                             º');
WriteLn('º  Este programa foi escrito por Rene M.Corrˆa Muniz especialmente para a par-º');
WriteLn('ºticipacao no concurso nacional de softwares 1998 do minist‚rio da educacao e º');
WriteLn('ºdo desporto MEC.                                                             º');
WriteLn('º                                                                             º');
WriteLn('º * Categoria Participante: Geral                                             º');
WriteLn('º * Data: 15/07/1998                                                          º');
WriteLn('ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
WriteLn;
End;

Procedure ReallocateMemory(P:Pointer);Assembler;
Asm
  Mov  AX, PrefixSeg
  Mov  ES, AX
  Mov  BX, word ptr P+2
  Cmp  Word ptr P,0
  Je   @OK
  Inc  BX
 @OK:
  Sub  BX, AX
  Mov  AH, $4A
  Int  $21
  Jc   @Out
  Les  DI, P
  Mov  Word Ptr HeapEnd,DI
  Mov  Word Ptr HeapEnd+2,ES
 @Out:
End;

Function Execute(Name,Tail:PathStr):Word;Assembler;
Asm
  Push Word Ptr HeapEnd+2
  Push Word Ptr HeapEnd
  Push Word Ptr Name+2
  Push Word Ptr Name
  Push Word Ptr Tail+2
  Push Word Ptr Tail
  Push Word Ptr HeapPtr+2
  Push Word Ptr HeapPtr
  Call ReallocateMemory
  Call SwapVectors
  Call Dos.Exec
  Call SwapVectors
  Call ReallocateMemory
  Mov  AX, DosError
  Or   AX, AX
  Jnz  @Done
  Mov  AH, $4D
  Int  $21 { Return error in will be in AX (if any) }
 @Done:
End;

Procedure UpperStr(Var Str:String);
  InLine(
    $8C/$DA/               {      mov   DX,DS               }
    $5E/                   {      pop   SI                  }
    $1F/                   {      pop   DS                  }
    $FC/                   {      cld                       }
    $AC/                   {      lodsb                     }
    $30/$E4/               {      xor   AH,AH               }
    $89/$C1/               {      mov   CX,AX               }
    $E3/$12/               {      jcxz  @30                 }
    $BB/Ord('a')/Ord('z')/ {      mov   BX,'za'             }
    $AC/                   { @15: lodsb                     }
    $38/$D8/               {      cmp   AL,BL               }
    $72/$08/               {      jb    @28                 }
    $38/$F8/               {      cmp   AL,BH               }
    $77/$04/               {      ja    @28                 }
    $80/$6C/$FF/$20/       {      sub   BYTE PTR [SI-1],$20 }
    $E2/$F1/               { @28: loop  @15                 }
    $8E/$DA);              { @30: mov   DS,DX               }

Procedure HelpScroll(Const Path:String);
Var FBuffer:Buffer;
    FText:Text;
    Line,Cont,i,TempX,TempY:Byte;
    Result,Temp:Word;

    Procedure DecryptString(Var Str:Buf);
    Var i:Byte;
    Const KeyCode=$1;
    Begin
      For i:=1 To 80 Do Begin
      Str[i]:=Chr(Ord(Str[i]) XOr KeyCode);
      End;
    End;

Begin
  If (MaxAvail<SizeOf(Buff)) Then Begin  {8910 Bytes Required}
  Scr.DosReturn;
  Scr.BackAscii(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao h  mem¢ria suficiente para exe-cutar esta operacao.');
  Exit;
  End;
    If Not FileExists(Path) Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
    Exit;
    End;
New(FBuffer);
Scr.CursorSize:=Small;
Scr.Cursor;
Assign(FText,Path);
Reset(FText);
Window(1,1,80,25);
TextBackGround(Cyan);
ClrScr;
GoToXY(1,1);
TextBackGround(White);
ClrEol;
GoToXY(1,25);
ClrEol;
GoToXY(1,1);
TextColor(Black);
Scr.Center(79,1,'Encryptor V3.0 - Ajuda On-Line');
GoToXY(1,25);
TextColor(Red);
Write(' ',#24,',',#25);
TextColor(Black);
Write(' Movimento  ');
TextColor(Red);
Write('PgDn/PgUp ');
TextColor(Black);
Write('Muda a p gina  ');
TextColor(Red);
Write('Esc');
TextColor(Black);
Write(' Sair');
Window(1,2,80,24);
GoToXY(1,1);
TextBackGround(Cyan);
WriteLn('Carregando o arquivo. Aguarde...');
Line:=0;
Cont:=0;
ClrScr;
    While Not Eof(FText) And (Cont<110) Do Begin
    Inc(Cont);
    ReadLn(FText,FBuffer^[Cont]); {Load File to Memory}
    DecryptString(FBuffer^[Cont]);
    End;
  For i:=1 To 23 Do Begin
    If (Line<Cont) Then Begin
    Inc(Line);
    GoToXY(1,i);
    Write(FBuffer^[Line]);
    End;
  End;
    Repeat
    Keyb.InKey;
      If (Keyb.Key=DownArrow) Then Begin
        If (Line<Cont) Then Begin
        Inc(Line);
        Scr.ScrollUp(2,24,1,79,Cyan);
        Scr.GoXY(1,24);
        Write(FBuffer^[Line]);
        End;
      End
        Else If (Keyb.Key=UpArrow) Then Begin
          If (Line>23) Then Begin
          Dec(Line,23);
          Scr.ScrollDown(2,24,1,79,Cyan);
          Scr.GoXY(1,2);
          Write(FBuffer^[Line]);
          Inc(Line,22);
          End;
        End
          Else If (Keyb.Key=PgDn) Then Begin
            If (Cont-Line)>=23 Then Begin
            ClrScr;
              For i:=1 To 23 Do Begin
                If (Line<Cont) Then Begin
                Inc(Line);
                GoToXY(1,i);
                Write(FBuffer^[Line]);
                End;
              End;
            End;
          End
            Else If (Keyb.Key=PgUp) Then Begin
              If (Line>=46) Then Begin
              Dec(Line,46);
              ClrScr;
                For i:=1 To 23 Do Begin
                Inc(Line);
                GoToXY(1,i);
                Write(FBuffer^[Line]);
                End;
              End
                Else If (Line In [24..45]) Then Begin
                Line:=0;
                ClrScr;
                  For i:=1 To 23 Do Begin
                  Inc(Line);
                  GoToXY(1,i);
                  Write(FBuffer^[Line]);
                  End;
                  End;
            End;
    Until (Keyb.Key=Esc);
Close(FText);
Dispose(FBuffer);
End;

Procedure SystemInfo;
Var KeybOK,MOK,Found,Pass:Boolean;
    Choice,VersionLo,VersionHi:Byte;
    Equip:EquipRec;
    CPUType:Str7;
    MachineID:Str42;
    BaseRAM,ExtRAM,DosVer:Word;
    CmosInfo:CMOSRec;
    BiosDate:Str8;
    LDrives:String[20];
    Man:String;
    HDRecord:HDRec;
    TransferRate:Real;
Label StartHelp,ReDraw,Done,DownCMOS,UpCMOS,DownBIOS,UpBIOS,MSDOS,Inf;

  Function Logical(Parameter:Boolean):Str3;
  Begin
    If Parameter Then Begin
    Logical:='Sim';
    End
      Else Begin
      Logical:='Nao';
      End;
  End;

Begin
ReDraw:
Window(1,1,80,25);
GoToXY(1,1);
M.MoveCursor(65,25);
Scr.BackASCII(#176,Blue,LightGray);
TextBackGround(Blue);
ClrEol;
TextColor(White);
Scr.Center(79,1,'System Info');
Scr.ShadedWindow(3,6,22,13,White,Blue);
Window(3,6,22,12);
Scr.Center(22,1,' Pesquisar em ');
Window(4,7,21,11);
TextBackGround(White);
GoToXY(1,2);
ClrEol;
TextColor(Yellow);
Scr.Center(20,2,'Inform. Gerais');
TextBackGround(Blue);
Scr.Center(20,3,'CMOS');
Scr.Center(20,4,'BIOS');
Scr.Center(20,5,'Ms-Dos');
Scr.ShadedWindow(27,3,76,22,White,Blue);
Window(1,1,80,25);
TextBackGround(White);
GoToXY(1,25);
ClrEol;
TextColor(Red);
Write(' ',#25);
TextColor(Black);
Write(' Pr¢ximo  ');
TextColor(Red);
Write(#24);
TextColor(Black);
Write(' Anterior  ');
TextColor(Red);
Write('ESC ');
TextColor(Black);
Write('Retorna ao Menu Principal  ');
TextColor(Red);
Write('F1 ');
TextColor(Black);
Write('Ajuda');
MOK:=False;
KeybOK:=False;
Choice:=1;
EquipList(Equip);
ReturnCPUType(WhatCPU,CPUType);
MachineID:=GetMachineID;
MemInfo(BaseRAM,ExtRAM);
M.MoveCursor(66,25);
Window(28,4,75,21);
TextColor(LightCyan);
TextBackGround(Blue);
WriteLn(' ',#254,' Informacoes Gerais - Equipamento Detectado');
TextColor(White);
WriteLn;
WriteLn(' ',#254,' Processador Central: ',CPUType);
WriteLn(' ',#254,' N£mero de Portas Paralelas: ',Equip.ParPorts);
WriteLn(' ',#254,' N£mero de Portas Seriais (RS-232): ',Equip.SerialPorts);
WriteLn(' ',#254,' N£mero de Drives para Discos Flex¡veis: ',Equip.FloppyNumber);
WriteLn(' ',#254,' ID:',MachineID);
GoToXY(1,8);
WriteLn(' ',#254,' N£mero de Discos R¡gidos (HD): ',FixedDisks);
WriteLn(' ',#254,' Boot Drive: ',UpCase(Char(GetBootDrive+64)));
WriteLn(' ',#254,' Coprocessador Matem tico: ',Logical(CoProcessor));
WriteLn(' ',#254,' Joystick/Adaptador de Jogos: ',Logical(GameAdapter));
WriteLn(' ',#254,' Adaptador de v¡deo PCI: ',Logical(PCIPresent));
WriteLn(' ',#254,' Mem¢ria Estendida: ',Logical(EMS));
  If Not EMS Then Begin
  WriteLn(' ',#254,' Mem¢ria Expandida: ',Logical(False));
  End
    Else Begin
    WriteLn(' ',#254,' Mem¢ria Expandida: ',Logical(IsXMS));
    End;
WriteLn(' ',#254,' Mem¢ria Convencional (em Kb): ',BaseRAM);
WriteLn(' ',#254,' Mem¢ria F¡sica (em Kb): ',ExtRAM);
WriteLn(' ',#254,' Total de Mem¢ria (em Kb): ',(ExtRAM+BaseRAM));
Pass:=False;
  Repeat
    While Not KeyPressed Do Begin
    M.GetMouseState;
      If (M.Bt=1) And (M.X In [1..64]) Then Begin
        Case M.X Of
         1..11:Begin
         Window(1,1,80,25);
         GoToXY(1,25);
         TextBackGround(Green);
         TextColor(Red);
         Write(' ',#25);
         TextColor(Black);
         Write(' Pr¢ximo ');
         M.MoveCursor(80,M.Y);
         M.MoveCursor(M.X,M.Y);
           While M.Bt=1 Do Begin
           M.GetMouseState;
           End;
         GoToXY(1,25);
         TextBackGround(White);
         TextColor(Red);
         Write(' ',#25);
         TextColor(Black);
         Write(' Pr¢ximo ');
         M.MoveCursor(80,M.Y);
         M.MoveCursor(M.X,M.Y);
           Case Choice Of
           1:GoTo DownCMOS;
           2:GoTo DownBIOS;
           3:GoTo MSDOS;
           End;
         End;
           12..23:Begin
           TextBackGround(Green);
           TextColor(Red);
           Window(1,1,80,25);
           GoToXY(12,25);
           Write(' ',#24);
           TextColor(Black);
           Write(' Anterior ');
           M.MoveCursor(80,M.Y);
           M.MoveCursor(M.X,M.Y);
             While M.Bt=1 Do Begin
             M.GetMouseState;
             End;
           GoToXY(12,25);
           TextBackGround(White);
           TextColor(Red);
           Write(' ',#24);
           TextColor(Black);
           Write(' Anterior ');
           M.MoveCursor(80,M.Y);
           M.MoveCursor(M.X,M.Y);
             Case Choice Of
             4:GoTo UpBIOS;
             3:GoTo UpCMOS;
             2:GoTo Inf;
             End;
           End;
             24..54:Begin
             TextBackGround(Green);
             TextColor(Red);
             Window(1,1,80,25);
             GoToXY(24,25);
             Write(' ESC');
             TextColor(Black);
             Write(' Retorna ao Menu Principal ');
             M.MoveCursor(80,M.Y);
             M.MoveCursor(M.X,M.Y);
               While M.Bt=1 Do Begin
               M.GetMouseState;
               End;
             GoToXY(24,25);
             TextBackGround(White);
             TextColor(Red);
             Write(' ESC');
             TextColor(Black);
             Write(' Retorna ao Menu Principal ');
             M.MoveCursor(80,M.Y);
             M.MoveCursor(M.X,M.Y);
             GoTo Done;
             End;
               55..64:Begin
               TextBackGround(Green);
               TextColor(Red);
               Window(1,1,80,25);
               GoToXY(55,25);
               Write(' F1');
               TextColor(Black);
               Write(' Ajuda ');
               M.MoveCursor(80,M.Y);
               M.MoveCursor(M.X,M.Y);
                 While M.Bt=1 Do Begin
                 M.GetMouseState;
                 End;
               GoToXY(55,25);
               TextBackGround(White);
               TextColor(Red);
               Write(' F1');
               TextColor(Black);
               Write(' Ajuda ');
               M.MoveCursor(80,M.Y);
               M.MoveCursor(M.X,M.Y);
               GoTo StartHelp;
               End;
        End;
      End;
    End;
  If Pass=False Then Begin
  Keyb.Inkey;
  End
    Else Begin
    Pass:=False;
    End;
    Case Keyb.Key Of
      DownArrow:Begin
        Case Choice Of
          1:Begin
          DownCMOS:
          Inc(Choice);
          Window(4,7,21,11);
          TextColor(Yellow);
          TextBackGround(Blue);
          GoToXY(1,2);
          ClrEol;
          Scr.Center(20,2,'Inform. Gerais');
          TextBackGround(White);
          GoToXY(1,3);
          ClrEol;
          Scr.Center(20,3,'CMOS');
          TextBackGround(Blue);
          Window(28,4,75,21);
          TextBackGround(Blue);
          ClrScr;
          {Call CMOS Procedure}
          GetCMOS(CMOSInfo);
          TextColor(LightCyan);
          Write(' ',#254,' CMOS - Informacoes Gerais');
          WriteLn;
          TextColor(White);
          WriteLn;
            With CMOSInfo Do Begin
              If Found Then Begin
              WriteLn(' ',#254,' CMOS presente: ',Logical(Found));
              WriteLn(' ',#254,' Video Detectado: ',VideoType);
              WriteLn(' ',#254,' Coprocessador Num‚rico presente: ',Logical(Coproc));
                If (FloppyA='None') Then Begin
                WriteLn(' ',#254,' Drive de Disquete A: ','Nenhum');
                End
                  Else Begin
                  WriteLn(' ',#254,' Drive de Disquete A: ',FloppyA);
                  End;
                If (FloppyB='None') Then Begin
                WriteLn(' ',#254,' Drive de Disquete B: ','Nenhum');
                End
                  Else Begin
                  WriteLn(' ',#254,' Drive de Disquete B: ',FloppyB);
                  End;
                If (Hard0=255) Then Begin
                WriteLn(' ',#254,' Identificacao do Disco R¡gido #1: ','Nenhuma N/A');
                End
                  Else Begin
                  WriteLn(' ',#254,' Identificacao do Disco R¡gido #1: ',Hard0);
                  End;
                If (Hard1=255) Then Begin
                WriteLn(' ',#254,' Identificacao do Disco R¡gido #2: ','Nenhuma N/A');
                End
                  Else Begin
                  WriteLn(' ',#254,' Identificacao do Disco R¡gido #2: ',Hard1);
                  End;
              GoToXY(1,10);
              WriteLn(' ',#254,' Mem¢ria Convencional: ',ConvenRAM,'Kb');
              WriteLn(' ',#254,' Mem¢ria Estendida: ',ExtendRAM,'Kb');
              WriteLn(' ',#254,' CMOS CheckSum v lido: ',Logical(CheckSum));
              WriteLn(' ',#254,' Configurado Corretamente: ',Logical(CheckSum));
              End
                Else Begin
                WriteLn(' ',#254,' CMOS presente: Nao encontrado');
                End;
            End;
          End;
            2:Begin
            DownBIOS:
            Inc(Choice);
            Window(4,7,21,11);
            TextColor(Yellow);
            TextBackGround(Blue);
            GoToXY(1,3);
            ClrEol;
            Scr.Center(20,3,'CMOS');
            TextBackGround(White);
            GoToXY(1,4);
            ClrEol;
            Scr.Center(20,4,'BIOS');
            Window(28,4,75,21);
            TextBackGround(Blue);
            ClrScr;
            {Call BIOS Procedure}
            GetBiosDate(BiosDate);
            M.GetMouseInfo;
            TextColor(LightCyan);
            Write(' ',#254,' BIOS - Informacoes Gerais');
            WriteLn;
            TextColor(White);
            WriteLn;
            WriteLn(' ',#254,' Data do BIOS detectada: ',BIOSDate);
            WriteLn(' ',#254,' Mouse presente: ',Logical(M.MouseFound));
              If (M.MouseFound) Then Begin
              WriteLn(' ',#254,' N£mero de botoes: ',M.Buttons);
              WriteLn(' ',#254,' Tipo do Mouse: ',M.MouseInfo.MouseType);
              WriteLn(' ',#254,' Versao do Driver: ',M.MouseInfo.DriverLo,'.',M.MouseInfo.DriverHi);
              WriteLn(' ',#254,' Trabalhando com IRQ: ',M.MouseInfo.IRQ);
              End;
            Scr.DetectVideo;
              If (Scr.VideoCard=None) Then Begin
              WriteLn(' ',#254,' Placa de V¡deo: Nenhuma');
              End
                Else Begin
                  Case Scr.VideoCard Of
                  Mono:WriteLn(' ',#254,' Placa de V¡deo: Monocrom tica');
                  Cga:WriteLn(' ',#254,' Placa de V¡deo: CGA');
                  EgaMono:WriteLn(' ',#254,' Placa de V¡deo: EGAMono');
                  EgaColor:WriteLn(' ',#254,' Placa de V¡deo: EGAColor');
                  VgaMono:WriteLn(' ',#254,' Placa de V¡deo: VGAMono');
                  VgaColor:WriteLn(' ',#254,' Placa de V¡deo: VGAColor');
                  McgaMono:WriteLn(' ',#254,' Placa de V¡deo: MCGAMono');
                  McgaColor:WriteLn(' ',#254,' Placa de V¡deo: MCGAColor');
                  End;
                End;
            SVGA(Found,Man,VersionLo,VersionHi);
              If Found Then Begin
              WriteLn(' ',#254,' Placa de V¡deo SVGA (VESA): ',Logical(Found));
              WriteLn(' ',#254,' Fabricante: ',Man);
              WriteLn(' ',#254,' Versao: ',VersionLo,'.',VersionHi);
              End
                Else Begin
                WriteLn(' ',#254,' Placa de V¡deo SVGA (VESA): Nao');
                End;
             WriteLn(' ',#254,' Mem¢ria de Apresentacao no Segmento: ',Word2Hex(VidSeg),'h');
               If (CheckForWin=NoWin) Then Begin
               WriteLn(' ',#254,' Windows in BackGround: Nao, modo REAL');
               End
                 Else Begin
                 WriteLn(' ',#254,' Windows in BackGround: Sim');
                   Case CheckForWin Of
                   RealStd:WriteLn(' ',#254,' Modo Operacional: Standard');
                   Enhanced:WriteLn(' ',#254,' Modo Operacional: Enhanced');
                   End;
                 End;
            End;
              3:Begin
              MSDOS:
              Inc(Choice);
              Window(4,7,21,11);
              TextColor(Yellow);
              TextBackGround(Blue);
              GoToXY(1,4);
              ClrEol;
              Scr.Center(20,4,'BIOS');
              TextBackGround(White);
              GoToXY(1,5);
              ClrEol;
              Scr.Center(20,5,'Ms-Dos');
              Window(28,4,75,21);
              TextBackGround(Blue);
              ClrScr;
              {Call MS-DOS Procedure}
              TextColor(LightCyan);
              Write(' ',#254,' MS-DOS - Informacoes Gerais');
              WriteLn;
              TextColor(White);
              WriteLn;
              DosVer:=DosVersion;
                If (Lo(DosVer)=7) And (Hi(DosVer)=0) Then Begin
                WriteLn(' ',#254,' Versao atual: ',Lo(DosVer),'.',Hi(DosVer),'  (Windows 95)');
                End
                  Else If (Lo(DosVer)=7) And (Hi(DosVer)=10) Then Begin
                  WriteLn(' ',#254,' Versao atual: ',Lo(DosVer),'.',Hi(DosVer),'  (Windows 98)');
                  End
                    Else Begin
                    WriteLn(' ',#254,' Versao atual: ',Lo(DosVer),'.',Hi(DosVer));
                    End;
              TextColor(Yellow);
              WriteLn(' ',#254,' DOS Standard Device Drivers');
              TextColor(White);
              WriteLn(' ',#254,' Append.Exe: ',Logical(IsAppend),'     ',#254,' Ansi.Sys: ',Logical(IsAnsiSys));
              WriteLn(' ',#254,' DblSpace.Bin: ',Logical(IsDblSpace),'   ',#254,' DosKey.Com: ',Logical(IsDosKey));
              WriteLn(' ',#254,' Dos4G/PMode: ',Logical(IsDos4G),'    ',#254,' DoubleDOS: ',Logical(IsDoubleDOS));
              WriteLn(' ',#254,' Assign.Com: ',Logical(IsAssign),'     ',#254,' DesqView: ',Logical(IsDesqView));
                If EMS Then Begin
                WriteLn(' ',#254,' Driver.Sys: ',Logical(IsDriverSys),'     ',#254,' EMM386: ',Logical(IsEMM386));
                End
                  Else Begin
                  WriteLn(' ',#254,' Driver.Sys: ',Logical(IsDriverSys),'     ',#254,' EMM386: ',Logical(False));
                  End;
              WriteLn(' ',#254,' EMS: ',Logical(EMS),'            ',#254,' Keyboard.Sys: ',Logical(IsKeyb));
              WriteLn(' ',#254,' NlsFunc.Exe: ',Logical(IsNlsFunc),'    ',#254,' Share.Exe: ',Logical(IsShare));
                If EMS Then Begin  {SmartDrive Not Work}
                WriteLn(' ',#254,' XMS: ',Logical(IsXMS));
                End
                  Else Begin
                  WriteLn(' ',#254,' XMS: ',Logical(False));
                  End;
              TextColor(Yellow);
              LDrives:=Drives;
              WriteLn(' ',#254,' Drives L¢gicos: ');
              TextColor(White);
              GoToXY(20,13);
              WriteLn(Drives);
              TextColor(Yellow);
              WriteLn(' ',#254,' Multim¡dia');
              TextColor(White);
              WriteLn(' ',#254,' Drive de CD-ROM presente: ',Logical(CDPresent));
                If (CDPresent) Then Begin
                WriteLn(' ',#254,' N£mero de drives de CR-ROM encontrado(s): ',TotalCD);
                WriteLn(' ',#254,' Primeiro drive detectado: ',UpCase(Chr(FirstCD+65)),':');
                End;
                TextColor(LightGreen);
                GoToXY(1,18);
                Write('                   ',#25,' Mais... Pressione Enter...');
                  Repeat
                    While Not KeyPressed Do Begin
                    M.GetMouseState;
                      If (M.Bt=1) And (M.X In[12..23]) Then Begin
                      TextBackGround(Green);
                      TextColor(Red);
                      Window(1,1,80,25);
                      GoToXY(12,25);
                      Write(' ',#24);
                      TextColor(Black);
                      Write(' Anterior ');
                      M.MoveCursor(80,M.Y);
                      M.MoveCursor(M.X,M.Y);
                        While M.Bt=1 Do Begin
                        M.GetMouseState;
                        End;
                      GoToXY(12,25);
                      TextBackGround(White);
                      TextColor(Red);
                      Write(' ',#24);
                      TextColor(Black);
                      Write(' Anterior ');
                      M.MoveCursor(80,M.Y);
                      M.MoveCursor(M.X,M.Y);
                      GoTo UpBIOS;
                      End
                        Else If (M.Bt=1) And (M.X In[24..54]) Then Begin
                        TextBackGround(Green);
                        TextColor(Red);
                        Window(1,1,80,25);
                        GoToXY(24,25);
                        Write(' ESC');
                        TextColor(Black);
                        Write(' Retorna ao Menu Principal ');
                        M.MoveCursor(80,M.Y);
                        M.MoveCursor(M.X,M.Y);
                          While M.Bt=1 Do Begin
                          M.GetMouseState;
                          End;
                        GoToXY(24,25);
                        TextBackGround(White);
                        TextColor(Red);
                        Write(' ESC');
                        TextColor(Black);
                        Write(' Retorna ao Menu Principal ');
                        M.MoveCursor(80,M.Y);
                        M.MoveCursor(M.X,M.Y);
                        GoTo Done;
                        End;
                    End;
                  Keyb.Inkey;
                    If (Keyb.Key=UpArrow) Then GoTo UpBIOS;
                      If (Keyb.Key=Esc) Then GoTo Done;
                  Until (Keyb.Key=Enter) Or (Keyb.Key=Esc) Or (Keyb.Key=UpArrow) Or (Keyb.Key=F1);
                  Pass:=True;
                    If (Keyb.Key=Enter) Then Begin
                    TextBackGround(Blue);
                    ClrScr;
                    M.CloseMouse;
                    Scr.SaveScreen;
                    Window(1,1,80,25);
                    TextBackGround(Black);
                    ClrScr;
                    Scr.OpenSimpleWindow(20,10,60,12,Yellow,White);
                    TextColor(Blue);
                    WriteLn('Por favor aguarde...Testando Hard Disk #1');
                    GoToXY(1,2);
                    WriteLn('Drive sendo testado:  ','C:\');
                    Keyb.DisableKeyb;
                    M.InitMouse;
                    M.MouseWindow(0,24,79,24);
                    M.MoveCursor(65,25);
                    M.SetTextCursor(Blue,Yellow);
                    HDInfo('c',HDRecord);
                    TransferRate:=DiskBenchMark('c');
                    Keyb.EnableKeyb;
                    Scr.RestoreScreen;
                    Window(1,1,80,25);
                    TextBackGround(White);
                    M.MoveCursor(66,25);
                    GoToXY(65,25);
                    Write(' ');
                    Window(28,4,75,21);
                    GoToXY(1,1);
                    TextBackGround(Blue);
                    TextColor(LightCyan);
                    WriteLn(' ',#254,' Estat¡sticas de C:\');
                    TextColor(White);
                    WriteLn;
                    WriteLn(' ',#254,' Capacidade total: ',HDRecord.Size Div 1048576,' MBytes');
                    WriteLn(' ',#254,' Espaco Livre no momento: ',HDRecord.Free Div 1048576,' MBytes');
                    WriteLn(' ',#254,' Bytes por Setor: ',HDRecord.Bytes_Per_Sector);
                    WriteLn(' ',#254,' Setores por Cluster de Alocacao: ',HDRecord.Sectors_Per_Cluster);
                    WriteLn(' ',#254,' N£mero total de Clusters: ',HDRecord.Total_Number_Clusters);
                    WriteLn(' ',#254,' Clusters Vazios: ',HDRecord.Empty_Clusters);
                    WriteLn;
                    TextColor(Yellow);
                    WriteLn(' ',#254,' Desempenho - Estimativa de Velocidade');
                    TextColor(White);
                    WriteLn(' ',#254,' Taxa de Transferencia Aproximada: ',TransferRate:0:1,' MB/S');
                    WriteLn;
                    TextColor(Yellow);
                    WriteLn(' ',#254,' Porcentagem Ocupada - Demonstrativo Gr fico');
                    Scr.StatusDiskBar(2,15,30,White,Blue,((HDRecord.Size-HDRecord.Free) Div 1048576),
                    HDRecord.Size Div 1048576);
                    End;
              End;
        End;
      End;
        Esc:Begin
        Done:
        KeybOK:=True;
        End;
          UpArrow:Begin
            Case Choice Of
              4:Begin
              UpBIOS:
              Dec(Choice);
              Window(4,7,21,11);
              TextColor(Yellow);
              TextBackGround(Blue);
              GoToXY(1,5);
              ClrEol;
              Scr.Center(20,5,'Ms-Dos');
              TextBackGround(White);
              GoToXY(1,4);
              ClrEol;
              Scr.Center(20,4,'BIOS');
              Window(28,4,75,21);
              TextBackGround(Blue);
              ClrScr;
              {Call BIOS Procedure}
              GetBiosDate(BiosDate);
              M.GetMouseInfo;
              TextColor(LightCyan);
              Write(' ',#254,' BIOS - Informacoes Gerais');
              WriteLn;
              TextColor(White);
              WriteLn;
              WriteLn(' ',#254,' Data do BIOS detectada: ',BIOSDate);
              WriteLn(' ',#254,' Mouse presente: ',Logical(M.MouseFound));
                If (M.MouseFound) Then Begin
                WriteLn(' ',#254,' N£mero de botoes: ',M.Buttons);
                WriteLn(' ',#254,' Tipo do Mouse: ',M.MouseInfo.MouseType);
                WriteLn(' ',#254,' Versao do Driver: ',M.MouseInfo.DriverLo,'.',M.MouseInfo.DriverHi);
                WriteLn(' ',#254,' Trabalhando com IRQ: ',M.MouseInfo.IRQ);
                End;
              Scr.DetectVideo;
                If (Scr.VideoCard=None) Then Begin
                WriteLn(' ',#254,' Placa de V¡deo: Nenhuma');
                End
                  Else Begin
                    Case Scr.VideoCard Of
                    Mono:WriteLn(' ',#254,' Placa de V¡deo: Monocrom tica');
                    Cga:WriteLn(' ',#254,' Placa de V¡deo: CGA');
                    EgaMono:WriteLn(' ',#254,' Placa de V¡deo: EGAMono');
                    EgaColor:WriteLn(' ',#254,' Placa de V¡deo: EGAColor');
                    VgaMono:WriteLn(' ',#254,' Placa de V¡deo: VGAMono');
                    VgaColor:WriteLn(' ',#254,' Placa de V¡deo: VGAColor');
                    McgaMono:WriteLn(' ',#254,' Placa de V¡deo: MCGAMono');
                    McgaColor:WriteLn(' ',#254,' Placa de V¡deo: MCGAColor');
                    End;
                  End;
              SVGA(Found,Man,VersionLo,VersionHi);
                If Found Then Begin
                WriteLn(' ',#254,' Placa de V¡deo SVGA (VESA): ',Logical(Found));
                WriteLn(' ',#254,' Fabricante: ',Man);
                WriteLn(' ',#254,' Versao: ',VersionLo,'.',VersionHi);
                End
                  Else Begin
                  WriteLn(' ',#254,' Placa de V¡deo SVGA (VESA): Nao');
                  End;
                WriteLn(' ',#254,' Mem¢ria de Apresentacao no Segmento: ',Word2Hex(VidSeg),'h');
                 If (CheckForWin=NoWin) Then Begin
                 WriteLn(' ',#254,' Windows in BackGround: Nao, modo REAL');
                 End
                   Else Begin
                   WriteLn(' ',#254,' Windows in BackGround: Sim');
                     Case CheckForWin Of
                     RealStd:WriteLn(' ',#254,' Modo Operacional: Standard');
                     Enhanced:WriteLn(' ',#254,' Modo Operacional: Enhanced');
                     End;
                   End;
              End;
                3:Begin
                UpCMOS:
                Dec(Choice);
                Window(4,7,21,11);
                TextColor(Yellow);
                TextBackGround(Blue);
                GoToXY(1,4);
                ClrEol;
                Scr.Center(20,4,'BIOS');
                TextBackGround(White);
                GoToXY(1,3);
                ClrEol;
                Scr.Center(20,3,'CMOS');
                Window(28,4,75,21);
                TextBackGround(Blue);
                ClrScr;
                {Call CMOS Procedure}
                GetCMOS(CMOSInfo);
                TextColor(LightCyan);
                Write(' ',#254,' CMOS - Informacoes Gerais');
                WriteLn;
                TextColor(White);
                WriteLn;
                  With CMOSInfo Do Begin
                    If Found Then Begin
                    WriteLn(' ',#254,' CMOS presente: ',Logical(Found));
                    WriteLn(' ',#254,' Video Detectado: ',VideoType);
                    WriteLn(' ',#254,' Coprocessador Num‚rico presente: ',Logical(Coproc));
                      If (FloppyA='None') Then Begin
                      WriteLn(' ',#254,' Drive de Disquete A: ','Nenhum');
                      End
                        Else Begin
                        WriteLn(' ',#254,' Drive de Disquete A: ',FloppyA);
                        End;
                      If (FloppyB='None') Then Begin
                      WriteLn(' ',#254,' Drive de Disquete B: ','Nenhum');
                      End
                        Else Begin
                        WriteLn(' ',#254,' Drive de Disquete B: ',FloppyB);
                        End;
                      If (Hard0=255) Then Begin
                      WriteLn(' ',#254,' Identificacao do Disco R¡gido #1: ','Nenhuma N/A');
                      End
                        Else Begin
                        WriteLn(' ',#254,' Identificacao do Disco R¡gido #1: ',Hard0);
                        End;
                      If (Hard1=255) Then Begin
                      WriteLn(' ',#254,' Identificacao do Disco R¡gido #2: ','Nenhuma N/A');
                      End
                        Else Begin
                        WriteLn(' ',#254,' Identificacao do Disco R¡gido #2: ',Hard1);
                        End;
                    GoToXY(1,10);
                    WriteLn(' ',#254,' Mem¢ria Convencional: ',ConvenRAM,'Kb');
                    WriteLn(' ',#254,' Mem¢ria Estendida: ',ExtendRAM,'Kb');
                    WriteLn(' ',#254,' CMOS CheckSum v lido: ',Logical(CheckSum));
                    WriteLn(' ',#254,' Configurado Corretamente: ',Logical(CheckSum));
                    End
                      Else Begin
                      WriteLn(' ',#254,' CMOS presente: Nao encontrado');
                      End;
                  End;
                End;
                  2:Begin
                  Inf:
                  Dec(Choice);
                  Window(4,7,21,11);
                  TextColor(Yellow);
                  TextBackGround(Blue);
                  GoToXY(1,3);
                  ClrEol;
                  Scr.Center(20,3,'CMOS');
                  TextBackGround(White);
                  GoToXY(1,2);
                  ClrEol;
                  Scr.Center(20,2,'Inform. Gerais');
                  Window(28,4,75,21);
                  TextBackGround(Blue);
                  ClrScr;
                  TextColor(LightCyan);
                  WriteLn(' ',#254,' Informacoes Gerais - Equipamento Detectado');
                  TextColor(White);
                  WriteLn;
                  WriteLn(' ',#254,' Processador Central: ',CPUType);
                  WriteLn(' ',#254,' N£mero de Portas Paralelas: ',Equip.ParPorts);
                  WriteLn(' ',#254,' N£mero de Portas Seriais (RS-232): ',Equip.SerialPorts);
                  WriteLn(' ',#254,' N£mero de Drives para Discos Flex¡veis: ',Equip.FloppyNumber);
                  WriteLn(' ',#254,' ID:',MachineID);
                  GoToXY(1,8);
                  WriteLn(' ',#254,' N£mero de Discos R¡gidos (HD): ',FixedDisks);
                  WriteLn(' ',#254,' Boot Drive: ',UpCase(Char(GetBootDrive+64)));
                  WriteLn(' ',#254,' Coprocessador Matem tico: ',Logical(CoProcessor));
                  WriteLn(' ',#254,' Joystick/Adaptador de Jogos: ',Logical(GameAdapter));
                  WriteLn(' ',#254,' Adaptador de v¡deo PCI: ',Logical(PCIPresent));
                  WriteLn(' ',#254,' Mem¢ria Estendida: ',Logical(EMS));
                    If Not EMS Then Begin
                    WriteLn(' ',#254,' Mem¢ria Expandida: ',Logical(False));
                    End
                      Else Begin
                      WriteLn(' ',#254,' Mem¢ria Expandida: ',Logical(IsXMS));
                      End;
                  WriteLn(' ',#254,' Mem¢ria Convencional (em Kb): ',BaseRAM);
                  WriteLn(' ',#254,' Mem¢ria F¡sica (em Kb): ',ExtRAM);
                  WriteLn(' ',#254,' Total de Mem¢ria (em Kb): ',(ExtRAM+BaseRAM));
                  End;
            End;
          End;
            F1:Begin
            StartHelp:
              If Not FileExists('InfG.Ehf') Then Begin
              Scr.DosReturn;
              Scr.BackAscii(#177,Blue,LightGray);
              MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
              GoTo Redraw;
              End;
            Assign(HlpFile,'InfG.Ehf');
            EvaluateCRC(HlpFile,CRC);
            LongToHex(CRC,CRCStr);
              If (CRCStr<>'C127D755') Then Begin
              Scr.DosReturn;
              Scr.BackAscii(#177,Blue,LightGray);
              MessageBox(22,9,58,16,'Aviso',
              'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
              GoTo Redraw;
              End;
            {Call Help Routine}
            HelpScroll('InfG.Ehf');
            GoTo ReDraw;
            End;
    End;
  Until (MOK) Or (KeybOK);
End;

Procedure DoHeader(Const SourcePath:String;Const Method:Byte;Const Password:Str20;Var Error:Boolean);
Var Extension:Str3;
    i,PointPos:Byte;
    CRC:LongInt;
    CRCStr:String8;
Const Signature:String[8]='$LCK300$';
      Ext:String[4]='.ENC';
Label Continue;
Begin
Error:=False;
Extension:='';
DestPath:='';
PointPos:=0;
  For i:=Length(SourcePath) DownTo 1 Do Begin
    If (SourcePath[i]='.') Then Begin
    PointPos:=i;
    GoTo Continue;
    End;
  End;
Continue: {Get the original extension}
Extension:=Copy(SourcePath,PointPos+1,(Length(SourcePath)-PointPos+1));
  If PointPos=0 Then Extension:='';
DestPath:=SourcePath;
  If PointPos<>0 Then Begin
  Delete(DestPath,PointPos,4);
  End;
DestPath:=DestPath+Ext;
Assign(DestFile,DestPath);
{$I-}
ReWrite(DestFile,1);
{$I+}
  If (IOResult<>0) Then Begin
  Error:=True;
  Exit;
  End;
Reset(DestFile,1);
  For i:=1 To 8 Do Begin
  BlockWrite(DestFile,Signature[i],1); {Write Signatute to DestFile}
  End;
i:=Method XOr KeyValue;
BlockWrite(DestFile,i,1); {Write the cryptation method to file}
  For i:=1 To Length(Extension) Do Begin
  Extension[i]:=Chr(Ord(Extension[i]) XOr KeyValue);
  BlockWrite(DestFile,Extension[i],1); {Write Extension to Header}
  End;
GenerateSeeds(Password,Seed1,Seed2);
BlockWrite(DestFile,Seed1,2);
BlockWrite(DestFile,Seed2,2); {Write Seeds - 2Bytes (Word)}
Assign(SourceFile,SourcePath);
EvaluateCRC(SourceFile,CRC);
LongToHex(CRC,CRCStr);
  For i:=1 To 8 Do Begin
  BlockWrite(DestFile,CRCStr[i],1); {Write the original CRC}
  End;
Close(DestFile);
{Total Header Size = 24 Bytes}
End;

Procedure ExpandHeader(Var EncFile:File;Var Header:HeaderInfo;Var Error:Byte);
Var Cont:Byte;
Begin
Error:=0; {0=No Error}
{$I-}
Reset(EncFile,1);
{$I+}
  If IOResult<>0 Then Begin
  Error:=1; {Error while opening file}
  Exit;
  End;
    If (FileSize(EncFile)<25) Then Begin
    Error:=2; {File not encrypted}
    Exit;
    End;
  For Cont:=1 To 8 Do Begin
  BlockRead(EncFile,Header.Signature[Cont],1); {Read Signature}
  End;
Header.Signature[0]:=Chr(8);
BlockRead(EncFile,Header.Method,1); {Read Encrypt Method}
Header.Method:=(Header.Method XOr KeyValue);
  For Cont:=1 To 3 Do Begin
  BlockRead(EncFile,Header.Extension[Cont],1); {Read Extension}
  Header.Extension[Cont]:=Chr(Ord(Header.Extension[Cont]) XOr KeyValue);
  End;
Header.Extension[0]:=Chr(3);
BlockRead(EncFile,Header.Seed1,2); {Read Seeds and CRC file}
BlockRead(EncFile,Header.Seed2,2);
  For Cont:=1 To 8 Do Begin
  BlockRead(EncFile,Header.CRC[Cont],1);
  End;
Header.CRC[0]:=Chr(8);
{Do not close the file}
End;

Procedure KillFile(Var Source:File);
{Wipe info from disk}
Var BytesLeft:Real;
    Buff:Buffer;
Begin
Reset(Source,1);
BytesLeft:=FileSize(Source);
ReWrite(Source,1);
  If (MaxAvail<4096) Then Exit;
New(Buff);
FillChar(Buff^,SizeOf(Buff^),1);
  While BytesLeft>0 Do Begin
    If (BytesLeft>4096) Then Begin
    BlockWrite(Source,Buff^,SizeOf(Buff^));
    End
      Else Begin
      BlockWrite(Source,Buff^,Trunc(BytesLeft));
      End;
  BytesLeft:=BytesLeft-4096;
  End;
Dispose(Buff);
Close(Source);
Erase(Source);
End;

Procedure ReduceStr(Const Source:String;Var Dest:Str28);
Var i,Cont:Byte;
    Temp:String[12];
Begin
Dest:='';
  For i:=Length(Source) DownTo 1 Do Begin
    If (Source[i]='\') Then Begin
    Dest:=Copy(Source,i,Length(Source)-i+1);
    Insert('...',Dest,1);
    Break;
    End;
  End;
Cont:=0;
    For i:=1 To Length(Source) Do Begin
      If (Source[i]='\') Then Begin
        If (Cont=0) Then Begin
        Inc(Cont);
        End
         Else Begin
         Temp:=Copy(Source,1,i);
         Temp[0]:=Chr(i);
         Insert(Temp,Dest,1);
         Break;
         End;
      End;
    End;
End;

Procedure EncryptFile(Var SourceFile,DestFile:File;Const Method:Byte);
Var Tmp1,Tmp2:File;
    Temp:Str28;
    SigStr:String[8];
    Size:Real;
    S:Status;
    Cont:Byte;
Begin
Window(1,1,80,25);
Scr.BackASCII(#176,Blue,LightGray);
TextBackGround(Blue);
ClrEol;
TextColor(Yellow);
Scr.Center(79,1,'Criptografando Arquivo');
GoToXY(1,25);
TextBackGround(White);
ClrEol;
TextColor(Blue);
Write(' Encryptor V3.0');
Scr.ShadedWindow(8,4,72,22,White,Blue);
GoToXY(1,1);
TextColor(Yellow);
Write(' ',#254,'  O programa agora est  codificando o seu arquivo. Por favor');
GoToXY(1,2);
Write('aguarde pois isto pode levar algum tempo.');
GoToXY(1,4);
WriteLn(' ',#254,' M‚todo Utilizado: #',Method);
  If Length(SourcePath)>35 Then Begin
  ReduceStr(SourcePath,Temp);
  WriteLn(' ',#254,' Arquivo Original: ',Temp);
  End
    Else Begin
    WriteLn(' ',#254,' Arquivo Original: ',SourcePath);
    End;
  If Length(DestPath)>35 Then Begin
  ReduceStr(DestPath,Temp);
  WriteLn(' ',#254,' Arquivo Criptografado: ',Temp);
  End
    Else Begin
    WriteLn(' ',#254,' Arquivo Criptografado: ',DestPath);
    End;
GoToXY(1,8);
Write(' ',#254,' Status:');
  With S Do Begin
  S.X:=2;
  S.Y:=10;
  S.Len:=40;
  S.Color:=Yellow;
  S.Back:=Blue;
  End;
Reset(DestFile,1); {RESET file must EXIST-Call DoHeader}
Reset(SourceFile,1);
Size:=FileSize(SourceFile); {Test for Disk Space!!!}
  If (DiskFree(0)<=(Size*2)) Then Begin
  Scr.DosReturn;
  Scr.BackAscii(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao h  espaco suficiente em disco  para executar esta operacao.');
  Exit;
  End;
    If (Size>8) Then Begin
    Reset(SourceFile,1);
        For Cont:=1 To 8 Do Begin
        BlockRead(SourceFile,SigStr[Cont],1);
        End;
      SigStr[0]:=Chr(8);
      If (SigStr='$LCK300$') Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,'Erro',
      'Este arquivo j  encontra-se protegido!');
      Exit;
      End;
    End
      Else If (Size=0) Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,'Erro',
      'Arquivo vazio!');
      Exit;
      End;
  Case Method Of
    3:Begin
    S.Tot:=(Size*3);
    {Borland Enc}
    Assign(Tmp1,'Tmp1.$$$');
    ReWrite(Tmp1,1);
    Encrypt(SourceFile,Tmp1,(Seed1*Seed2),S);
    KillFile(SourceFile);
    {O'Brien Enc}
    Assign(Tmp2,'Tmp2.$$$');
    ReWrite(Tmp2,1);
    Encode(Tmp1,Tmp2,Seed1,Seed2,S,Size);
    KillFile(Tmp1);
    {XOr Enc}
    XOrEncode(Tmp2,DestFile,(Seed1+Seed2),S,Size,True);
    KillFile(Tmp2);
    End;
      2:Begin
      S.Tot:=(Size*2);
      {Borland Enc}
      Assign(Tmp1,'Tmp1.$$$');
      ReWrite(Tmp1,1);
      Encrypt(SourceFile,Tmp1,(Seed1*Seed2),S);
      {O'Brien Enc}
      KillFile(SourceFile);
      Encode(Tmp1,DestFile,Seed1,Seed2,S,Size);
      KillFile(Tmp1);
      End;
        1:Begin
        S.Tot:=(Size);
        {Borland Enc}
        Encrypt(SourceFile,DestFile,(Seed1*Seed2),S);
        KillFile(SourceFile);
        End;
  End;
TextColor(White);
GoToXY(1,12);
Write(' ',#254,' Criptografia conclu¡da com ˆxito.');
TextColor(LightGreen);
Keyb.ClearKbdBuf;
Scr.ScrollTextLine(11,53,16,'Pressione qualquer tecla para continuar...');
Keyb.ClearKbdBuf;
End;

Procedure DecryptFile(Var SourceFile,DestFile:File;Const Method:Byte);
Var Tmp1,Tmp2:File;
    Temp:Str28;
    SigStr:String[8];
    Size:Real;
    S:Status;
    Cont:Byte;
    CRCFile:String8;
    CRCValue:LongInt;
Begin
Window(1,1,80,25);
Scr.BackASCII(#176,Blue,LightGray);
TextBackGround(Blue);
ClrEol;
TextColor(Yellow);
Scr.Center(79,1,'Decodificando Arquivo');
GoToXY(1,25);
TextBackGround(White);
ClrEol;
TextColor(Blue);
Write(' Encryptor V3.0');
Scr.ShadedWindow(8,4,72,22,White,Blue);
GoToXY(1,1);
TextColor(Yellow);
Write(' ',#254,' O programa agora est  Decodificando o seu arquivo. Por favor');
GoToXY(1,2);
Write('aguarde pois isto pode levar algum tempo.');
GoToXY(1,4);
WriteLn(' ',#254,' M‚todo Utilizado: #',Method);
  If Length(SourcePath)>35 Then Begin
  ReduceStr(SourcePath,Temp);
  WriteLn(' ',#254,' Arquivo Criptografado: ',Temp);
  End
    Else Begin
    WriteLn(' ',#254,' Arquivo Criptografado: ',SourcePath);
    End;
  If Length(DestPath)>35 Then Begin
  ReduceStr(DestPath,Temp);
  WriteLn(' ',#254,' Arquivo Original: ',Temp);
  End
    Else Begin
    WriteLn(' ',#254,' Arquivo Original: ',DestPath);
    End;
GoToXY(1,8);
Write(' ',#254,' Status:');
  With S Do Begin
  S.X:=2;
  S.Y:=10;
  S.Len:=40;
  S.Color:=Yellow;
  S.Back:=Blue;
  End;
Size:=FileSize(SourceFile); {Test for Disk Space!!!}
Size:=Size-24;
  If (DiskFree(0)<=(Size*2)+24) Then Begin
  Scr.DosReturn;
  Scr.BackAscii(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao h  espaco suficiente em disco  para executar esta operacao.');
  Exit;
  End;
    Case Method Of
    3:Begin
    S.Tot:=(Size*3);
    {XOr Decrypt}
    Assign(Tmp1,'Tmp1.$$$');
    ReWrite(Tmp1,1);
    XOrEncode(SourceFile,Tmp1,(Header.Seed1+Header.Seed2),S,0,False);
    KillFile(SourceFile);
    {O'Brien Dec}
    Assign(Tmp2,'Tmp2.$$$');
    ReWrite(Tmp2,1);
    Decode(Tmp1,Tmp2,Header.Seed1,Header.Seed2,S,Size,False);
    KillFile(Tmp1);
    {Borland Dec}
    Decrypt(Tmp2,DestFile,(Header.Seed1*Header.Seed2),S,Size,False);
    KillFile(Tmp2);
    End;
      2:Begin
      S.Tot:=(Size*2);
      {O'Brien Dec}
      Assign(Tmp1,'Tmp1.$$$');
      ReWrite(Tmp1,1);
      Decode(SourceFile,Tmp1,Header.Seed1,Header.Seed2,S,0,True);
      KillFile(SourceFile);
      {Borland Dec}
      Decrypt(Tmp1,DestFile,(Header.Seed1*Header.Seed2),S,(Size/2),False);
      KillFile(Tmp1);
      End;
        1:Begin
        S.Tot:=(Size);
        {Borland Dec}
        Decrypt(SourceFile,DestFile,(Header.Seed1*Header.Seed2),S,0,True);
        KillFile(SourceFile);
        End;
    End;
TextColor(White);
EvaluateCRC(DestFile,CRCValue);
LongToHex(CRCValue,CRCFile);
  If (CRCFile=Header.CRC) Then Begin
  GoToXY(1,12);
  Write(' ',#254,' CRC Check: OK');
  End
    Else Begin
    GoToXY(1,12);
    Write(' ',#254,' CRC Check: Erro');
    Scr.SaveScreen;
    MessageBox(13,7,68,17,'Atencao',
'O teste de CRC do seu arquivo falhou.Existe uma grandeprobabilidade de que ele esteja corrompido.Restaure-o desuas c¢pias.');
    Scr.RestoreScreen;
    End;
GoToXY(1,14);
Write(' ',#254,' Decodificacao conclu¡da com ˆxito.');
TextColor(LightGreen);
Keyb.ClearKbdBuf;
Scr.ScrollTextLine(11,53,16,'Pressione qualquer tecla para continuar...');
Keyb.ClearKbdBuf;
End;

Procedure Explorer(Var ArqPath:String);

Type FileInfo=Record
     Name:String[12];
     Dir:Boolean;
     End;
     FullDir=Array [1..2000] Of FileInfo; {28000 Bytes}
     DiskBuf=^FullDir;

Var InitPath:String;
    Dir:DiskBuf;
    Cont,i,MaxPages,Temp:Word;
    F:SearchRec;
    RStr:Str28;

    Procedure SetupDir(Var Dir:DiskBuf);
    Var Cont:Word;
    Begin
      For Cont:=1 To 800 Do Begin
        With Dir^[Cont] Do Begin
        Name:='';
        Dir:=False;
        End;
      End;
    End;

    Procedure LoadDir; {Load the current directory}
    Var CPath:String;
    Begin
    Cont:=1;
    FindFirst('*.*',Archive+Directory,F);
    GetDir(0,CPath);
    {$I-}
    ChDir(F.Name);
    {$I+}
    If (IOResult=0) Then Begin
      With Dir^[Cont] Do Begin
      Name:=F.Name;
      Dir:=True;
      End;
    ChDir(CPath);
    End
      Else Begin
        With Dir^[Cont] Do Begin
        Name:=F.Name;
        Dir:=False;
        End;
      End;
        While (DOSError=0) And (Cont<2000) Do Begin
        FindNext(F);
          If DOSError=18 Then Begin
          Exit;
          End
            Else Begin
            Inc(Cont);
            End;
        {$I-}
        Chdir(F.Name);
        {$I+}
          If (IOResult=0) Then Begin
            With Dir^[Cont] Do Begin
            Name:=F.Name;
            Dir:=True;
            End;
          Chdir(CPath);
          End
            Else Begin
              With Dir^[Cont] Do Begin
              Name:=F.Name;
              Dir:=False;
              End;
            End;
        End;
    End;

    Procedure DoTable(Const Page:Byte);  {Zero is the FIRST!!!}
    Var i,j:Byte;
        Temp:Word;
    Begin
    Window(2,5,79,23);
    TextColor(LightCyan);
    TextBackGround(Blue);
    ClrScr;
    i:=14;
      While (i<78) Do Begin
        For j:=1 To 18 Do Begin
        GoToXY(i,j);
        Write('³');
        End;
      Inc(i,13);
      End;
    Temp:=108*Page;
    Inc(Temp);
      For j:=0 To 5 Do Begin
        For i:=1 To 18 Do Begin
          If (Temp<=Cont) Then Begin
          GoToXY((j*13)+2,i);
          Write(Dir^[Temp].Name);
          Inc(Temp);
          End
            Else Begin
            Exit;
            End;
        End;
      End;
    End;

    Procedure ChangeDir;Forward;

    Procedure RunTable;
    Var i,j,Page:Byte;
        Pont:Word;
        CDir:String;
    Label GoNow;
    Begin
    GoNow:
    GetDir(0,CDir);
    Page:=0;
    Window(1,1,80,25);
    TextBackGround(Blue);
    ClrScr;
    Scr.OpenWindow(2,2,79,23,LightCyan,Blue); {78 Characters/Line}
    Window(1,1,80,24);
    GoToXY(1,4);
    Write('ÌÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹');
    Window(2,2,79,3);
    TextColor(Yellow);
    Scr.Center(77,1,'Gerenciador de Arquivos');
    TextColor(LightCyan);
    GoToXY(1,2);
    Write('Diret¢rio Atual: ');
    TextColor(White);
      If (Length(CDir)>59) Then Begin
      ReduceStr(CDir,RStr);
      Write(RStr);
      End
        Else Begin
        Write(CDir);
        End;
    Window(1,1,80,25);
    GoToXY(1,25);
    TextBackGround(White);
    TextColor(Red);
    Write(' ',#24,',',#25);
    TextColor(Black);
    Write(' Movimento  ');
    TextColor(Red);
    Write('PgUp/PgDn ');
    TextColor(Black);
    Write('Mais Arquivos  ');
    TextColor(Red);
    Write('F1 ');
    TextColor(Black);
    Write('Ajuda  ');
    TextColor(Red);
    Write('F2 ');
    TextColor(Black);
    Write('Trocar de Drive');
    ClrEol;
    Window(2,5,79,23);
    TextColor(Yellow);
    TextBackGround(Blue);
    ClrScr;
    DoTable(Page);
    Window(2,5,79,23);
    TextColor(White);
    TextBackGround(White);
    Pont:=108*Page;
    Inc(Pont);
    j:=0;
    GoToXY((j*13)+2,1);
    Write('            ');
    GoToXY((j*13)+2,1);
    Write(Dir^[Pont].Name);
      Repeat
      Keyb.Inkey;
        Case Keyb.Key Of
         DownArrow:Begin
           If (WhereY<18) And (Pont<Cont) Then Begin
           GoToXY((j*13)+2,WhereY);
           TextColor(LightCyan);
           TextBackGround(Blue);
           Write('            ');
             If (j=5) Then Begin
             GoToXY((j*13)+2,WhereY-1);
             End
               Else Begin
               GoToXY((j*13)+2,WhereY);
               End;
           Write(Dir^[Pont].Name);
             If (j=5) And (Length(Dir^[Pont].Name)=12) Then Begin
             GoToXY(WhereX,WhereY-1);
             End;
           Inc(Pont);
           GoToXY((j*13)+2,WhereY+1);
           TextColor(White);
           TextBackGround(White);
           Write('            ');
             If (j=5) Then Begin
             GoToXY((j*13)+2,WhereY-1);
             End
               Else Begin
               GoToXY((j*13)+2,WhereY);
               End;
           Write(Dir^[Pont].Name);
             If (j=5) And (Length(Dir^[Pont].Name)=12) Then Begin
             GoToXY(WhereX,WhereY-1);
             End;
           End
             Else If (WhereY=18) And (Pont<Cont) And (j<>5) Then Begin
             GoToXY((j*13)+2,WhereY);
             TextColor(LightCyan);
             TextBackGround(Blue);
             Write('            ');
             GoToXY((j*13)+2,WhereY);
             Write(Dir^[Pont].Name);
             Inc(Pont);
             Inc(j);
             GoToXY((j*13)+2,1);
             TextColor(White);
             TextBackGround(White);
             Write('            ');
               If (j=5) Then Begin
               GoToXY((j*13)+2,WhereY-1);
               End
                 Else Begin
                 GoToXY((j*13)+2,WhereY);
                 End;
             Write(Dir^[Pont].Name);
               If (j=5) And (Length(Dir^[Pont].Name)=12) Then GoToXY((j*13)+1,WhereY-1);
             End;
         End; {DownArrow}
           UpArrow:Begin
             If (WhereY>1) Then Begin
             GoToXY((j*13)+2,WhereY);
             TextColor(LightCyan);
             TextBackGround(Blue);
             Write('            ');
               If (j=5) Then GoToXY((j*13)+2,WhereY-1);
             GoToXY((j*13)+2,WhereY);
             Write(Dir^[Pont].Name);
               If (j=5) And (Length(Dir^[Pont].Name)=12) Then GoToXY((j*13)+2,WhereY-1);
             Dec(Pont);
             GoToXY((j*13)+2,WhereY-1);
             TextColor(White);
             TextBackGround(White);
             Write('            ');
               If (j=5) Then GoToXY((j*13)+2,WhereY-1);
             GoToXY((j*13)+2,WhereY);
             Write(Dir^[Pont].Name);
               If (j=5) And (Length(Dir^[Pont].Name)=12) Then GoToXY((j*13)+2,WhereY-1);
             End
               Else If (WhereY=1) And (Pont<>1) And (j<>0) Then Begin
               GoToXY((j*13)+2,WhereY);
               TextColor(LightCyan);
               TextBackGround(Blue);
               Write('            ');
                 If (j=5) Then GoToXY((j*13)+2,WhereY-1);
               GoToXY((j*13)+2,WhereY);
               Write(Dir^[Pont].Name);
               Dec(Pont);
               Dec(j);
               GoToXY((j*13)+2,18);
               TextColor(White);
               TextBackGround(White);
               Write('            ');
               GoToXY((j*13)+2,WhereY);
               Write(Dir^[Pont].Name);
               End;
           End; {UpArrow}
             Enter:Begin
               If Dir^[Pont].Dir Then Begin
               ChDir(Dir^[Pont].Name);
               CDir:='';
               GetDir(0,CDir);
               Window(2,2,79,3);
               TextColor(LightCyan);
               TextBackGround(Blue);
               GoToXY(1,2);
               ClrEol;
               Write('Diret¢rio Atual: ');
               TextColor(White);
                 If (Length(CDir)>59) Then Begin
                 ReduceStr(CDir,RStr);
                 Write(RStr);
                 End
                   Else Begin
                   Write(CDir);
                   End;
               Window(2,5,79,23);
               TextColor(Yellow);
               TextBackGround(Blue);
               ClrScr;
               Scr.Center(77,10,'Por favor aguarde...Carregando...');
               LoadDir;
               Page:=0;
               DoTable(Page);
               Window(2,5,79,23);
               TextColor(White);
               TextBackGround(White);
               Pont:=108*Page;
               Inc(Pont);
               j:=0;
               GoToXY((j*13)+2,1);
               Write('            ');
               GoToXY((j*13)+2,1);
               Write(Dir^[Pont].Name);
               End
                 Else Begin
                 ArqPath:='';
                 ArqPath:=CDir+'\'+Dir^[Pont].Name;
                   If (Pos('\\',ArqPath)<>0) Then Begin
                   Delete(ArqPath,Pos('\\',ArqPath),1);
                   End;
                 Dispose(Dir);
                 ChDir(InitPath);
                 Exit;
                 End;
             End; {Enter}
               PgDn:Begin
               Temp:=Cont Mod 108;
                 If Temp>0 Then Begin
                 MaxPages:=(Cont Div 108)+1;
                 End
                   Else Begin
                   MaxPages:=(Cont Div 108);
                   End;
                 If Page<(MaxPages-1) Then Begin
                 Inc(Page);
                 DoTable(Page);
                 Window(2,5,79,23);
                 TextColor(White);
                 TextBackGround(White);
                 Pont:=108*Page;
                 Inc(Pont);
                 j:=0;
                 GoToXY((j*13)+2,1);
                 Write('            ');
                 GoToXY((j*13)+2,1);
                 Write(Dir^[Pont].Name);
                 End;
               End; {PgDn}
                 PgUp:Begin
                   If Page>0 Then Begin
                   Dec(Page);
                   DoTable(Page);
                   Window(2,5,79,23);
                   TextColor(White);
                   TextBackGround(White);
                   Pont:=108*Page;
                   Inc(Pont);
                   j:=0;
                   GoToXY((j*13)+2,1);
                   Write('            ');
                   GoToXY((j*13)+2,1);
                   Write(Dir^[Pont].Name);
                   End;
                 End; {PgUp}
                   F2:Begin
                   ChangeDir;
                   Window(1,1,80,25);
                   TextBackGround(Blue);
                   ClrScr;
                   Scr.OpenWindow(2,2,79,23,LightCyan,Blue); {78 Characters/Line}
                   Window(1,1,80,24);
                   GoToXY(1,4);
                   Write('ÌÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹');
                   Window(2,2,79,3);
                   TextColor(Yellow);
                   Scr.Center(77,1,'Gerenciador de Arquivos');
                   TextColor(LightCyan);
                   GoToXY(1,2);
                   Write('Diret¢rio Atual: ');
                   TextColor(White);
                   Write(InitPath);
                   Window(1,1,80,25);
                   GoToXY(1,25);
                   TextBackGround(White);
                   TextColor(Red);
                   Write(' ',#24,',',#25);
                   TextColor(Black);
                   Write(' Movimento  ');
                   TextColor(Red);
                   Write('PgUp/PgDn ');
                   TextColor(Black);
                   Write('Mais Arquivos  ');
                   TextColor(Red);
                   Write('F1 ');
                   TextColor(Black);
                   Write('Ajuda  ');
                   TextColor(Red);
                   Write('F2 ');
                   TextColor(Black);
                   Write('Trocar de Drive');
                   ClrEol;
                   Window(2,5,79,23);
                   TextColor(Yellow);
                   TextBackGround(Blue);
                   ClrScr;
                   Scr.Center(77,10,'Por favor aguarde...Carregando...');
                   LoadDir;
                   Scr.CursorSize:=Small;
                   Scr.Cursor;
                   GoTo GoNow;
                   End; {F2}
                     F1:Begin
                       If Not FileExists(InitPath+'\Hlp3.Ehf') Then Begin
                       Scr.DosReturn;
                       Scr.BackAscii(#177,Blue,LightGray);
                       MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
                       GoTo GoNow;
                       End;
                     Assign(HlpFile,InitPath+'\Hlp3.Ehf');
                     EvaluateCRC(HlpFile,CRC);
                     LongToHex(CRC,CRCStr);
                       If (CRCStr<>'D1F534CB') Then Begin
                       Scr.DosReturn;
                       Scr.BackAscii(#177,Blue,LightGray);
                       MessageBox(22,9,58,16,'Erro',
                       'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
                       GoTo GoNow;
                       End;
                     {Call Help Routine}
                     HelpScroll(InitPath+'\Hlp3.Ehf');
                     GoTo GoNow;
                     End;
        End;
      Until (Keyb.Key=Esc);
    ChDir(InitPath);
    Dispose(Dir);
    End;

    Procedure ChangeDir;
    Var Box1:FixedDataBox;
    Drive,DriveReady:Boolean;
    Status:Str12;
    CMOSInfo:CMOSRec;
    Label DoAgain,ReadAgain,Continue;
    Begin
    DoAgain:
    Window(1,1,80,25);
    GoToXY(1,1);
    Scr.BackASCII(#178,LightGray,Green);
    GoToXY(1,1);
    TextBackGround(Blue);
    ClrEol;
    Scr.Center(79,1,'Alterar Drive');
    TextBackGround(White);
    GotoXY(1,25);
    ClrEol;
    TextColor(Red);
    Write(' Enter ');
    TextColor(Black);
    Write('Confirma novo drive  ');
    TextColor(Red);
    Write('Esc ');
    TextColor(Black);
    Write('Cancela e retorna ao Explorer  ');
    TextColor(Red);
    Write('F1 ');
    TextColor(Black);
    Write('Ajuda');
    Scr.TitleShadedWindow(10,5,70,18,White,Blue,'Escolha um novo Drive');
    Window(11,6,69,17);
    GoToXY(3,2);
    TextColor(Yellow);
    Write(
    ' Na caixa de di logo abaixo, digite o drive para onde de-seja mover-se. Pressione <Enter> para confirmar ou <Esc>');
    Write(' para sair.');
    GoToXY(4,5);
    TextColor(White);
    Write(#254,' Drives v lidos: ');
    TextColor(LightGreen);
    Write(Drives);
    TextColor(White);
    GoToXY(4,8);
    Write(#254,' Novo Drive: ');
      With Box1 Do Begin
      Init;
      X1:=19;
      Y1:=8;
      X2:=19;
      BoxColor:=Black;
      BoxTextColor:=LightGreen;
      DataType:=TextOnly;
      UseMouse:=False;
      ByPassKeys[1]:=F1;
      End;
    Scr.CursorSize:=Normal;
    Scr.Cursor;
    ReadAgain:
    Box1.OpenDataBox;
      If (Box1.ExitMode=ByPassed) Then Begin
        If Not FileExists(InitPath+'\Hlp6.Ehf') Then Begin
        Scr.DosReturn;
        Scr.BackAscii(#177,Blue,LightGray);
        MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
        GoTo DoAgain;
        End;
      Assign(HlpFile,InitPath+'\Hlp6.Ehf');
      EvaluateCRC(HlpFile,CRC);
      LongToHex(CRC,CRCStr);
        If (CRCStr<>'4F06B011') Then Begin
        Scr.DosReturn;
        Scr.BackAscii(#177,Blue,LightGray);
        MessageBox(22,9,58,16,'Erro',
        'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
        GoTo DoAgain;
        End;
      {Call Help Routine}
      HelpScroll(InitPath+'\Hlp6.Ehf');
      GoTo DoAgain;
      End;
        If (Box1.ExitMode=NormalExit) Or (Box1.ExitMode=TabExit) Then Begin
        Drive:=DriveValid(UpCase(Box1.BoxText[1]));
          If Not Drive Then Begin {Drive is not valid}
          Scr.SaveScreen;
          MessageBox(22,9,58,16,'Erro','Este Drive nao ‚ v lido.');
          Scr.RestoreScreen;
          Scr.CursorSize:=Normal;
          Scr.Cursor;
          Box1.BoxText:='';
          GoTo ReadAgain;
          End
            Else Begin
              If (UpCase(Box1.BoxText[1])='A') Or (UpCase(Box1.BoxText[1])='B') Then Begin
              GetCMOS(CMOSInfo); {Ask for CMOS about the drives}
                If (UpCase(Box1.BoxText[1])='A') And (CMOSInfo.FloppyA<>'None') Then Begin
                TestFloppy(UpCase(Box1.BoxText[1]),DriveReady,Status);
                GoTo Continue;
                End
                  Else Begin
                  Scr.SaveScreen;
                  MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
                  Scr.RestoreScreen;
                  Scr.CursorSize:=Normal;
                  Scr.Cursor;
                  Box1.BoxText:='';
                  GoTo ReadAgain;
                  End;
              If (UpCase(Box1.BoxText[1])='B') And (CMOSInfo.FloppyB<>'None') Then Begin
              TestFloppy(UpCase(Box1.BoxText[1]),DriveReady,Status);
              GoTo Continue;
              End
                Else Begin
                Scr.SaveScreen;
                MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
                Scr.RestoreScreen;
                Scr.CursorSize:=Normal;
                Scr.Cursor;
                Box1.BoxText:='';
                GoTo ReadAgain;
                End;
            Continue:
              If Not DriveReady Then Begin
              Scr.SaveScreen;
              MessageBox(22,9,58,16,'Erro','Drive de disquete nao pronto.');
              Scr.RestoreScreen;
              Scr.CursorSize:=Normal;
              Scr.Cursor;
              Box1.BoxText:='';
              GoTo ReadAgain;
              End;
            End
              Else If (Ord(UpCase(Box1.BoxText[1]))-65 = FirstCD) Then Begin
              Scr.SaveScreen;
              MessageBox(22,9,58,16,'Erro',' Nao ‚ poss¡vel criptografar arqui-vos em drives de CD-ROM.');
              Scr.RestoreScreen;
              Scr.CursorSize:=Normal;
              Scr.Cursor;
              Box1.BoxText:='';
              GoTo ReadAgain;
              End;
        SelectDrive(UpCase(Box1.BoxText[1]));
        End;
    End;
End;

Begin
  If MaxAvail<SizeOf(FullDir) Then Begin
  Scr.DosReturn;
  Scr.BackAscii(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao h  mem¢ria suficiente para exe-cutar esta operacao.');
  Exit;
  End
    Else Begin
    New(Dir); {Allocate Memory}
    End;
SetupDir(Dir);
Window(1,1,80,25);
TextBackGround(Blue);
ClrScr;
Scr.OpenWindow(2,2,79,23,LightCyan,Blue); {78 Characters/Line}
Window(1,1,80,24);
GoToXY(1,4);
Write('ÌÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹');
Window(2,2,79,3);
TextColor(Yellow);
Scr.Center(77,1,'Gerenciador de Arquivos');
TextColor(LightCyan);
GoToXY(1,2);
Write('Diret¢rio Atual: ');
GetDir(0,InitPath);
TextColor(White);
  If (Length(InitPath)>59) Then Begin
  ReduceStr(InitPath,RStr);
  Write(RStr);
  End
    Else Begin
    Write(InitPath);
    End;
Window(1,1,80,25);
GoToXY(1,25);
TextBackGround(White);
TextColor(Red);
Write(' ',#24,',',#25);
TextColor(Black);
Write(' Movimento  ');
TextColor(Red);
Write('PgUp/PgDn ');
TextColor(Black);
Write('Mais Arquivos  ');
TextColor(Red);
Write('F1 ');
TextColor(Black);
Write('Ajuda  ');
TextColor(Red);
Write('F2 ');
TextColor(Black);
Write('Trocar de Drive');
ClrEol;
Window(2,5,79,23);
TextColor(Yellow);
TextBackGround(Blue);
ClrScr;
Scr.Center(77,10,'Por favor aguarde...Carregando...');
LoadDir;
{0 is the first page}
RunTable;
End;

Procedure ReadPassword(Var Pass:Str20);
Var Box1:FixedDataBox;
Label GoAgain;
Begin
GoAgain:
Window(1,1,80,25);
Scr.BackASCII(#176,Blue,LightGray);
TextBackGround(Blue);
ClrEol;
TextColor(Yellow);
Scr.Center(79,1,'* Password *');
GoToXY(1,25);
TextBackGround(White);
ClrEol;
TextColor(Red);
Write(' Enter ');
TextColor(Black);
Write('Confirma a Senha  ');
TextColor(Red);
Write('Esc ');
TextColor(Black);
Write('Cancela a Operacao  ');
TextColor(Red);
Write('F1 ');
TextColor(Black);
Write('Ajuda');
Scr.TitleShadedWindow(8,5,72,20,White,Blue,'Entre com a sua Senha');
GoToXY(1,2);
TextColor(Yellow);
Write(' ',#254,' Voce agora deve entrar com a sua senha para a decodificacao ');
GoToXY(1,3);
Write('do arquivo no campo abaixo. Digite exatamente como quando voce ');
GoToXY(1,4);
Write('codificou o seu arquivo pela primeira vez, com as letras mai£s-');
GoToXY(1,5);
Write('culas e min£sculas nas mesmas posicoes originais.');
GoToXY(1,8);
TextColor(White);
Write(' ',#254,' Senha: ');
Box1.Init;
  With Box1 Do Begin
  X1:=12;
  X2:=31;
  Y1:=8;
  BoxColor:=Black;
  BoxTextColor:=LightGreen;
  Masked:=True;
  ByPassKeys[1]:=F1;
  DataType:=Mixed;
  End;
Scr.CursorSize:=Normal;
Scr.Cursor;
Box1.OpenDataBox;
  If (Box1.ExitMode=ByPassed) Then Begin
    If Not FileExists('Hlp5.Ehf') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
    GoTo GoAgain;
    End;
  Assign(HlpFile,'Hlp5.Ehf');
  EvaluateCRC(HlpFile,CRC);
  LongToHex(CRC,CRCStr);
    If (CRCStr<>'291704DB') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Aviso',
    'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
    GoTo GoAgain;
    End;
  HelpScroll('Hlp5.Ehf');
  {Call Help Procedure}
  GoTo GoAgain;
  End
    Else If (Box1.ExitMode=CancelExit) Then Begin
    Pass:='';
    Exit;
    End
      Else If (Box1.ExitMode=NormalExit) Then Begin
        If (Box1.BoxText='') Then Begin
        MessageBox(22,9,58,16,'Erro','Senha inv lida. A senha deve conterpelo menos um caracter.');
        GoTo GoAgain;
        End;
      End;
Scr.CursorSize:=Small;
Scr.Cursor;
Pass:=Box1.BoxText;
End;

Procedure GetEncFile(Var Path:String);
Var Box:DataBox;
    Drive,DriveReady:Boolean;
    CMOSInfo:CMOSRec;
    Status:Str12;
    IPath:String;
Label ReRead,Continue;

Begin
GetDir(0,IPath);
Box.Init;
  With Box Do Begin
  X1:=14;
  Y1:=11;
  X2:=44;
  BoxColor:=Black;
  BoxTextColor:=Yellow;
  ArrowColor:=(LightGreen+Blink);
  UseMouse:=False;
  ByPassKeys[1]:=F1;
  ByPassKeys[2]:=F2;
  End;
ReRead:
Window(1,1,80,25);
GoToXY(1,1);
Scr.BackASCII(#176,Blue,LightGray);
GoToXY(1,1);
TextColor(Yellow);
TextBackGround(Blue);
ClrEol;
Scr.Center(79,1,'Localizar Arquivo');
TextBackGround(White);
TextColor(Blue);
GoToXY(1,25);
ClrEol;
Write(' Enter ou Tab');
TextColor(Black);
Write(' Confirma Caminho  ');
TextColor(Blue);
Write('Esc');
TextColor(Black);
Write(' Cancela  ');
TextColor(Blue);
Write('F1 ');
TextColor(Black);
Write('Ajuda  ');
TextColor(Blue);
Write('F2 ');
TextColor(Black);
Write('Abre Explorer');
Scr.TitleShadedWindow(10,4,70,21,White,Blue,'Localizando seu Arquivo');
Window(11,5,69,20);
GoToXY(1,2);
TextColor(White);
WriteLn(' ',#254,
' Voce deve agora especificar o caminho do DOS  de onde seencontra o arquivo a ser decodificado.');
WriteLn(' ',#254,' Se voce nao sabe a sua localizacao exata, pode pressio- nar F2 para ativar o gerenciador de');
GoToXY(36,5);
Write(' arquivos que facilitar a sua busca.');
GoToXY(1,8);
Write(' ',#254,' Exemplo: ');
TextColor(Yellow);
Write('C:\Windows\Doc.Enc');
TextColor(White);
GoToXY(1,11);
Write(' ',#254,' Caminho:');
Scr.CursorSize:=Normal;
Scr.Cursor;
Box.OpenDataBox;
Scr.CursorSize:=Small;
Scr.Cursor;
    If (Box.ExitMode=CancelExit) Then Begin
    Path:='';
    Exit;
    End;
  If (Box.ExitMode=ByPassed) Then Begin
    If Box.ByPassedKey=F1 Then Begin
    {Call Help Procedure}
      If Not FileExists('Hlp2.Ehf') Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
      GoTo ReRead;
      End;
    Assign(HlpFile,'Hlp2.Ehf');
    EvaluateCRC(HlpFile,CRC);
    LongToHex(CRC,CRCStr);
      If (CRCStr<>'F65B7672') Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,'Erro',
      'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
      GoTo ReRead;
      End;
    {Call Help Routine}
    HelpScroll('Hlp2.Ehf');
    GoTo ReRead;
    End
      Else If Box.ByPassedKey=F2 Then Begin
      {Call Explorer Procedure}
      Explorer(Path);
      Box.BoxText:=Path;
      GoTo ReRead;
      End;
  End
    Else If (Box.ExitMode=NormalExit) Or (Box.ExitMode=TabExit) Then Begin
    {Do error checking}
    Path:=Box.BoxText;
      If (Pos(':\',Path)<>0) Then Begin {Drive Path Selected}
      Drive:=DriveValid(UpCase(Path[1]));
        If Not Drive Then Begin {Drive is not valid}
        MessageBox(22,9,58,16,'Erro','Este Drive nao ‚ v lido.');
        Box.BoxText:='';
        GoTo ReRead;
        End
          Else Begin {Is Valid}
            If (UpCase(Path[1])='A') Or (UpCase(Path[1])='B') Then Begin
            GetCMOS(CMOSInfo); {Ask for CMOS about the drives}
              If (UpCase(Path[1])='A') And (CMOSInfo.FloppyA<>'None') Then Begin
              TestFloppy(UpCase(Path[1]),DriveReady,Status);
              GoTo Continue;
              End
                Else Begin
                MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
                Box.BoxText:='';
                GoTo ReRead;
                End;
            If (UpCase(Path[1])='B') And (CMOSInfo.FloppyB<>'None') Then Begin
            TestFloppy(UpCase(Path[1]),DriveReady,Status);
            GoTo Continue;
            End
              Else Begin
              MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
              Box.BoxText:='';
              GoTo ReRead;
              End;
          Continue:
            If Not DriveReady Then Begin
            MessageBox(22,9,58,16,'Erro','Drive de disquete nao pronto.');
            Box.BoxText:='';
            GoTo ReRead;
            End;
          End
            Else If (Ord(UpCase(Path[1]))-65 = FirstCD) Then Begin
            MessageBox(22,9,58,16,'Erro',' Nao ‚ poss¡vel criptografar arqui-vos em drives de CD-ROM.');
            Box.BoxText:='';
            GoTo ReRead;
            End;
      End; {Finish Drives test}
        {Try to find the file}
        If (Not FileExists(Path)) Then Begin
        MessageBox(22,9,58,16,'Erro','Arquivo nao encontrado.');
        Box.BoxText:='';
        GoTo ReRead;
        End
          Else Begin
          ChDir(IPath);
          Exit;
          End;
      End {Drive Selected}
        Else Begin
        {Try to find the file}
          If (Not FileExists(Path)) Then Begin
          MessageBox(22,9,58,16,'Erro','Arquivo nao encontrado.');
          Box.BoxText:='';
          GoTo ReRead;
          End
            Else Begin {Found! Exit}
            ChDir(IPath);
            Exit;
            End;
        End;
    End;
ChDir(IPath);
End;

Procedure SearchFiles(Var Method:Byte;Var Path:String);
Var Box:DataBox;
    Choose:Byte;
    Drive,DriveReady:Boolean;
    CMOSInfo:CMOSRec;
    Status:Str12;
    TempFile:File;
    IPath:String;
Label ReRead,Continue;

  Function GetMethod:Byte;
  Label DoAgain;
  Begin
  DoAgain:
  GetMethod:=0; {Cancel=0}
  Choose:=1;
  Window(1,1,80,25);
  GoToXY(1,1);
  Scr.BackASCII(#176,Blue,LightGray);
  GoToXY(1,1);
  TextColor(Yellow);
  TextBackGround(Blue);
  ClrEol;
  Scr.Center(79,1,'Escolha o M‚todo de Criptografia');
  TextBackGround(White);
  TextColor(Blue);
  GoToXY(1,25);
  ClrEol;
  Write(' ',#24,',',#25);
  TextColor(Black);
  Write(' Seleciona Opcao  ');
  TextColor(Blue);
  Write('Enter');
  TextColor(Black);
  Write(' Confirma Opcao  ');
  TextColor(Blue);
  Write('F1 ');
  TextColor(Black);
  Write('Ajuda  ');
  TextColor(Blue);
  Write('Esc ');
  TextColor(Black);
  Write('Retorna ao inicio');
  Scr.ShadedSimpleWindow(10,4,70,8,White,Blue);
  WriteLn('  Na caixa de di logo abaixo, selecione o m‚todo de cripto-grafia que melhor se adapta   sua aplicacao.');
  GoToXY(45,2);
  Write('  Para maiores coment rios pressione ');
  TextColor(Yellow);
  Write('F1.');
  Scr.TitleShadedWindow(20,11,60,17,White,Blue,'#M‚todos');
  TextColor(Yellow);
  TextBackGround(White);
  GoToXY(1,2);
  ClrEol;
  Scr.Center(42,2,'M‚todo #1 - Baixo N¡vel de Protecao');
  TextBackGround(Blue);
  Scr.Center(42,3,'M‚todo #2 - N¡vel Intermedi rio');
  Scr.Center(42,4,'M‚todo #3 - N¡vel M ximo');
    Repeat
    Keyb.InKey;
      If (Keyb.Key=DownArrow) Then Begin
        Case Choose Of
          1:Begin
          TextBackGround(Blue);
          GoToXY(1,2);
          ClrEol;
          Scr.Center(42,2,'M‚todo #1 - Baixo N¡vel de Protecao');
          TextBackGround(White);
          GoToXY(1,3);
          ClrEol;
          Scr.Center(42,3,'M‚todo #2 - N¡vel Intermedi rio');
          Inc(Choose);
          End;
            2:Begin
            TextBackGround(Blue);
            GoToXY(1,3);
            ClrEol;
            Scr.Center(42,3,'M‚todo #2 - N¡vel Intermedi rio');
            TextBackGround(White);
            GoToXY(1,4);
            ClrEol;
            Scr.Center(42,4,'M‚todo #3 - N¡vel M ximo');
            Inc(Choose);
            End;
        End;
      End
        Else If (Keyb.Key=UpArrow) Then Begin
          Case Choose Of
           3:Begin
           TextBackGround(Blue);
           GoToXY(1,4);
           ClrEol;
           Scr.Center(42,4,'M‚todo #3 - N¡vel M ximo');
           TextBackGround(White);
           GoToXY(1,3);
           ClrEol;
           Scr.Center(42,3,'M‚todo #2 - N¡vel Intermedi rio');
           Dec(Choose);
           End;
             2:Begin
             TextBackGround(Blue);
             GoToXY(1,3);
             ClrEol;
             Scr.Center(42,3,'M‚todo #2 - N¡vel Intermedi rio');
             TextBackGround(White);
             GoToXY(1,2);
             ClrEol;
             Scr.Center(42,2,'M‚todo #1 - Baixo N¡vel de Protecao');
             Dec(Choose);
             End;
          End;
        End;
    Until (Keyb.Key=Enter) Or (Keyb.Key=Esc) Or (Keyb.Key=F1);
      If (Keyb.Key=Enter) Then Begin
      GetMethod:=Choose;
      End
        Else If (Keyb.Key=Esc) Then Begin
        GetMethod:=0;
        Exit;
        End
          Else If (Keyb.Key=F1) Then Begin
          {Call Help Procedure}
            If Not FileExists('Hlp1.Ehf') Then Begin
            Scr.DosReturn;
            Scr.BackAscii(#177,Blue,LightGray);
            Window(1,1,80,25);
            MessageBox(22,9,58,16,' Erro ','Arquivo de ajuda nao encontrado.');
            GoTo DoAgain;
            End;
          Assign(HlpFile,'Hlp1.Ehf');
          EvaluateCRC(HlpFile,CRC);
          LongToHex(CRC,CRCStr);
            If (CRCStr<>'E3F7E76A') Then Begin
            Scr.DosReturn;
            Scr.BackAscii(#177,Blue,LightGray);
            MessageBox(22,9,58,16,' Erro ',
            'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
            GoTo DoAgain;
            End;
          {Call Help Routine}
          HelpScroll('Hlp1.Ehf');
          GoTo DoAgain;
          End;
  End;

Begin
Method:=GetMethod;
  If (Method=0) Then Begin
  Exit; {Cancel}
  End;
GetDir(0,IPath);
Box.Init;
  With Box Do Begin
  X1:=14;
  Y1:=11;
  X2:=44;
  BoxColor:=Black;
  BoxTextColor:=Yellow;
  ArrowColor:=(LightGreen+Blink);
  UseMouse:=False;
  ByPassKeys[1]:=F1;
  ByPassKeys[2]:=F2;
  End;
ReRead:
Window(1,1,80,25);
GoToXY(1,1);
Scr.BackASCII(#176,Blue,LightGray);
GoToXY(1,1);
TextColor(Yellow);
TextBackGround(Blue);
ClrEol;
Scr.Center(79,1,'Localizar Arquivo');
TextBackGround(White);
TextColor(Blue);
GoToXY(1,25);
ClrEol;
Write(' Enter ou Tab');
TextColor(Black);
Write(' Confirma Caminho  ');
TextColor(Blue);
Write('Esc');
TextColor(Black);
Write(' Cancela  ');
TextColor(Blue);
Write('F1 ');
TextColor(Black);
Write('Ajuda  ');
TextColor(Blue);
Write('F2 ');
TextColor(Black);
Write('Abre Explorer');
Scr.TitleShadedWindow(10,4,70,21,White,Blue,'Localizando seu Arquivo');
Window(11,5,69,20);
GoToXY(1,2);
Write(' ',#254,' M‚todo Selecionado: ');
TextColor(Yellow);
Write('#',Choose);
TextColor(White);
GoToXY(1,4);
WriteLn(' ',#254,
' Voce deve agora especificar o caminho do DOS  de onde seencontra o arquivo que voce deseja proteger.');
GoToXY(45,5);
WriteLn(' Se voce nao sabe a sua localizacao exata, pode pressionar F2  para ativaro gerenciador de');
GoToXY(18,7);
WriteLn('arquivos que facilitar  a sua busca.');
GoToXY(1,9);
Write(' ',#254,' Exemplo: ');
TextColor(Yellow);
Write('C:\Winword\Doc1.Doc');
TextColor(White);
GoToXY(1,11);
Write(' ',#254,' Caminho:');
Scr.CursorSize:=Normal;
Scr.Cursor;
Box.OpenDataBox;
Scr.CursorSize:=Small;
Scr.Cursor;
    If (Box.ExitMode=CancelExit) Then Begin
    Method:=0;
    End;
  If (Box.ExitMode=ByPassed) Then Begin
    If Box.ByPassedKey=F1 Then Begin
    {Call Help Procedure}
      If Not FileExists('Hlp2.Ehf') Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,' Erro ','Arquivo de ajuda nao encontrado.');
      GoTo ReRead;
      End;
    Assign(HlpFile,'Hlp2.Ehf');
    EvaluateCRC(HlpFile,CRC);
    LongToHex(CRC,CRCStr);
      If (CRCStr<>'F65B7672') Then Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,' Erro ',
      'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
      GoTo ReRead;
      End;
    {Call Help Routine}
    HelpScroll('Hlp2.Ehf');
    GoTo ReRead;
    End
      Else If Box.ByPassedKey=F2 Then Begin
      {Call Explorer Procedure}
      Explorer(Path);
      Box.BoxText:=Path;
      GoTo ReRead;
      End;
  End
    Else If (Box.ExitMode=NormalExit) Or (Box.ExitMode=TabExit) Then Begin
    {Do error checking}
    Path:=Box.BoxText;
      If (Pos(':\',Path)<>0) Then Begin {Drive Path Selected}
      Drive:=DriveValid(UpCase(Path[1]));
        If Not Drive Then Begin {Drive is not valid}
        MessageBox(22,9,58,16,'Erro','Este Drive nao ‚ v lido.');
        Box.BoxText:='';
        GoTo ReRead;
        End
          Else Begin {Is Valid}
            If (UpCase(Path[1])='A') Or (UpCase(Path[1])='B') Then Begin
            GetCMOS(CMOSInfo); {Ask for CMOS about the drives}
              If (UpCase(Path[1])='A') And (CMOSInfo.FloppyA<>'None') Then Begin
              TestFloppy(UpCase(Path[1]),DriveReady,Status);
              GoTo Continue;
              End
                Else Begin
                MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
                Box.BoxText:='';
                GoTo ReRead;
                End;
            If (UpCase(Path[1])='B') And (CMOSInfo.FloppyB<>'None') Then Begin
            TestFloppy(UpCase(Path[1]),DriveReady,Status);
            GoTo Continue;
            End
              Else Begin
              MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
              Box.BoxText:='';
              GoTo ReRead;
              End;
          Continue:
            If Not DriveReady Then Begin
            MessageBox(22,9,58,16,'Erro','Drive de disquete nao pronto.');
            Box.BoxText:='';
            GoTo ReRead;
            End;
          End
            Else If (Ord(UpCase(Path[1]))-65 = FirstCD) Then Begin
            MessageBox(22,9,58,16,'Erro',' Nao ‚ poss¡vel criptografar arqui-vos em drives de CD-ROM.');
            Box.BoxText:='';
            GoTo ReRead;
            End;
      End; {Finish Drives test}
        {Try to find the file}
        If (Not FileExists(Path)) Then Begin
        MessageBox(22,9,58,16,'Erro','Arquivo nao encontrado.');
        Box.BoxText:='';
        GoTo ReRead;
        End
          Else Begin
          ChDir(IPath);
          Exit;
          End;
      End {Drive Selected}
        Else Begin
        {Try to find the file}
          If (Not FileExists(Path)) Then Begin
          MessageBox(22,9,58,16,'Erro','Arquivo nao encontrado.');
          Box.BoxText:='';
          GoTo ReRead;
          End
            Else Begin {Found! Exit}
            ChDir(IPath);
            Exit;
            End;
        End;
    End;
ChDir(IPath);
End;

Procedure GetPassword(Var Pass:Str20);
Var Box1,Box2:FixedDataBox;
Label Continue,Continue2,GoAgain,ReadAgain,ReadAgain2;
Begin
GoAgain:
Window(1,1,80,25);
Scr.BackASCII(#176,Blue,LightGray);
TextBackGround(Blue);
ClrEol;
TextColor(Yellow);
Scr.Center(79,1,'* Password *');
GoToXY(1,25);
TextBackGround(White);
ClrEol;
TextColor(Red);
Write(' Enter ');
TextColor(Black);
Write('Confirma a Senha  ');
TextColor(Red);
Write('Esc ');
TextColor(Black);
Write('Cancela a Criptografia  ');
TextColor(Red);
Write('F1 ');
TextColor(Black);
Write('Ajuda');
Scr.TitleShadedWindow(8,4,72,22,White,Blue,'Entre com a sua Senha');
GoToXY(1,2);
TextColor(Yellow);
Write(' ',#254,' Voce agora deve entrar com a sua senha para a protecao do ar');
GoToXY(1,3);
Write('quivo no campo abaixo. (m ximo 20 caracteres)');
GoToXY(1,6);
TextColor(White);
Write(' ',#254,' Senha: ');
Box1.Init;
Box2.Init;
  With Box1 Do Begin
  X1:=12;
  X2:=31;
  Y1:=6;
  BoxColor:=Black;
  BoxTextColor:=White;
  Masked:=True;
  ByPassKeys[1]:=F1;
  DataType:=Mixed;
  End;
    With Box2 Do Begin
    X1:=12;
    X2:=31;
    Y1:=12;
    BoxColor:=Black;
    BoxTextColor:=Yellow;
    Masked:=True;
    ByPassKeys[1]:=F1;
    DataType:=Mixed;
    End;
ReadAgain:
Scr.CursorSize:=Normal;
Scr.Cursor;
Box1.OpenDataBox;
  If (Box1.ExitMode=ByPassed) Then Begin
  Scr.SaveScreen;
    If Not FileExists('Hlp4.Ehf') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
    GoTo Continue;
    End;
  Assign(HlpFile,'Hlp4.Ehf');
  EvaluateCRC(HlpFile,CRC);
  LongToHex(CRC,CRCStr);
    If (CRCStr<>'31E96679') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Aviso',
    'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
    GoTo Continue;
    End;
  HelpScroll('Hlp4.Ehf');
  {Call Help Procedure}
  Continue:
  Scr.RestoreScreen;
  GoTo ReadAgain;
  End
    Else If (Box1.ExitMode=CancelExit) Then Begin
    Pass:='';
    Exit;
    End
      Else If (Box1.ExitMode=NormalExit) Then Begin
        If (Box1.BoxText='') Then Begin
        Scr.SaveScreen;
        MessageBox(22,9,58,16,'Erro','A senha deve conter no m¡nimo um caracter.');
        Scr.RestoreScreen;
        GoTo ReadAgain;
        End;
      End;
Scr.CursorSize:=Small;
Scr.Cursor;
TextColor(Yellow);
TextBackGround(Blue);
GoToXY(1,9);
Write(' ',#254,' Por favor confirme a sua senha no campo de entrada a seguir.');
TextColor(White);
GoToXY(1,12);
Write(' ',#254,' Senha: ');
ReadAgain2:
Scr.CursorSize:=Normal;
Scr.Cursor;
Box2.OpenDataBox;
  If (Box2.ExitMode=ByPassed) Then Begin
  Scr.SaveScreen;
    If Not FileExists('Hlp4.Ehf') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
    GoTo Continue2;
    End;
  Assign(HlpFile,'Hlp4.Ehf');
  EvaluateCRC(HlpFile,CRC);
  LongToHex(CRC,CRCStr);
    If (CRCStr<>'31E96679') Then Begin
    Scr.DosReturn;
    Scr.BackAscii(#177,Blue,LightGray);
    MessageBox(22,9,58,16,'Aviso',
    'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
    GoTo Continue2;
    End;
  {Call Help Procedure}
  HelpScroll('Hlp4.Ehf');
  Continue2:
  Scr.RestoreScreen;
  GoTo ReadAgain2;
  End
    Else If (Box2.ExitMode=CancelExit) Then Begin
    Pass:='';
    Exit;
    End
      Else If (Box2.ExitMode=NormalExit) Then Begin
        If (Box1.BoxText<>Box2.BoxText) Then Begin
        MessageBox(22,9,58,16,'Erro','A senha nao confere.Por favor tentenovamente.');
        Box1.BoxText:='';
        Box2.BoxText:='';
        GoTo GoAgain;
        End;
      End;
Pass:=Box1.BoxText;
TextBackGround(Blue);
TextColor(Yellow);
GoToXY(1,15);
Scr.CursorSize:=Small;
Scr.Cursor;
Write(' ',#254,' OK confere. Guarde com cuidado a sua senha para uma posteri-or decodificacao de seu arqui');
Write('vo, lembre-se de que sem ela voce JAMAIS poder  recuper -lo. ');
TextColor(White+Blink);
Write('      Pressione <ENTER>...');
  Repeat
  Keyb.Inkey;
  Until (Keyb.Key=Enter);
End;

Procedure SystemDate(Var Y,M,D,DoW:Word);
Begin
GetDate(Y,M,D,DoW);
End;

Procedure Clock;
Var H,M,S,S100:Word;
Label Go;
Begin
Window(36,6,74,20);
TextBackGround(Blue);
TextColor(Yellow);
GetTime(H,M,S,S100);
GoToXY(31,15);
  If (S In [0..9]) And (M In [0..9]) Then Begin
  Write(H,':0',M,':0',S);
  GoTo Go;
  End
    Else If M In [0..9] Then Begin
    Write(H,':0',M,':',S);
    GoTo Go;
    End
      Else If S In [0..9] Then Begin
      Write(H,':',M,':0',S);
      GoTo Go;
      End
        Else If H In [0..9] Then Begin
        Write('0',H,':',M,':',S);
        GoTo Go;
        End
          Else If (S In [0..9]) And (M In [0..9]) And (H In [0..9]) Then Begin
          Write('0',H,':0',M,':0',S);
          GoTo Go;
          End
            Else If (S In [0..9]) And (H In [0..9]) Then Begin
            Write('0',H,':',M,':0',S);
            GoTo Go;
            End
              Else If (M In [0..9]) And (H In [0..9]) Then Begin
              Write('0',H,':0',M,':',S);
              GoTo Go;
              End;
Write(H,':',M,':',S);
Go:
TextColor(White);
Window(6,7,28,18);
End;

Procedure MainMenu;
Begin
Scr.BackASCII(#177,Blue,LightGray);
Scr.OpenWindow(6,2,74,2,White,Blue);
TextColor(LightCyan);
Scr.Center(71,1,'*** ENCRYPTOR-Versao 3.0 ***');
Scr.CompleteWindow(5,6,29,19,White,Blue);
TextColor(Yellow);
Scr.Center(26,1,'Menu Principal');
Scr.Center(26,2,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
Scr.Center(26,3,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
TextColor(White);
TextBackGround(Red);
Scr.HighLightText('~Codificar',8,4,White,Red,LightCyan);
Choice:=1;
TextColor(White);
TextBackGround(Blue);
Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
Scr.Center(26,8,'Ajuda');
Scr.Center(26,9,'Sa¡da');
TextColor(Yellow);
Scr.Center(26,10,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
Scr.Center(26,11,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
Scr.CompleteWindow(35,5,75,21,White,Blue);
TextColor(Yellow);
WriteLn(' Encryptor V3.0 - 15/07/1998');
WriteLn;
TextColor(White);
WriteLn('   Utilit rio para protecao de arquivospor senha.');
GoToXY(11,4);
Write(' Para maiores informacoes consulte a ajuda.');
TextColor(LightGreen);
GoToXY(2,7);
Write('* F1 =');
TextColor(White);
Write(' Ajuda On-Line');
TextColor(LightGreen);
Write(' * ALT+X =');
TextColor(White);
Write(' Sa¡da');
WriteLn;
Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
TextColor(LightGreen);
WriteLn('þ Descricao do Comando:');
TextColor(White);
WriteLn('þ Codifica um arquivo com a senha fornecida.');
GoToXY(1,12);
Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
GoToXY(1,15);
TextColor(Yellow);
Write(' ',DaysOfWeek[DoW],' ',D,'/',Month,'/',Y);
GoToXY(1,13);
TextColor(LightGreen);
Write('þ Mem¢ria: ');
TextColor(White);
Write(MemAvail,' Bytes');
Window(1,1,80,25);
M.MoveCursor(5,6);
GoToXY(1,25);
TextBackGround(White);
ClrEol;
TextColor(Red);
Write(' ALT+C ');
TextColor(Black);
Write('Codificar  ');
TextColor(Red);
Write('ALT+D ');
TextColor(Black);
Write('Decodificar  ');
TextColor(Red);
Write('F1 ');
TextColor(Black);
Write('Ajuda  ');
TextColor(Red);
Write('ALT+X ');
TextColor(Black);
Write('Sa¡da');
Window(6,7,28,18);
M.MoveCursor(60,25);
End;

Procedure DosShell;
Var ExecNow:Word;
Begin
Scr.DosReturn;
TextColor(LightGreen);
Scr.Center(78,1,'*** PROMPT DO MS-DOS ***');
Writeln;
Writeln;
TextColor(White);
Writeln('Escreva EXIT para retornar ao programa.');
TextColor(LightGray);
GetDir(0,CPath);
ExecNow:=Execute(GetEnv('COMSPEC'),'');
  If (ExecNow<>0) Then Begin
    Case ExecNow Of
      2:Begin
      Scr.DosReturn;
      Scr.BackAscii(#177,Blue,LightGray);
      M.RestoreFullWindow;
      M.MoveCursor(25,13);
      Scr.BackAscii(#177,Blue,LightGray);
      MessageBox(22,9,58,16,'Erro',
      'Nao foi poss¡vel encontrar o arqui-vo "COMMAND.COM". O prompt do Ms-Dos nao estara dispon¡vel.');
      M.MouseWindow(0,24,79,24);
      End;
       3:Begin
       Scr.DosReturn;
       Scr.BackAscii(#177,Blue,LightGray);
       M.RestoreFullWindow;
       M.MoveCursor(25,13);
       Scr.BackAscii(#177,Blue,LightGray);
       MessageBox(22,9,58,16,'Erro',
       'Nao foi poss¡vel encontrar o arqui-vo "COMMAND.COM". O prompt do Ms-Dos nao estara dispon¡vel.');
       M.MouseWindow(0,24,79,24);
       End;
         8:Begin
         Scr.DosReturn;
         M.RestoreFullWindow;
         M.MoveCursor(1,1);
         Scr.BackAscii(#177,Blue,LightGray);
         M.MoveCursor(25,13);
         Scr.BackAscii(#177,Blue,LightGray);
         MessageBox(22,9,58,16,'Erro',
         'Nao h  mem¢ria suficiente para car-regar COMMAND.COM');
         M.MouseWindow(0,24,79,24);
         End;
           Else Begin
           Scr.DosReturn;
           Scr.BackAscii(#177,Blue,LightGray);
           M.RestoreFullWindow;
           M.MoveCursor(25,13);
           Scr.BackAscii(#177,Blue,LightGray);
           MessageBox(22,9,58,16,'Erro',
           'Erro ao carregar COMMAND.COM');
           M.MouseWindow(0,24,79,24);
           End;
    End;
  End;
ChDir(CPath);
Window(1,1,80,25);
GoToXY(1,1);
End;

Begin {Programa Principal}
CopyRight;
CheckResources;
ExitSave:=ExitProc;
ExitProc:=@ExitP;
GetDir(0,CPath);
SystemDate(Y,Month,D,DoW);
InitScreen;
ReDraw:
Window(1,1,80,25);
GoToXY(1,1);
KeyboardOK:=False;
MouseOK:=False;
MainMenu;
  Repeat
    While Not KeyPressed Do Begin
    M.GetMouseState;
      If (M.Bt=1) And (M.X In [1..59]) Then Begin
      Window(1,1,80,25);
      TextBackGround(Green);
        Case M.X Of
         1..17:Begin
         GoToXY(1,25);
         TextColor(Red);
         Write(' ALT+C ');
         TextColor(Black);
         Write('Codificar ');
           While (M.Bt=1) Do Begin
           M.GetMouseState;
           Clock;
           End;
         GoTo GoEncode;
         End;
           18..36:Begin
           GoToXY(18,25);
           TextColor(Red);
           Write(' ALT+D ');
           TextColor(Black);
           Write('Decodificar ');
             While (M.Bt=1) Do Begin
             M.GetMouseState;
             Clock
             End;
           GoTo GoDecode;
           End;
             37..46:Begin
             GoToXY(37,25);
             TextColor(Red);
             Write(' F1 ');
             TextColor(Black);
             Write('Ajuda ');
               While (M.Bt=1) Do Begin
               M.GetMouseState;
               Clock;
               End;
             GoTo HelpStart;
             End;
               47..59:Begin
               GoToXY(47,25);
               TextColor(Red);
               Write(' ALT+X ');
               TextColor(Black);
               Write('Sa¡da ');
                 While (M.Bt=1) Do Begin
                 M.GetMouseState;
                 Clock;
                 End;
               GoTo ExitGo;
               End;
        End;
      MouseOK:=True;
      GoTo Jump;
      End;
    Clock;
    End;
  Keyb.Inkey;
    If (Keyb.Key=DownArrow) Then Begin
      Case Choice Of
       1:Begin
       Inc(Choice);
       Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
       Scr.HighLightText('~Decodificar',7,5,White,Red,LightCyan);
       Window(36,6,74,20);
       GoToXY(1,10);
       TextBackGround(Blue);
       Write('þ Decodifica um arquivo com a senha fornecida.');
       Window(6,7,28,18);
       End;
         2:Begin
         Inc(Choice);
         Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
         Scr.HighLightText('System ~Info',7,6,White,Red,LightCyan);
         Window(36,6,74,20);
         GoToXY(1,10);
         TextBackGround(Blue);
         Write('þ Fornece informacoes detalhadas sobre o seu computador.');
         Window(6,7,28,18);
         End;
           3:Begin
           Inc(Choice);
           Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
           Scr.HighLightText('Dos ~Shell',8,7,White,Red,LightCyan);
           Window(36,6,74,20);
           TextBackGround(Blue);
           GoToXY(1,10);
           ClrEol;
           GoToXY(1,11);
           ClrEol;
           GoToXY(1,10);
           Write('þ Prompt do MS-DOS.');
           Window(6,7,28,18);
           End;
             4:Begin
             Inc(Choice);
             Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
             TextBackGround(Red);
             Scr.Center(26,8,'Ajuda');
             Window(36,6,74,20);
             TextBackGround(Blue);
             GoToXY(1,10);
             ClrEol;
             GoToXY(1,11);
             ClrEol;
             GoToXY(1,10);
             Write('þ Ajuda On-Line.');
             Window(6,7,28,18);
             End;
               5:Begin
               Inc(Choice);
               TextBackGround(Blue);
               Scr.Center(26,8,'Ajuda');
               TextBackGround(Red);
               Scr.Center(26,9,'Sa¡da');
               Window(36,6,74,20);
               TextBackGround(Blue);
               GoToXY(1,10);
               ClrEol;
               GoToXY(1,11);
               ClrEol;
               GoToXY(1,10);
               Write('þ Sai do programa.');
               Window(6,7,28,18);
               End;
                 6:Begin
                 Choice:=1;
                 TextBackGround(Blue);
                 Scr.Center(26,9,'Sa¡da');
                 Scr.HighLightText('~Codificar',8,4,White,Red,LightCyan);
                 Window(36,6,74,20);
                 GoToXY(1,10);
                 TextBackGround(Blue);
                 Write('þ Codifica um arquivo com a senha fornecida.');
                 Window(6,7,28,18);
                 End;
      End;
    End
      Else If (Keyb.Key=UpArrow) Then Begin
        Case Choice Of
         6:Begin
         Dec(Choice);
         TextBackGround(Blue);
         Scr.Center(26,9,'Sa¡da');
         TextBackGround(Red);
         Scr.Center(26,8,'Ajuda');
         Window(36,6,74,20);
         TextBackGround(Blue);
         GoToXY(1,10);
         ClrEol;
         GoToXY(1,11);
         ClrEol;
         GoToXY(1,10);
         Write('þ Ajuda On-Line.');
         Window(6,7,28,18);
         End;
           5:Begin
           Dec(Choice);
           TextBackGround(Blue);
           Scr.Center(26,8,'Ajuda');
           Scr.HighLightText('Dos ~Shell',8,7,White,Red,LightCyan);
           Window(36,6,74,20);
           TextBackGround(Blue);
           GoToXY(1,10);
           ClrEol;
           GoToXY(1,11);
           ClrEol;
           GoToXY(1,10);
           Write('þ Prompt do MS-DOS.');
           Window(6,7,28,18);
           End;
             4:Begin
             Dec(Choice);
             Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
             Scr.HighLightText('System ~Info',7,6,White,Red,LightCyan);
             Window(36,6,74,20);
             GoToXY(1,10);
             TextBackGround(Blue);
             Write('þ Fornece informacoes detalhadas sobre o seu computador.');
             Window(6,7,28,18);
             End;
               3:Begin
               Dec(Choice);
               Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
               Scr.HighLightText('~Decodificar',7,5,White,Red,LightCyan);
               TextBackGround(Blue);
               Window(36,6,74,20);
               GoToXY(1,10);
               ClrEol;
               GoToXY(1,11);
               ClrEol;
               GoToXY(1,10);
               Write('þ Decodifica um arquivo com a senha fornecida.');
               Window(6,7,28,18);
               End;
                 2:Begin
                 Dec(Choice);
                 Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
                 Scr.HighLightText('~Codificar',8,4,White,Red,LightCyan);
                 TextBackGround(Blue);
                 Window(36,6,74,20);
                 GoToXY(1,10);
                 ClrEol;
                 GoToXY(1,11);
                 ClrEol;
                 GoToXY(1,10);
                 Write('þ Codifica um arquivo com a senha fornecida.');
                 Window(6,7,28,18);
                 End;
                   1:Begin
                   Choice:=6;
                   Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
                   TextBackGround(Red);
                   Scr.Center(26,9,'Sa¡da');
                   Window(36,6,74,20);
                   TextBackGround(Blue);
                   GoToXY(1,10);
                   ClrEol;
                   GoToXY(1,11);
                   ClrEol;
                   GoToXY(1,10);
                   Write('þ Sai do programa.');
                   Window(6,7,28,18);
                   End;
        End;
      End
        Else If (Keyb.Key=Enter) Or (Keyb.Key=Alt_X) Or (Keyb.Key=Alt_C)
        Or (Keyb.Key=Alt_D) Or (Keyb.Key=Alt_I) Or (Keyb.Key=Alt_S) Or
        (Keyb.Key=F1) Then Begin
          Case Keyb.Key Of
          Alt_X: Choice:=6;
          Alt_C: Choice:=1;
          Alt_D: Choice:=2;
          Alt_I: Choice:=3;
          Alt_S: Choice:=4;
          F1: Choice:=5;
          End;
        KeyboardOK:=True;
        End;
  Jump:
  Until (KeyboardOK) Or (MouseOK);
{Call the Routines}
  If KeyboardOK Then Begin
    Case Choice Of
     1:Begin
     GoEncode:
     Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
     Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
     Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
     Scr.Center(26,8,'Ajuda');
     Scr.Center(26,9,'Sa¡da');
       For i:=1 To 3 Do Begin
       TextBackGround(Blue);
       Scr.Center(26,4,'         ');
       Delay(100);
       Scr.HighLightText('~Codificar',8,4,White,Red,LightCyan);
       Delay(100);
       End;
     {Call Encode Routine}
     SearchFiles(Method,SourcePath);
       If (Method=0) Then Begin
       GoTo ReDraw;
       End;
     Assign(SourceFile,SourcePath);
     GetFAttr(SourceFile,Attrib);
       If (Attrib And ReadOnly)<>0 Then Begin
       Scr.DosReturn;
       Scr.BackAscii(#177,Blue,LightGray);
       MessageBox(22,9,58,16,'Erro',
       'O arquivo ‚ somente para leitura.    Acesso negado.');
       GoTo Redraw;
       End;
     GetPassword(Password);
       If (Password='') Then Begin
       GoTo ReDraw;
       End;
     {Check for memory}
       If (MaxAvail<4097) Then Begin
       Scr.DosReturn;
       Scr.BackAscii(#177,Blue,LightGray);
       MessageBox(22,9,58,16,'Erro',
       'Nao h  mem¢ria suficiente para exe-cutar esta operacao.');
       GoTo Redraw;
       End;
     UpperStr(SourcePath);
     DoHeader(SourcePath,Method,Password,Error);
       If Error Then Begin
       Scr.DosReturn;
       Scr.BackAscii(#177,Blue,LightGray);
       MessageBox(22,9,58,16,'Erro',
       'Nao foi poss¡vel criar o arquivo dedestino. Veja se o disco nao est  protegido contra grava‡ao.');
       GoTo Redraw;
       End;
     {Call other routines}
     EncryptFile(SourceFile,DestFile,Method);
     GoTo Redraw;
     End;
       2:Begin
       GoDecode:
       Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
       Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
       Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
       Scr.Center(26,8,'Ajuda');
       Scr.Center(26,9,'Sa¡da');
         For i:=1 To 3 Do Begin
         TextBackGround(Blue);
         Scr.Center(26,5,'           ');
         Delay(100);
         Scr.HighLightText('~Decodificar',7,5,White,Red,LightCyan);
         Delay(100);
         End;
       {Call Decode Routine}
       ReadPassword(Password);
         If Password='' Then GoTo ReDraw;
       GetEncFile(SourcePath);
       UpperStr(SourcePath);
         If (SourcePath='') Then GoTo ReDraw;
           For i:=Length(SourcePath) DownTo 1 Do Begin
             If (SourcePath[i]='.') Then Begin
             PointPos:=i;
             Break;
             End;
           End;
       DestPath:=Copy(SourcePath,1,PointPos);
         For i:=Length(SourcePath) DownTo 1 Do Begin
             If (SourcePath[i]='\') Then Begin
             PointPos:=i;
             Break;
             End;
           End;
       TempPath:=Copy(SourcePath,1,PointPos);
       Assign(SourceFile,SourcePath);
       GetFAttr(SourceFile,Attrib);
         If (Attrib And ReadOnly)<>0 Then Begin
         Scr.DosReturn;
         Scr.BackAscii(#177,Blue,LightGray);
         MessageBox(22,9,58,16,'Erro',
         'O arquivo ‚ somente para leitura.    Acesso negado.');
         GoTo Redraw;
         End;
       ExpandHeader(SourceFile,Header,ErrorCode);
         If (ErrorCode=1) Then Begin
         Scr.DosReturn;
         Scr.BackAscii(#177,Blue,LightGray);
         MessageBox(22,9,58,16,'Erro',
         'Erro abrindo arquivo fonte.');
         GoTo Redraw;
         End
           Else If (ErrorCode=2) Then Begin
           Scr.DosReturn;
           Scr.BackAscii(#177,Blue,LightGray);
           MessageBox(22,9,58,16,'Erro',
           'Arquivo nao codificado.');
           Close(SourceFile);
           GoTo Redraw;
           End;
             If (Header.Signature<>'$LCK300$') Then Begin
             Scr.DosReturn;
             Scr.BackAscii(#177,Blue,LightGray);
             MessageBox(22,9,58,16,'Erro',
             'Arquivo nao criptografado por Encryptor V3.0.');
             Close(SourceFile);
             GoTo Redraw;
             End;
       DestPath:=DestPath+Header.Extension;
       GenerateSeeds(Password,Seed1,Seed2);
         If (Seed1<>Header.Seed1) Or (Seed2<>Header.Seed2) Then Begin
         Scr.DosReturn;
         Scr.BackAscii(#177,Blue,LightGray);
         MessageBox(22,9,58,16,'Erro',
         'Senha Incorreta!');
         Close(SourceFile);
         GoTo Redraw;
         End;
       Assign(DestFile,TempPath+'$$$$$.$$');{Do you see any file with this name?}
       {$I-}
       ReWrite(DestFile,1);
       {$I+}
         If IOResult<>0 Then Begin
         Scr.DosReturn;
         Scr.BackAscii(#177,Blue,LightGray);
         MessageBox(22,9,58,16,'Erro',
         'Nao foi poss¡vel criar o arquivo dedestino. Veja se o disco nao est  protegido contra grava‡ao.');
         Close(SourceFile);
         GoTo Redraw;
         End;
       {Call Routine to Decrypt}
       DecryptFile(SourceFile,DestFile,Header.Method);
       Rename(DestFile,DestPath); {DestFile is the original archive}
       GoTo ReDraw;
       End;
         3:Begin
         Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
         Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
         Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
         Scr.Center(26,8,'Ajuda');
         Scr.Center(26,9,'Sa¡da');
           For i:=1 To 3 Do Begin
           TextBackGround(Blue);
           Scr.Center(26,6,'           ');
           Delay(100);
           Scr.HighLightText('System ~Info',7,6,White,Red,LightCyan);
           Delay(100);
           End;
         {Call System Info Routine}
         M.MouseWindow(0,24,79,24);
         SystemInfo;
         GoTo Redraw;
         End;
           4:Begin
           Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
           Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
           Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
           Scr.Center(26,8,'Ajuda');
           Scr.Center(26,9,'Sa¡da');
             For i:=1 To 3 Do Begin
             TextBackGround(Blue);
             Scr.Center(26,7,'         ');
             Delay(100);
             Scr.HighLightText('Dos ~Shell',8,7,White,Red,LightCyan);
             Delay(100);
             End;
           {Call Dos Shell Routine}
           DosShell;
           GoTo ReDraw;
           End;
             5:Begin
             HelpStart:
             Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
             Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
             Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
             Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
             Scr.Center(26,9,'Sa¡da');
               For i:=1 To 3 Do Begin
               TextBackGround(Blue);
               Scr.Center(26,8,'     ');
               Delay(100);
               TextBackGround(Red);
               Scr.Center(26,8,'Ajuda');
               Delay(100);
               End;
                 If Not FileExists('Main.Ehf') Then Begin
                 Scr.DosReturn;
                 Scr.BackAscii(#177,Blue,LightGray);
                 MessageBox(22,9,58,16,'Erro','Arquivo de ajuda nao encontrado.');
                 GoTo Redraw;
                 End;
             Assign(HlpFile,'Main.Ehf');
             EvaluateCRC(HlpFile,CRC);
             LongToHex(CRC,CRCStr);
               If (CRCStr<>'A01B8E1F') Then Begin
               Scr.DosReturn;
               Scr.BackAscii(#177,Blue,LightGray);
               MessageBox(22,9,58,16,'Erro',
               'O arquivo foi modificado. Por favorrestaure o arquivo original do disco de instalacao.');
               GoTo Redraw;
               End;
             {Call Help Routine}
             HelpScroll('Main.Ehf');
             GoTo ReDraw;
             End;
               6:Begin
               ExitGo:
               Scr.HighLightText('~Codificar',8,4,White,Blue,LightCyan);
               Scr.HighLightText('~Decodificar',7,5,White,Blue,LightCyan);
               Scr.HighLightText('System ~Info',7,6,White,Blue,LightCyan);
               Scr.HighLightText('Dos ~Shell',8,7,White,Blue,LightCyan);
               Scr.Center(26,8,'Ajuda');
                 For i:=1 To 3 Do Begin
                 TextBackGround(Blue);
                 Scr.Center(26,9,'     ');
                 Delay(100);
                 TextBackGround(Red);
                 Scr.Center(26,9,'Sa¡da');
                 Delay(100);
                 End;
               {Call Exit Routine}
               Exit;
               End;
    End;
  End;
M.CloseMouse;
End.