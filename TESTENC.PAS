Program TestEnc;
Uses Crt,Dos,
     CRTControl,
     StopHack,
     CRCControl;
Var Scr:Screen;
    DirInfo:SearchRec;
    EncFile:File;
    CRC:LongInt;
    CRCStr:String8;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'TestEnc (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

Begin
Copyright;
Scr.DosReturn;
Scr.OpenSimpleWindow(2,2,78,4,White,Blue);
TextColor(Yellow);
Scr.Center(79,1,'* Encryptor CRC Test V1.0 *');
TextColor(White);
Scr.Center(79,2,'Prevent Hacking and Virus Infections');
Scr.Center(79,3,'Programado para uso com Encryptor V3.0 ออ 29/07/1998');
Window(1,1,80,25);
Scr.CursorSize:=Normal;
Scr.Cursor;
TextColor(LightGray);
TextBackGround(Black);
GoToXY(1,7);
FindFirst ('Enc30.Exe',Archive,DirInfo);
  If (DirInfo.Name='') Then Begin
  WriteLn('þ Erro - Arquivo Enc30.Exe nao encontrado.');
  WriteLn;
  Halt(1);
  End;
WriteLn('þ Testando Enc30.Exe...');
WriteLn;
Assign(EncFile,'Enc30.Exe');
{$I-}
Reset(EncFile,1);
{$I+}
  If IOResult<>0 Then Begin
  WriteLn('þ Erro - Erro ao abrir Enc30.Exe.');
  Halt(1);
  End
    Else Begin
    Close(EncFile);
    End;
EvaluateCRC(EncFile,CRC);
LongToHex(CRC,CRCStr);
  If (CRCStr<>'063FDC19') Then Begin
  WriteLn('þ Erro de CRC - Arquivo Enc30.Exe foi modificado.');
  WriteLn;
  End
    Else Begin
    WriteLn('þ OK - Arquivo Enc30.Exe confere CRC.');
    WriteLn;
    End;
End.