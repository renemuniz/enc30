Unit EncryptControl;   {Encrypt-Decrypt Procedures}

Interface

Type Buf = Array [1..4096] Of Byte; {4Kb Buffer}
     Buffer = ^Buf;

     Status=Record
     X,Y,Len:Byte;
     Color,Back:Byte;
     Tot:Real;
     End;

Const StartK = 981;        {Start default key}
      MultKey = 12674;     {Mult default key}
      AddKey = 35891;      {Add default key}

{32 Bit}
Procedure Encrypt(Var FileIn,FileOut:File;StartKey:Integer;Const CStat:Status);
Procedure Decrypt(Var FileIn,FileOut:File;StartKey:Integer;Const CStat:Status;Const Size:Real;Const First:Boolean);
Procedure GenerateSeeds(Password:String;Var Seed1,Seed2:Word);
Procedure Encode(Var FileIn,FileOut:File;Seed1,Seed2:Word;Const CStat:Status;Const Size:Real);
Procedure Decode(Var FileIn,FileOut:File;Seed1,Seed2:Word;Const CStat:Status;Const Size:Real;Const First:Boolean);
Procedure XOrEncode(Var FileIn,FileOut:File;Seed:Word;Const CStat:Status;Const Size:Real;Const Enc:Boolean);

Implementation
Uses CrtControl;
Var Scr:Screen;

Procedure Copyright;Near;Assembler;
Asm
Jmp @@1
Db 13,10,'EncryptControl Unit (C)1998 by Rene M.C.Muniz  All rights reserved.',13,10
@@1:
End;

{Use StartKey=SEED1*SEED2}
Procedure Encrypt(Var FileIn,FileOut:File;StartKey:Integer;Const CStat:Status);
Var BufIn:Buffer;
    RecordsRead,RecordsWrite,i:Word;
    BytesRead:Real;
Begin
BytesRead:=0;
Reset(FileIn,1);
Reset(FileOut,1);
Seek(FileOut,FileSize(FileOut));
New(BufIn);
  Repeat
  BlockRead(FileIn,BufIn^,SizeOf(BufIn^),RecordsRead);
  Scr.StatusBar(CStat.X,CStat.Y,CStat.Len,CStat.Color,CStat.Back,BytesRead,CStat.Tot);
    For i:=1 To RecordsRead Do Begin
    BufIn^[i]:=BufIn^[i] XOr (StartKey Shr 8);
    StartKey:=(BufIn^[i]+StartKey)*MultKey+AddKey;
    End;
  BytesRead:=BytesRead+RecordsRead;
  BlockWrite(FileOut,BufIn^,RecordsRead,RecordsWrite);
  Until (RecordsRead=0) Or (RecordsRead<>RecordsWrite);
Dispose(BufIn);
Close(FileIn);
Close(FileOut);
End;

Procedure Decrypt(Var FileIn,FileOut:File;StartKey:Integer;Const CStat:Status;Const Size:Real;Const First:Boolean);
Var BufIn:Buffer;
    RecordsRead,RecordsWrite,i:Word;
    Temp:Byte;
    BytesRead:Real;
Begin
BytesRead:=(2*Size);
  If Not First Then Begin
  Reset(FileIn,1);
  End;
ReWrite(FileOut,1);
New(BufIn);
  Repeat
  BlockRead(FileIn,BufIn^,SizeOf(BufIn^),RecordsRead);
  Scr.StatusBar(CStat.X,CStat.Y,CStat.Len,CStat.Color,CStat.Back,BytesRead,CStat.Tot);
    For i:=1 To RecordsRead Do Begin
    Temp:=BufIn^[i];
    BufIn^[i]:=BufIn^[i] XOr (StartKey Shr 8);
    StartKey:=(Temp+StartKey)*MultKey+AddKey;
    End;
  BytesRead:=BytesRead+RecordsRead;
  BlockWrite(FileOut,BufIn^,RecordsRead,RecordsWrite);
  Until (RecordsRead=0) Or (RecordsRead<>RecordsWrite);
Dispose(BufIn);
Close(FileIn);
Close(FileOut);
End;

