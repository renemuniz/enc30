Program EncInstall;
Uses Crt,Dos,
     HardwareTools,
     CrtControl,
     CrcControl,
     AdvancedCrtControl,
     KeyboardControl;

Type Str28=String[28];

Var Scr:Screen;
    K:Keyboard;
    OrigMode:Integer;
    Box:DataBox;
    Path:String;
    Drive,DriveReady:Boolean;
    CMOSInfo:CMOSRec;
    Status:Str12;
    DiskSpace,CRC:LongInt;
    Source,Dest:File;
    NumRead,NumWritten:Word;
    DirInfo:SearchRec;
    CRCStr:String8;
    FBuffer:Buffer;
    ReducedStr:Str28;
    TotalWritten:LongInt;

Label ReRead,Continue;

Function EntryExists(FileName:String):Boolean;Assembler;
Asm
Push Ds          {Save DS                         }
Lds  Si,Filename {DS:SI => Filename               }
XOr  Bx,Bx       {Clear BX                        }
Mov  Bl,[Si]     {BX = Length(Filename)           }
Inc  Si          {DS:SI => Filename[1]            }
Mov  Dx,Si       {DS:DX => Filename[1]            }
Mov  [Si+Bx],Bh  {Append Ascii 0 to Filename      }
Mov  Ax,4300h    {Get Attribute Function Code     }
Int  21h         {Get File Attributes             }
Mov  Al,Bh       {Set Default Result to FALSE     }
Cmc              {Toggle Carry Flag               }
Adc  Al,Al       {Change Result to TRUE if Failed }
Pop  Ds          {Restore DS                      }
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

