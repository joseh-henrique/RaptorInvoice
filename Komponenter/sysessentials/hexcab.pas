  unit hexcab;

  interface

  Uses Forms, Windows, SysUtils, Classes, contnrs, Dialogs,
  hexbase;

  {$A-}

  Const

  ERR_TYPEERROR               = 'Storage file format not recognized';
  ERR_StreamNotFound          = 'Stream not found error';
  ERR_WrongEncodingKey        = 'Encoding key is wrong error';
  ERR_ReadHeader              = 'Failed to read cabinet header error';
  ERR_ReadFileHeader          = 'Failed to read stream header error';
  ERR_Accumulate              = 'Failed to accumulate stored streams error';
  ERR_AddFileItem             = 'Failed to add accumulated stored stream to internal collection error';
  ERR_SeekWriteHeader         = 'Failed to seek BOF, unable to write header data error';
  ERR_WriteHeader             = 'Failed to write header data error';
  ERR_WriteFileHeader         = 'Failed to write stream header error';
  ERR_WriteFileContent        = 'Failed to write stream content error';
  ERR_AllocTempMemory         = 'Failed to allocate temporary memory buffer error';
  ERR_FillTempMemory          = 'Failed to populate temporary memory buffer error';
  ERR_DeleteFile              = 'Failed to remove old cabinet file, file can be protected or in use error';
  ERR_FileExt                 = 'Failed to output stream content to file error';
  ERR_SourceFileMissing       = 'Failed to locate input file error';
  ERR_StreamExists            = 'A stream with that name exists in cabinet error';
  ERR_MoveData                = 'Failed to move data, file is corrupt error';
  ERR_NewSourceAlreadyExists  = 'A stream with the new name already exists error';
  ERR_StreamNotExist          = 'A stream with that name does not exist error';
  ERR_FailedSeekFile          = 'Failed to seek to file position error';
  ERR_StreamNIL               = 'Stream is NIL error';
  ERR_FailedCreateFile        = 'Failed to create file: %s';

  Type
  TEncryptionBeginsEvent    = Procedure (Sender:TObject;Max:Integer) of Object;
  TEncryptionProgressEvent  = Procedure (Sender:TObject;Position,Max:Integer) of Object;
  TEncryptionEndsEvent      = Procedure (Sender:TObject;Max:Integer) of Object;
  TStreamDeletedEvent       = Procedure (Sender:TObject;Source:String) of Object;
  TStreamAddedEvent         = Procedure (Sender:TObject;Source:String) of Object;
  TCompactingBeginsEvent    = Procedure (Sender:TObject;Max:Integer) of Object;
  TCompactingProgressEvent  = Procedure (Sender:TObject;Position,Max:Integer) of Object;
  TCompactingEndsEvent      = Procedure (Sender:TObject;Max:Integer) of Object;
  TCabinetOpenEvent         = Procedure (Sender:TObject;Source:String) of Object;
  TCabinetCloseEvent        = Procedure (Sender:TObject;Source:String) of Object;
  TValidateCabIdentEvent    = Procedure (Sender:TObject;Identifier:Integer;var Accept:Boolean) of Object;

  Type
  THexCustomCabinet = Class;
  THexCabinet       = Class;
  EHexCabinet       = Class(Exception);
  EHexStoredFile    = Class(Exception);
  THexCabinetState  = (ssOpen,ssClosed);

  TCabinetHeader = Record
    MAGIC:        Cardinal;
    KIND:         Cardinal;
    FILES:        Integer;
    FILEKEY:      ShortString;
    Title:        String[48];
    Information:  ShortString;
  end;

  TFileHeader = Record
    MAGIC:    Cardinal;
    FILESIZE: Integer;
    FileName: ShortString;
  end;

  THexCabOptions = set of (coPassDialog,coIdentCheck,coExclusive);

  THexStoredFile = Class(TObject)
  private
    FParent:    THexCustomCabinet;
    FSize:      Integer;
    FOffset:    Integer;
    FName:      String;
  Public
    Constructor Create(AOwner:THexCustomCabinet);
  Published
    Property    ByteSize:Integer read FSize write FSize;
    Property    BytePos:Integer read FOffset write FOffset;
    Property    Filename:String read FName write FName;
  End;

  THexCustomCabinet = Class(THexCustomComponent)
  Private
    FObjects:           TObjectList;
    FEncodingKey:       String;
    FOptions:           THexCabOptions;

    FOnEncryptBegins:   TEncryptionBeginsEvent;
    FOnEncryptProgress: TEncryptionProgressEvent;
    FOnEncryptEnds:     TEncryptionEndsEvent;
    FOnCompactBegins:   TCompactingBeginsEvent;
    FOnCompactProgress: TCompactingProgressEvent;
    FOnCompactEnds:     TCompactingEndsEvent;
    FOnDelete:          TStreamDeletedEvent;
    FOnClose:           TCabinetCloseEvent;
    FOnOpen:            TCabinetOpenEvent;
    FOnAdd:             TStreamAddedEvent;
    FOnValidate:        TValidateCabIdentEvent;

    Function    GetCount:Integer;
    Function    GetItem(Index:Integer):THexStoredFile;
  Protected
    procedure   SetIdentifier(Value:Cardinal);Virtual;abstract;
    Procedure   SetTitle(Value:String);Virtual;abstract;
    Procedure   SetInfo(value:String);Virtual;abstract;
    Function    GetTitle:String;Virtual;abstract;
    Function    GetInfo:String;Virtual;abstract;
    Function    GetIdentifier:Cardinal;Virtual;abstract;

    Property    EncodingKey:String read FEncodingKey write FEncodingKey;
    Function    RC4EncodeDecodeString(Var Source,key:String):String;
    Procedure   EncryptStream(Stream:TStream);
    Function    GetDataSource:String;Virtual;abstract;
    Function    GetSize:Integer;Virtual;abstract;
    Function    GetState:THexCabinetState;Virtual;abstract;
    Function    GetEncryption:Boolean;Virtual;abstract;
  Public
    Property    CabOptions: THexCabOptions read FOptions write FOptions;
    Property    CabTitle:String read GetTitle write SetTitle;
    Property    CabInfo:String read GetInfo write SetInfo;
    Property    CabSource:String read GetDataSource;
    Property    CabSize:Integer read GetSize;
    Property    CabState:THexCabinetState read GetState;
    Property    Encrypted:Boolean read GetEncryption;
    Property    Items[index:Integer]:THexStoredFile read GetItem;default;
    Property    Count:Integer read GetCount;

    Procedure   StoreStream(Token:String;Stream:TStream);virtual;abstract;
    Procedure   StoreFile(Filename:String);virtual;abstract;
    Procedure   DeleteStream(Token:String);virtual;abstract;
    Procedure   ReplaceStream(Token:String;Stream:TStream);virtual;abstract;
    Procedure   RenameStream(Token,NewToken:String);virtual;abstract;
    Function    IndexOf(Token:String):Integer;

    Procedure   ExtractToFile(Token:String;Const Filename:String);virtual;abstract;
    Procedure   ExtractToStream(Token:String;Stream:TStream);virtual;abstract;

    Function    StreamExists(Token:String):Boolean;virtual;abstract;
    Function    Dir(AFileExt:String):TStringList;virtual;abstract;
    Function    StreamSize(Token:String):Integer;virtual;abstract;
    function    LoadStream(Token:String):TMemoryStream;virtual;abstract;

    Procedure   Open(Source,EncKey:String);virtual;abstract;
    Procedure   Close;virtual;abstract;

    Procedure   New(Source:String;EncKey:String);virtual;abstract;

    Constructor Create(AOwner:TComponent);Override;
    Destructor  Destroy;Override;
  Published
    Property    Identifier:Cardinal read GetIdentifier write SetIdentifier;
    Property    OnEncryptionBegins: TEncryptionBeginsEvent read FOnEncryptBegins write FOnEncryptBegins;
    Property    OnEncryptionProgress: TEncryptionProgressEvent read FOnEncryptProgress write FOnEncryptProgress;
    Property    OnEncryptionEnds:TEncryptionEndsEvent read FOnEncryptEnds write FOnEncryptEnds;
    Property    OnStreamDeleted:TStreamDeletedEvent read FOnDelete write FOnDelete;
    Property    OnStreamAdded: TStreamAddedEvent read FOnAdd write FOnAdd;
    Property    OnCompactingBegins: TCompactingBeginsEvent read FOnCompactBegins write FOnCompactBegins;
    Property    OnCompactingProgress:TCompactingProgressEvent read FOnCompactProgress write FOnCompactProgress;
    Property    OnCompactingEnds:TCompactingEndsEvent read FOnCompactEnds write FOnCompactEnds;
    Property    OnCabinetOpen:TCabinetOpenEvent read FOnOpen write FOnOpen;
    Property    OnCabinetClosed:TCabinetCloseEvent read FOnClose write FOnClose;
    Property    OnValidateIdentifier: TValidateCabIdentEvent read FOnValidate write FOnValidate;
  End;

  THexCabinet=Class(THexCustomCabinet)
  private
    FState:       THexCabinetState;
    FDisk:        TFileStream;
    Fheader:      TCabinetHeader;
    FFilename:    String;

    FIdentifier:  Cardinal;
    FTitle:       String;
    FInformation: String;

    Procedure   ReadHeader;
    Procedure   WriteHeader;
    Procedure   AccumulateItems;
  Protected
    procedure   SetIdentifier(Value:Cardinal);override;
    Procedure   SetTitle(Value:String);override;
    Procedure   SetInfo(value:String);override;
    Function    GetTitle:String;override;
    Function    GetInfo:String;override;
    Function    GetIdentifier:Cardinal;override;

    Function    GetEncryption:Boolean;override;
    Function    GetSize:Integer;override;
    Function    GetDataSource:String;override;
    Function    GetState:THexCabinetState;override;
  Public
    Procedure   StoreStream(Token:String;Stream:TStream);override;
    Procedure   StoreFile(Filename:String);override;
    Procedure   DeleteStream(Token:String);override;
    Procedure   ExtractToFile(Token:String;Const Filename:String);override;
    Procedure   ExtractToStream(Token:String;Stream:TStream);override;
    Procedure   ReplaceStream(Token:String;Stream:TStream);override;
    Function    StreamExists(Token:String):Boolean;override;
    Function    Dir(AFileExt:String):TStringList;override;
    Function    StreamSize(Token:String):Integer;override;
    Procedure   RenameStream(Token,NewToken:String);override;
    Procedure   Open(Source,EncKey:String);override;
    Procedure   Close;override;
    function    LoadStream(Token:String):TMemoryStream;override;
    Procedure   New(Source:String;EncKey:String);override;
    Procedure   BeforeDestruction;Override;
    Constructor Create(AOwner:TComponent);override;
  Published
    Property    CabTitle;
    Property    CabInfo;
    Property    CabOptions;
  End;

  Implementation

  Const
  DISK_MAGIC                  = $CAFEBABE;
  FILE_MAGIC                  = $BABECAFE;
  FILE_CHUNK                  = 1024*4;
  GLOBAL_KEY                  = 'heruherusofnatpanea';
  
  //##########################################################
  // THexCustomCabinet
  //##########################################################

  Constructor THexCustomCabinet.Create(AOwner:TComponent);
  Begin
    inherited Create(AOwner);
    FObjects:=TObjectList.Create(TRUE);
    FOptions:=[coPassDialog,coIdentCheck,coExclusive];
  end;

  Destructor THexCustomCabinet.Destroy;
  Begin
    FObjects.free;
    Inherited;
  end;

  Function THexCustomCabinet.GetCount:Integer;
  Begin
    result:=FObjects.Count;
  end;

  Function THexCustomCabinet.GetItem(Index:Integer):THexStoredFile;
  Begin
    result:=THexStoredFile(FObjects[index]);
  end;

  Procedure THexCustomCabinet.EncryptStream(Stream:TStream);
  var
    x:      Integer;
    FStep:  Integer;
    FCounter: Integer;

    S: Array[0..255] of Byte;
    K: Array[0..255] of byte;

    I,J,T:Integer;
    Temp,Y:Byte;

    Procedure BuildTables;
    var
      FItem,JX:Integer;
      FTemp:Byte;
    Begin
      for FItem:=0 to 255 do
      s[FItem]:=FItem;

      JX:=1;
      for FItem:=0 to 255 do
      begin
        if JX>length(FEncodingKey) then
        JX:=1;
        k[FItem]:=Byte(FEncodingKey[JX]);
        inc(JX);
      end;

      JX:=0;
      For FItem:=0 to 255 do
      begin
        JX:=(JX+s[FItem] + k[FItem]) mod 256;
        FTemp:=s[FItem];
        s[FItem]:=s[JX];
        s[JX]:=FTemp;
      end;
    End;

  Begin
    Stream.Seek(0,0);

    If assigned(FOnEncryptBegins) then
    FOnEncryptBegins(self,Stream.Size);

    FStep:=(Stream.Size div 10);
    if FStep>100 then
    FStep:=(Stream.Size div 20);

    FCounter:=0;

    i:=0;
    j:=0;
    BuildTables;

    for x:=0 to Stream.Size-1 do
    begin

      inc(FCounter);
      if FCounter>FStep then
      begin
        if assigned(FOnEncryptProgress) then
        FOnEncryptProgress(self,x,Stream.Size);
        FCounter:=0;
      end;

      { Figure out where in the table to work }
      i:=(i+1) mod 256;
      j:=(j+s[i]) mod 256;
      temp:=s[i];
      s[i]:=s[j];
      s[j]:=temp;
      t:=(s[i] + (s[j] mod 256)) mod 256;
      y:=s[t];

      Stream.Read(Temp,1);
      stream.Seek(stream.position-1,0);
      Temp:=(Temp xor y);
      Stream.write(Temp,1);
    end;

    stream.seek(0,0);

    if assigned(FOnEncryptEnds) then
    FOnEncryptEnds(self,Stream.Size);
  End;

  Function THexCustomCabinet.RC4EncodeDecodeString(Var Source,key:String):String;
  var
    S: Array[0..255] of Byte;
    K: Array[0..255] of byte;
    Temp,y:Byte;
    I,J,T,X:Integer;
    target:String;
  Begin
    for i:=0 to 255 do
    s[i]:=i;

    J:=1;
    for I:=0 to 255 do
    begin
      if j>length(key) then j:=1;
      k[i]:=byte(key[j]);
      inc(j);
    end;

    J:=0;
    For i:=0 to 255 do
    begin
      j:=(j+s[i] + k[i]) mod 256;
      temp:=s[i];
      s[i]:=s[j];
      s[j]:=Temp;
    end;

    i:=0;
    j:=0;
    for x:=1 to length(source) do
    begin
      i:=(i+1) mod 256;
      j:=(j+s[i]) mod 256;
      temp:=s[i];
      s[i]:=s[j];
      s[j]:=temp;
      t:=(s[i] + (s[j] mod 256)) mod 256;
      y:=s[t];
      target:=target + char(byte(source[x]) xor y);
    end;
    result:=Target;
  End;

  Function THexCustomCabinet.IndexOf(Token:String):Integer;
  var
    x:  Integer;
  Begin
    result:=-1;

    { Check that we can do this }
    if (CabState<>ssOpen) then
    exit;

    Token:=Lowercase(Token);

    for x:=1 to FObjects.Count do
    begin
      if Items[x-1].Filename=Token then
      begin
        result:=x-1;
        break;
      end;
    end;
  End;

  //##########################################################
  // THexCabinet
  //##########################################################

  Constructor THexCabinet.Create(AOwner:TComponent);
  Begin
    inherited Create(AOwner);
    FState:=ssClosed;
    FIdentifier:=1200;
    Fheader.Title:='My cab';
    FHeader.Information:='Copyright HexMonks';
  End;

  Procedure THexCabinet.BeforeDestruction;
  Begin
    Inherited;
    if FState<>ssClosed then
    Close;
  End;

  Function THexCabinet.GetTitle:String;
  Begin
    result:=FHeader.title;
  End;

  Function THexCabinet.GetInfo:String;
  Begin
    result:=Fheader.Information;
  End;

  Function THexCabinet.GetState:THexCabinetState;
  Begin
    result:=FState;
  end;

  Function THexCabinet.GetIdentifier:Longword;
  Begin
    result:=FIdentifier;
  End;

  Function THexCabinet.GetDataSource:String;
  Begin
    result:=FFilename;
  end;

  procedure THexCabinet.SetIdentifier(Value:Longword);
  Begin
    If Value<>FIdentifier then
    begin
      FIdentifier:=Value;
      If FState=ssOpen then
      Begin
        FHeader.KIND:=Value;

        try
          WriteHeader;
        except
          on exception do
          Raise;
        end;

      end;
    end;
  End;

  Procedure THexCabinet.SetTitle(Value:String);
  Begin
    If Value<>FTitle then
    begin
      FTitle:=Value;
      If FState=ssOpen then
      Begin
        FHeader.Title:=Value;

        try
          WriteHeader;
        except
          on exception do
          raise;
        end;

      end;
    end;
  end;

  Procedure THexCabinet.SetInfo(value:String);
  Begin
    If Value<>FInformation then
    begin
      FInformation:=Value;
      If FState=ssOpen then
      Begin
        FHeader.Information:=Value;

        try
          WriteHeader;
        except
          on exception do
          raise;
        end;

      end;
    end;
  end;

  Procedure THexCabinet.New(Source:String;EncKey:String);
  var
    FPassWord:    String;
    FPrivateKey:  String;
  Begin
    { make sure active cab is closed }
    if (FState<>ssClosed) then
    Close;

    { Attempt to delete file if it already exists }
    if FileExists(source) then
    begin
      try
        DeleteFile(Source);
      except
        Raise EHexCabinet.Create(ERR_DeleteFile);
      end;
    end;

    { Encode the password if encKey defined }
    FPassword:='';
    If Length(trim(EncKey))>0 then
    begin
      FPrivateKey:=GLOBAL_KEY;
      FPassWord:=trim(EncKey);
      FPassword:=RC4EncodeDecodeString(FPassword,FPrivateKey);
      FEncodingKey:=EncKey;
    end;

    { Fill in the file header }
    FHeader.MAGIC:=DISK_MAGIC;
    FHeader.KIND:=FIdentifier;
    FHeader.FILES:=0;
    FHeader.Title:=FTitle;
    FHeader.Information:=FInformation;
    FHeader.FILEKEY:=FPassword;

    { Attempt to create the file }
    try
      FDisk:=TFileStream.Create(Source,fmCreate or fmShareExclusive);
    except
      on e: exception do
      raise EHexCabinet.Createfmt(ERR_FailedCreateFile,[e.message]);
    end;

    { Write the header }
    try
      WriteHeader;
    except
      on exception do
      raise;
    end;

    { Declare elvis-wille for opened }
    FState:=ssOpen;
    FFilename:=Source;

    { Notify the world of elvis's return.. }
    if assigned(FOnOpen) then
    FOnOpen(self,source);
  End;

  Procedure THexCabinet.Open(Source,EncKey:String);
  var
    FPassWord:    String;
    FPrivateKey:  String;
    FOK:          Boolean;
    FMode:        Integer;
  label
    DoLogin_;
  Begin
    { make sure the cab is closed }
    If (FState<>ssClosed) then
    Close;

    { Check that the file exists }
    If not FileExists(Source) then
    Raise EHexFileNotFound.CreateFmt(ERR_Hex_FileNotFound,[Source]);

    { open the file exclusively? }
    FMode:=fmOpenReadWrite;
    if (coExclusive in CabOptions) then
    Fmode:=FMode + fmShareExclusive;

    { Attempt to open the file }
    try
      FDisk:=TFileStream.Create(Source,FMode);
    except
      on e: exception do
      Raise EHEXInternalError.CreateFmt(ERR_HEX_InternalError,[e.message]);
    end;

    { Read the header }
    try
      ReadHeader;
    except
      FDisk.free;
      Raise;
    end;

    { Verify identifier }
    if (coIdentCheck in CabOptions) then
    Begin
      If assigned(OnValidateIdentifier) then
      Begin
        FOK:=True;
        OnValidateIdentifier(self,FHeader.KIND,FOK);
        { not valid, just exit, the caller knows this by now }
        If not FOK then
        Begin
          FDisk.free;
          exit;
        end;
      end;
    end;

    { Verify encoding if present }
    if length(FHeader.FILEKEY)>0 then
    begin
      FPrivateKey:=GLOBAL_KEY;
      FPassword:=Fheader.FileKey;
      FPassword:=RC4EncodeDecodeString(FPassword,FPrivateKey);

      If FPassword<>EncKey then
      begin
        { use dialog? }
        If (coPassDialog in CabOptions) then
        Begin
          DoLogin_:
          FPassword:=Inputbox('Password protected','Please input password','');
          If FPassword<>EncKey then
          Begin
            FPassword:='The password you have entered is incorrect.'#13#13;
            Fpassword:=Fpassword+'Try again?';
            If Application.MessageBox(PChar(FPassword),'Password protection',MB_YESNO or MB_ICONHAND)<>IDYes then
            Begin
              FDisk.free;
              exit;
            end;
            goto DoLogin_
          end;
        end else
        Begin
          { Quicker to just let Close() handle everything }
          FState:=ssOpen;
          Close;
          Raise EHEXInternalError.CreateFmt(ERR_HEX_InternalError,[ERR_WrongEncodingKey]);
        end;
      end;
    end;

    FEncodingKey:=FPassword;

    { Set the properties for open }
    FFilename:=Source;
    FState:=ssOpen;
    FTitle:=FHeader.Title;
    FInformation:=FHeader.Information;
    FIdentifier:=FHeader.KIND;

    { Attempt to accumulate stored streams }
    try
      AccumulateItems;
    except
      on exception do
      begin
        Close;
        Raise;
      end;
    end;

    { Notify world of state change }
    if assigned(FOnOpen) then
    FOnOpen(self,source);
  End;

  Function THexCabinet.GetSize:Integer;
  Begin
    if (FState<>ssOpen) then
    result:=0 else
    result:=FDisk.Size;
  end;

  Function THexCabinet.GetEncryption:Boolean;
  Begin
    if (FState<>ssOpen) then
    result:=False else
    result:=length(FHeader.FILEKEY)>0;
  End;

  { This routine scans the disk-file for stream entries }
  Procedure THexCabinet.AccumulateItems;
  var
    FFile:    TFileHeader;
    FItem:    THexStoredFile;
    FOffset:  Integer;
    x:        Integer;
  Begin
    For x:=1 to FHeader.FILES do
    begin

      { Read entry header }
      try
        FDisk.read(FFile,SizeOf(TFileHeader));
      except
        on exception do
        raise EHexStoredFile.Create(ERR_ReadFileHeader);
      end;

      { file mangled? }
      if (ffile.MAGIC<>FILE_MAGIC) then
      Raise EHexIOError.Create(ERR_Hex_IOError);

      { Add to our collection }
      try
        FItem:=THexStoredFile.Create(Self);
      except
        on exception do
        raise EHexStoredFile.Create(ERR_Accumulate);
      end;

      try
        FObjects.add(FItem);
      except
        on exception do
        begin
          FItem.free;
          raise EHexStoredFile.Create(ERR_AddFileItem);
        end;
      end;

      With FItem do
      Begin
        Filename:=FFile.FileName;
        ByteSize:=FFile.FILESIZE;
        BytePos:=FDisk.Position;
      End;

      { Seek next file }
      if (x<FHeader.FILES) then
      begin
        FOffset:=FDisk.Position;
        Inc(FOffset,FFile.FileSize);

        try
          FDisk.Seek(FOffset,0);
        except
          on exception do
          raise EHexIOError.Create(ERR_Hex_IOError);
        end;

      end;
    end;
  End;

  Procedure THexCabinet.ReadHeader;
  Begin

    try
      FDisk.Seek(0,0);
    except
      on exception do
      Raise EHexCabinet.Create(ERR_ReadHeader);
    end;

    try
      FDisk.Read(FHeader,SizeOf(FHeader));
    except
      on exception do
      Raise EHexCabinet.Create(ERR_ReadHeader);
    end;

    If FHeader.MAGIC<>DISK_MAGIC then
    raise EHexInternalError.Create(ERR_TYPEERROR);
  End;

  Procedure THexCabinet.WriteHeader;
  Begin
    try
      FDisk.Seek(0,0);
    except
      On exception do
      raise EHexCabinet.Create(ERR_SeekWriteHeader);
    end;

    try
      FDisk.Write(FHeader,SizeOf(FHeader));
    except
      on exception do
      raise EHexCabinet.Create(ERR_WriteHeader);
    end;
  End;

  Procedure THexCabinet.Close;
  var
    AFile:  String;
  Begin
    { only works on active cabs }
    if (FState<>ssOpen) then
    exit;

    try
      WriteHeader;
    except
      FreeAndNil(FDisk);
      FState:=ssClosed;

      (* no point raising this if we are dying *)
      If not (csDestroying in ComponentState) then
      raise;
    end;

    AFile:=FFilename;
    FFilename:='';
    FObjects.Clear;
    FreeAndNil(FDisk);
    FState:=ssClosed;
    FEncodingKey:='';

    if assigned(OnCabinetClosed) then
    OnCabinetClosed(self,AFile);
  End;

  Procedure THexCabinet.StoreFile(Filename:String);
  var
    FFile:  TFileStream;
  Begin
    { only works on active cabs }
    if (FState<>ssOpen) then
    exit;

    if fileexists(Filename)=False then
    begin
      raise EHexCabinet.Create(ERR_SourceFileMissing);
      exit;
    end;

    try
      FFile:=TFileStream.Create(Filename,fmOpenRead);
    except
      on e: exception do
      begin
        raise EHexCabinet.Create(E.message);
        exit;
      end;
    end;

    try
      try
        StoreStream(ExtractFileName(Filename),FFile);
      except
        on exception do
        raise;
      end;
    finally
      FFile.free;
    end;
  End;

  Function THexCabinet.StreamSize(Token:String):Integer;
  var
    Findex: Integer;
  Begin
    { only works on active cabs }
    if (FState<>ssOpen) then
    Begin
      result:=0;
      exit;
    end;

    FIndex:=IndexOf(Token);

    if FIndex=-1 then
    begin
      raise EHexCabinet.Create(ERR_StreamNotExist);
      exit;
    end;

    result:=Items[FIndex].ByteSize;
  end;

  Function THexCabinet.StreamExists(Token:String):Boolean;
  Begin
    { only works on active cabs }
    if (FState<>ssOpen) then
    result:=False else
    Result:=IndexOf(Token)>-1;
  End;

  Procedure THexCabinet.StoreStream(Token:String;Stream:TStream);
  var
    FFile:  TFileHeader;
    FTemp:  TMemoryStream;
    FStart: Integer;
  label
    _AllDone;
  Begin
    { only works on active cabs }
    if (FState<>ssOpen) then
    exit;

    { make token small }
    Token:=lowercase(Token);

    { stream already exist? }
    if StreamExists(Token) then
    begin
      raise EHexCabinet.Create(ERR_StreamExists);
      exit;
    end;

    { Seek to the bottom of the stream }
    try
      FDisk.Seek(FDisk.Size,0);
    except
      on exception do
      Begin
        raise EHexIOError.Create(ERR_Hex_IOError);
        exit;
      end;
    end;

    { populate stream header }
    FillChar(FFile,SizeOf(FFile),#0);
    FFile.MAGIC:=File_MAGIC;
    FFile.FILESIZE:=Stream.Size;
    FFile.FileName:=Token;

    { write stream header }
    try
      FDisk.Write(FFile,SizeOf(TFileHeader));
    except
      on exception do
      begin
        raise EHexCabinet.Create(ERR_WriteFileHeader);
        exit;
      end;
    end;

    FStart:=FDisk.Position;

    try
      Stream.Seek(0,0);
    except
      on exception do
      Begin
        Raise EHexIOError.Create(ERR_Hex_IOError);
        exit;
      end;
    end;

    If not Encrypted then
    begin
      try
        FDisk.CopyFrom(Stream,Stream.Size);
      except
        on exception do
        raise EHexCabinet.Create(ERR_WriteFileContent);
      end;
      goto _AllDone;
    end;

    try
      FTemp:=TMemoryStream.Create;
    except
      on exception do
      begin
        raise EHexCabinet.Create(ERR_AllocTempMemory);
        exit;
      end;
    end;

    try
      FTemp.CopyFrom(Stream,Stream.Size);
    except
      on exception do
      begin
        raise EHexCabinet.Create(ERR_FillTempMemory);
        exit;
      end;
    end;

    try
      try
        EncryptStream(FTemp);
        FDisk.CopyFrom(FTemp,FTemp.Size);
      except
        on exception do
        begin
          raise;
          exit;
        end;
      end;
    finally
      Ftemp.free;
    end;
    
    _AllDone:
    Inc(FHeader.FILES);

    try
      FObjects.add(THexStoredFile.Create(Self));
    except
      on exception do
      begin
        raise EHexCabinet.Create(ERR_AddFileItem);
        exit;
      end;
    end;

    Items[Count-1].Filename:=Token;
    Items[Count-1].ByteSize:=Stream.Size;
    Items[Count-1].BytePos:=FStart;

    try
      WriteHeader;
    except
      on exception do
      begin
        raise;
        exit;
      end;
    end;

    if assigned(OnStreamAdded) then
    OnStreamAdded(self,Token);
  End;

  Procedure THexCabinet.ExtractToFile(Token:String;Const Filename:String);
  var
    FFile:  TFileStream;
    FIndex: Integer;
  Begin
    { only works in active cabs }
    if (FState<>ssOpen) then
    exit;

    if FileExists(Filename) then
    begin
      try
        SysUtils.DeleteFile(Filename);
      except
        on exception do
        begin
          raise EHexCabinet.Create(ERR_DeleteFile);
          exit;
        end;
      end;
    end;

    FIndex:=IndexOf(Token);
    If FIndex=-1 then
    begin
      raise EHexCabinet.Create(ERR_StreamNotFound);
      exit;
    end;

    try
      FFile:=TFileStream.Create(Filename,fmCreate);
    except
      on exception do
      begin
        raise EHexCabinet.Create(ERR_FileExt);
        exit;
      end;
    end;

    try
      FDisk.Seek(Items[FIndex].BytePos,0);
    except
      on exception do
      begin
        raise EHexIOError.Create(ERR_Hex_IOError);
        exit;
      end;
    end;

    try
      FFile.CopyFrom(FDisk,Items[FIndex].ByteSize);
    except
      on exception do
      begin
        raise;
        FFile.free;
        exit;
      end;
    end;

    try
      If Encrypted then
      EncryptStream(FFile);
    finally
      FFile.free;
    end;
  End;

  Function THexCabinet.LoadStream(Token:String):TMemoryStream;
  var
    FData:  TMemoryStream;
  Begin
    if StreamExists(Token)=False then
    begin
      raise EHexCabinet.Create(ERR_StreamNotFound);
      exit;
    end;

    FData:=TMemoryStream.Create;
    try
      ExtractToStream(Token,FData);
    except
      on exception do
      begin
        FData.free;
        raise;
        exit;
      end;
    end;

    FData.Seek(0,0);
    result:=FData;
  End;

  Function THexCabinet.Dir(AFileExt:String):TStringList;
  var
    x:        Integer;
    FText:    String;
    FFilter:  TStringList;
  Begin
    { Check if we can do this }
    if (FState<>ssOpen) then
    Begin
      result:=NIL;
      exit;
    end;

    try
      FFilter:=TStringList.Create
    except
      on exception do
      Begin
        Raise;
        exit;
      end;
    end;

    { We return data in a stringlist }
    try
      Result:=TStringList.Create;
    except
      on exception do
      begin
        FFilter.free;
        Raise;
        Exit;
      end;
    end;

    FFilter.Text:=StringReplace(Lowercase(AFileExt),';',#13#10,[rfReplaceAll]);

    { run through the list and compare }
    try
      for x:=1 to FObjects.Count do
      Begin
        FText:=Lowercase(ExtractFileExt(Items[x-1].Filename));
        If FFilter.IndexOf(FText)>-1 then
        result.Add(Items[x-1].FileName);
      end;
    finally
      FFilter.free;
    end;
  End;

  Procedure THexCabinet.ExtractToStream(Token:String;Stream:TStream);
  var
    FIndex: Integer;
    FTemp:  TMemoryStream;
  Begin
    { Check if we can do this }
    if (FState<>ssOpen) then
    exit;

    { Does this stream exist? }
    FIndex:=IndexOf(Token);
    If FIndex=-1 then
    begin
      raise EHexCabinet.Create(ERR_StreamNotFound);
      exit;
    end;

    { Seek to the file beginning}
    try
      FDisk.Seek(Items[FIndex].BytePos,0);
    except
      on exception do
      begin
        Raise EHexIOError.Create(ERR_Hex_IOError);
        exit;
      end;
    end;

    { Data was not encrypted, just read and return }
    If Encrypted=False then
    begin
      try
        Stream.CopyFrom(FDisk,Items[FIndex].ByteSize);
        Stream.Seek(0,0);
      except
        raise EHexCabinet.Create(ERR_WriteFileContent);
      end;
      exit;
    end;

    { Data is encrypted, create a temp buffer }
    try
      FTemp:=TMemoryStream.Create;
    except
      on exception do
      Begin
        raise;
        exit;
      end;
    end;

    { Get the data in question }
    try
      FTemp.CopyFrom(FDisk,Items[FIndex].ByteSize);
    except
      on exception do
      begin
        FTemp.free;
        raise;
        exit;
      end;
    end;

    { Decode the data stream }
    try
      EncryptStream(FTemp);
    except
      on exception do
      begin
        FTemp.free;
        raise;
        exit;
      end;
    end;

    { And return the data, finnaly free the temp buffer }
    try
      Stream.CopyFrom(FTemp,FTemp.Size);
      Stream.seek(0,0);
    finally
      Ftemp.free;
    end;
  End;

  Procedure THexCabinet.ReplaceStream(Token:String;Stream:TStream);
  Begin
    try
      try
        If StreamExists(Token) then
        DeleteStream(Token);
      except
        on exception do
        Begin
          raise;
          exit;
        end;
      end;

      try
        StoreStream(Token,Stream);
      except
        on exception do
        raise;
      end;
    except
      on exception do
      raise;
    end;
  End;

  Procedure THexCabinet.RenameStream(Token,NewToken:String);
  var
    FTemp:  TMemoryStream;
  Begin
    { Check that we dont overwrite anything }
    If StreamExists(NewToken) then
    Begin
      Raise EHexCabinet.Create(ERR_NewSourceAlreadyExists);
      exit;
    end;

    { Check that the source file exists }
    If not StreamExists(Token) then
    begin
      Raise EHexCabinet.Create(ERR_StreamNotFound);
      exit;
    end;

    FTemp:=TMemoryStream.Create;
    try
      { Get content of file }
      ExtractToStream(Token,FTemp);

      { Delete the file }
      DeleteStream(Token);

      { Save back under new name }
      StoreStream(NewToken,FTemp);
    finally
      FTemp.free;
    end;
  End;

  Procedure THexCabinet.DeleteStream(Token:String);
  var
    FIndex,x:   Integer;
    FCopyTop,FCopyBottom:Integer;
    FCopySize:Integer;
    FCopySegments: Integer;
    FLastSegment:  Integer;
    FFileSize:Integer;
    FCopyPos:Integer;
    Fbuffer: Pointer;
  Begin
    if (FState<>ssOpen) then
    exit;

    FIndex:=IndexOf(Token);
    If FIndex=-1 then
    exit;

    { Last item delete? }
    If FIndex=FObjects.Count-1 then
    begin
      FCopyTop:=FDisk.Size;
      dec(FCopyTop,SizeOf(TFileHeader));
      Dec(FCopyTop,Items[FIndex].ByteSize);

      try
        FDisk.Size:=FCopyTop;
      except
        on exception do
        begin
          raise EHexIOError.Create(ERR_Hex_IOError);
          exit;
        end;
      end;

      FObjects.Delete(FIndex);
      Dec(Fheader.FILES);

      try
        WriteHeader;
      except
        on exception do
        begin
          raise;
          exit;
        end;
      end;

      if assigned(FOnDelete) then
      FOnDelete(self,Token);
      exit;
    end;

    { Allocate immediate buffer }
    try
      FBuffer:=AllocMem(FILE_CHUNK);
    except
      on exception do
      Begin
        raise;
        exit;
      end;
    end;

    try
      FCopyTop:=Items[FIndex].BytePos;
      FCopyBottom:=FCopyTop + Items[FIndex].ByteSize;
      dec(FCopyTop,SizeOf(TFileHeader));
      FCopySize:=FDisk.Size-FCopyBottom;

      FCopySegments:=(FCopySize div FILE_CHUNK);
      if FCopySegments*FILE_CHUNK>FCopySize then
      dec(FCopySegments);
      FLastSegment:=FCopySize - (FCopySegments*FILE_CHUNK);

      if assigned(FOnCompactBegins) then
      FOnCompactBegins(self,FCopySize);

      FCopyPos:=0;

      try
        for x:=1 to FCopySegments do
        begin
          inc(FCopyPos,FILE_CHUNK);
          if assigned(FOnCompactProgress) then
          FOnCompactProgress(self,FCopyPos,FCopySize);

          FDisk.Seek(FCopyBottom,0);
          FDisk.Read(FBuffer^,FILE_CHUNK);

          FDisk.Seek(FCopyTop,0);
          FDisk.Write(FBuffer^,FILE_CHUNK);

          Inc(FCopyTop,FILE_CHUNK);
          inc(FCopyBottom,FILE_CHUNK);
        end;
      except
        raise EHexCabinet.Create(ERR_MoveData);
        exit;
      end;

      if FLastSegment>0 then
      begin
        try
          inc(FCopyPos,FLastSegment);
          if assigned(FOnCompactProgress) then
          FOnCompactProgress(self,FCopyPos,FCopySize);

          FDisk.Seek(FCopyBottom,0);
          FDisk.Read(FBuffer^,FLastSegment);

          FDisk.Seek(FCopyTop,0);
          FDisk.Write(FBuffer^,FLastSegment);
        except
          raise;
        end;
      end;

      if assigned(FOnCompactends) then
      FOnCompactends(self,FCopySize);

      FFileSize:=Items[FIndex].ByteSize + SizeOf(TFileHeader);
      FDisk.Size:=(FDisk.Size-FFileSize);

      Dec(FHeader.Files);

      for x:=FIndex to FObjects.Count-1 do
      Items[x].BytePos:=Items[x].BytePos-FFileSize;

      FObjects.Delete(FIndex);

      try
        WriteHeader;
      except
        on exception do
        begin
          raise;
          exit;
        end;
      end;

      if assigned(OnStreamDeleted) then
      OnStreamDeleted(self,Token);
    finally
      { release immediate memory }
      FreeMem(FBuffer,FILE_CHUNK);
    end;
  End;

  //##########################################################
  // THexStoredFile
  //##########################################################

  Constructor THexStoredFile.Create(AOwner:THexCustomCabinet);
  Begin
    inherited Create;
    FParent:=AOwner;
  End;

  end.