Procedure GenerateSeeds(Password:String;Var Seed1,Seed2:Word);
Var i,j:Byte;
Begin
Seed1:=0;        {Generate the seeds}
Seed2:=0;
j:=Length(Password);
  For i:=1 To Length(Password) Do Begin
  Seed1:=Seed1+(Ord(Password[i])*i);
  Seed2:=Seed2+(Ord(Password[i])*j);
  Dec(j,1);
  End;
End;

Procedure Encode(Var FileIn,FileOut:File;Seed1,Seed2:Word;Const CStat:Status;Const Size:Real);
Var BufIn:Buffer;
    i,i1,i2,RecordsRead,RecordsWrite:Word;
    BytesRead:Real;
Begin
BytesRead:=Size;
i1:=Seed1;
i2:=Seed2;
New(BufIn);
Reset(FileIn,1);
Reset(FileOut,1);
Seek(FileOut,FileSize(FileOut));
  Repeat
  BlockRead(FileIn,BufIn^,SizeOf(BufIn^),RecordsRead);
  Scr.StatusBar(CStat.X,CStat.Y,CStat.Len,CStat.Color,CStat.Back,BytesRead,CStat.Tot);
    For i:=1 To RecordsRead Do Begin
    Dec(i1);
    Inc(i2);
      If Odd(i) Then Begin
      BufIn^[i]:=(BufIn^[i]-i1);
      End
        Else Begin
        BufIn^[i]:=(BufIn^[i]+i2);
        End;
    End;
  BytesRead:=BytesRead+RecordsRead;
  BlockWrite(FileOut,BufIn^,RecordsRead,RecordsWrite);
  Until (RecordsRead=0) Or (RecordsRead<>RecordsWrite);
Dispose(BufIn);
Close(FileIn);
Close(FileOut);
End;

Procedure Decode(Var FileIn,FileOut:File;Seed1,Seed2:Word;Const CStat:Status;Const Size:Real;Const First:Boolean);
Var BufIn:Buffer;
    i,i1,i2,RecordsRead,RecordsWrite:Word;
    BytesRead:Real;
Begin
BytesRead:=Size;
i1:=Seed1;
i2:=Seed2;
New(BufIn);
  If Not First Then Begin
  Reset(FileIn,1);
  End;
ReWrite(FileOut,1);
  Repeat
  BlockRead(FileIn,BufIn^,SizeOf(BufIn^),RecordsRead);
  Scr.StatusBar(CStat.X,CStat.Y,CStat.Len,CStat.Color,CStat.Back,BytesRead,CStat.Tot);
    For i:=1 To RecordsRead Do Begin
    Dec(i1);
    Inc(i2);
      If Odd(i) Then Begin
      BufIn^[i]:=(BufIn^[i]+i1);
      End
        Else Begin
        BufIn^[i]:=(BufIn^[i]-i2);
        End;
    End;
  BytesRead:=BytesRead+RecordsRead;
  BlockWrite(FileOut,BufIn^,RecordsRead,RecordsWrite);
  Until (RecordsRead=0) Or (RecordsRead<>RecordsWrite);
Dispose(BufIn);
Close(FileIn);
Close(FileOut);
End;

{USE SEED=SEED1+SEED2}
Procedure XOrEncode(Var FileIn,FileOut:File;Seed:Word;Const CStat:Status;Const Size:Real;Const Enc:Boolean);
Var BufIn:Buffer;
    i,RecordsRead,RecordsWrite:Word;
    BytesRead:Real;
Begin
BytesRead:=(2*Size);
RandSeed:=Seed;
New(BufIn);
  If Enc Then Begin
  Reset(FileIn,1);
  Reset(FileOut,1);
  Seek(FileOut,FileSize(FileOut));
  End;
  Repeat
  BlockRead(FileIn,BufIn^,SizeOf(BufIn^),RecordsRead);
  Scr.StatusBar(CStat.X,CStat.Y,CStat.Len,CStat.Color,CStat.Back,BytesRead,CStat.Tot);
    For i:=1 To RecordsRead Do Begin
    BufIn^[i]:=(BufIn^[i] XOr Random(256));
    End;
  BytesRead:=BytesRead+RecordsRead;
  BlockWrite(FileOut,BufIn^,RecordsRead,RecordsWrite);
  Until (RecordsRead=0) Or (RecordsRead<>RecordsWrite);
Dispose(BufIn);
Close(FileIn);
Close(FileOut);
End;

Begin
CopyRight;
End.