Procedure CopyFile(SPath:String);
Begin
Assign(Source,SPath);
Assign(Dest,Path+'\$$$$$.$$');
GoToXY(1,9);
ClrEol;
TextColor(White);
Write('Arquivo Fonte: ',SPath);
TextColor(LightGreen);
GoToXY(1,10);
ClrEol;
  If Length(Path)>40 Then Begin
  ReduceStr(Path,ReducedStr);
  Write('Arquivo Destino: ',ReducedStr+'\'+SPath);
  End
    Else Begin
    Write('Arquivo Destino: ',Path+'\'+SPath);
    End;
{$I-}
Reset(Source,1);
{$I+}
  If (IOResult<>0) Then Begin
  Scr.DosReturn;
  WriteLn('Erro durante a abertura do arquivo fonte.');
  Halt(1);
  End;
{$I-}
ReWrite(Dest,1);
{$I+}
  If (IOResult<>0) Then Begin
  Scr.DosReturn;
  WriteLn('Erro durante a cria‡ao do arquivo destino.');
  Halt(1);
  End;
TotalWritten:=0;
  Repeat
  BlockRead(Source,FBuffer^,SizeOf(Buf),NumRead);
  BlockWrite(Dest,FBuffer^,NumRead,NumWritten);
  Scr.StatusBar(30,19,33,White,Blue,TotalWritten,FileSize(Source));
  Inc(TotalWritten,NumWritten);
  Until (NumRead=0) Or (NumWritten<>NumRead);
Close(Source);
Close(Dest);
{$I-}
Rename(Dest,Path+'\'+SPath);
{$I+}
  If (IOResult<>0) Then Begin
  Scr.DosReturn;
  WriteLn('O arquivo ',SPath,' j  existe no diret¢rio atual.');
  WriteLn('Execute novamente o programa escolhendo outro diret¢rio.');
  Erase(Dest);
  Halt(1);
  End;
End;

Begin
Scr.Init;
K.Init;
Scr.DosReturn;
  If Scr.IsMono Then Begin
  WriteLn('Este programa nao pode ser executado em monitores monocrom ticos.');
  Halt(1);
  End;
OrigMode:=LastMode;
TextMode(CO80);
Scr.CursorSize:=Small;
Scr.Cursor;
Scr.BackASCII(#177,Blue,LightGray);
TextBackGround(White);
ClrEol;
GoToXY(1,25);
ClrEol;
GoToXY(1,1);
TextColor(Brown);
Scr.Center(79,1,'Assistente de Instala‡ao - Encryptor V3.0');
TextBackGround(Blue);
TextColor(Yellow);
Scr.Center(81,3,'Bem vindo ao assitente de instala‡ao de Encryptor V3.0');
TextBackGround(White);
GoToXY(1,25);
TextColor(Red);
Write(' Enter ');
TextColor(Black);
Write('Confirma o Diret¢rio');
TextColor(Red);
Write('  Esc ');
TextColor(Black);
Write('Abandona a Instala‡ao');
Scr.TitleShadedWindow(6,5,74,21,White,Blue,'Diret¢rio de Instala‡ao');
TextColor(Yellow);
GoToXY(2,2);
WriteLn('Este assistente ir  lhe acompanhar durante todo o processo de ins-tala‡ao');
GoToXY(9,3);
WriteLn('do software Encryptor V3.0. Entre logo abaixo com o diret¢-rio no qual ser ');
GoToXY(18,4);
WriteLn('instalado o  programa. Se  preferir,  simplesmente ');
GoToXY(1,5);
WriteLn('pressione <Enter> para aceitar o diret¢rio padrao.');
TextColor(White);
WriteLn('Obs - Se o diret¢rio nao existir o programa ir  cri -lo.');
WriteLn('Obs2 - Nao use caracteres inv lidos como "\" no final ou ";".');
GoToXY(2,9);
Write('þ Espa‡o Requerido em Disco: 160Kb');
Box.Init;
  With Box Do Begin
  BoxColor:=Black;
  BoxTextColor:=White;
  X1:=15;
  Y1:=12;
  X2:=50;
  ArrowColor:=(LightGreen+Blink);
  BoxText:='C:\Enc30';
  End;
ReRead:
Scr.CursorSize:=Normal;
Scr.Cursor;
GoToXY(2,12);
TextBackGround(Blue);
TextColor(LightGreen);
Write('þ Diret¢rio: ');
Box.OpenDataBox;
  If (Box.ExitMode=CancelExit) Then Begin
  TextMode(OrigMode);
  Scr.DosReturn;
  WriteLn('Instala‡ao cancelada pelo usu rio.');
  Exit;
  End;
Path:=Box.BoxText;
  If (Pos(':\',Path)<>0) Then Begin {Drive Path Selected}
  Drive:=DriveValid(UpCase(Path[1]));
    If Not Drive Then Begin {Drive is not valid}
    Scr.SaveScreen;
    MessageBox(22,9,58,16,'Erro','Este Drive nao ‚ v lido.');
    Box.BoxText:='';
    Scr.RestoreScreen;
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
            Scr.SaveScreen;
            MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
            Scr.RestoreScreen;
            Box.BoxText:='';
            GoTo ReRead;
            End;
              If (UpCase(Path[1])='B') And (CMOSInfo.FloppyB<>'None') Then Begin
              TestFloppy(UpCase(Path[1]),DriveReady,Status);
              GoTo Continue;
              End
                Else Begin
                Scr.SaveScreen;
                MessageBox(22,9,58,16,'Erro','Drive de disquete inv lido.');
                Box.BoxText:='';
                Scr.RestoreScreen;
                GoTo ReRead;
                End;
        Continue:
          If Not DriveReady Then Begin
          Scr.SaveScreen;
          MessageBox(22,9,58,16,'Erro','Drive de disquete nao pronto.');
          Box.BoxText:='';
          Scr.RestoreScreen;
          GoTo ReRead;
          End;
        End
          Else If (Ord(UpCase(Path[1]))-65 = FirstCD) Then Begin
          Scr.SaveScreen;
          MessageBox(22,9,58,16,'Erro',' Nao ‚ poss¡vel instalar em drives de CD-ROM.');
          Box.BoxText:='';
          Scr.RestoreScreen;
          GoTo ReRead;
          End;
      DiskSpace:=DiskFree(Ord(UpCase(Path[1]))-64);
        If (DiskSpace<160000) Then Begin
        Scr.SaveScreen;
        MessageBox(22,9,58,16,'Erro',' Nao h  espa‡o suficiente em disco para instalar o programa.');
        Box.BoxText:='';
        Scr.RestoreScreen;
        GoTo ReRead;
        End
      End; {Finish Drives test}
  End
    Else Begin
      If (Box.ExitMode=NormalExit) Or (Box.ExitMode=TabExit) Then Begin
      Scr.SaveScreen;
      MessageBox(22,9,58,16,'Erro','Caminho inv lido. Vocˆ tem que especificar um drive!');
      Box.BoxText:='';
      Scr.RestoreScreen;
      GoTo ReRead;
      End;
    End;

  If Not EntryExists(Path) Then Begin
  {$I-}
  MkDir(Path); {Try to create the directory}
  {$I+}
    If IOResult<>0 Then Begin
    Scr.SaveScreen;
    MessageBox(22,9,58,16,'Erro',
    ' Nao foi poss¡vel criar o diret¢rioneste drive. Veja se o disco nao est cheio ou protegido contra grava‡ao.');
    Box.BoxText:='';
    Scr.RestoreScreen;
    GoTo ReRead;
    End;
  End;
Scr.DosReturn;
Scr.OpenWindow(22,11,57,12,White,Magenta);
Write('  Preparando para instalar por favoraguarde...');
{Search File Enc30.Exe}
FindFirst('Enc30.Exe',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Enc30.Exe');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'063FDC19') Then Begin  {Look for the CRC Enc30.Exe}
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Enc30.Exe foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File TestEnc.Exe}
FindFirst('TestEnc.Exe',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'TestEnc.Exe');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'F8F01862') Then Begin  {Look for the CRC Enc30.Exe}
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo TestEnc.Exe foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Main.Ehf}
FindFirst('Main.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Main.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'A01B8E1F') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Main.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp1.Ehf}
FindFirst('Hlp1.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp1.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'E3F7E76A') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp1.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp2.Ehf}
FindFirst('Hlp2.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp2.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'F65B7672') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp2.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp3.Ehf}
FindFirst('Hlp3.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp3.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'D1F534CB') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp3.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp4.Ehf}
FindFirst('Hlp4.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp4.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'31E96679') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp4.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp5.Ehf}
FindFirst('Hlp5.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp5.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'291704DB') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp5.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File Hlp6.Ehf}
FindFirst('Hlp6.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'Hlp6.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'4F06B011') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo Hlp6.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Search File InfG.Ehf}
FindFirst('InfG.Ehf',Archive,DirInfo);
  If (DirInfo.Name='') Or (DosError<>0) Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'Nao foi poss¡vel encontrar os componentes necess rios para a instala‡ao do programa no diret¢rio atual.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
Assign(Source,'InfG.Ehf');
{Check the CRC}
EvaluateCRC(Source,CRC);
LongToHex(CRC,CRCStr); {Put the original CRC here}
  If (CRCStr<>'C127D755') Then Begin
  Scr.GoXY(1,1);
  Scr.BackASCII(#177,Blue,LightGray);
  MessageBox(22,9,58,16,'Erro',
  'O arquivo InfG.Ehf foi modificado.Nao ‚ poss¡vel prosseguir com a instala‡ao.');
  Scr.DosReturn;
  Write('Erro durante a instala‡ao');
  Exit;
  End;
{Ok Prepare to copy the files}
  If (MaxAvail<SizeOf(Buf)) Then Begin
  Scr.DosReturn;
  WriteLn('Nao h  mem¢ria suficiente para prosseguir a instala‡ao.');
  Halt(1);
  End;
New(FBuffer);
Window(1,1,80,25);
Scr.Back(Blue);
TextColor(LightCyan);
GoToXY(1,2);
Writeln('    Assistente de Instala‡ao Encryptor V3.0 ');
GoToXY(5,3);
Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
GoToXY(5,23);
Write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
Window(5,4,75,22);
TextColor(White);
GoToXY(1,1);
Write(' O assistente de instala‡ao est  agora copiando os arquivos do programa');
GoToXY(1,2);
Write('para o diret¢rio que vocˆ escolheu. Por favor aguarde.');
GoToXY(1,5);
TextColor(Yellow);
Write('Status: Copiando os arquivos do programa');
{Copy Enc30.Exe}
UpperStr(Path);
CopyFile('ENC30.EXE');
CopyFile('TESTENC.EXE');
GoToXY(1,5);
TextColor(Yellow);
ClrEol;
Write('Status: Copiando os arquivos de ajuda');
{Copy Help Files}
CopyFile('MAIN.EHF');
CopyFile('HLP1.EHF');
CopyFile('HLP2.EHF');
CopyFile('HLP3.EHF');
CopyFile('HLP4.EHF');
CopyFile('HLP5.EHF');
CopyFile('HLP6.EHF');
CopyFile('INFG.EHF');
Window(1,1,80,25);
Scr.SetBlink(True);
TextBackGround(Blue);
TextColor(LightGreen);
K.ClearKbdBuf;
Scr.ScrollTextLine(13,71,24,'Conclu¡do.Pressione qualquer tecla para continuar...');
Dispose(FBuffer);
Scr.DosReturn;
WriteLn('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
WriteLn('º                   **  Instala‡ao Conclu¡da com ˆxito!  **                   º');
WriteLn('º                                                                             º');
WriteLn('º * Para iniciar Encryptor V3.0 digite ENC30 no prompt do MS-DOS              º');
WriteLn('º                                                                             º');
WriteLn('º  Este programa foi escrito por Rene M.Corrˆa Muniz especialmente para a par-º');
WriteLn('ºticipacao no concurso nacional de softwares 1998 do minist‚rio da educacao e º');
WriteLn('ºdo desporto MEC.                                                             º');
WriteLn('º                                                                             º');
WriteLn('º * Categoria Participante: Geral                                             º');
WriteLn('º * Data: 15/07/1998                                                          º');
WriteLn('ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
WriteLn;
ChDir(Path);
End.