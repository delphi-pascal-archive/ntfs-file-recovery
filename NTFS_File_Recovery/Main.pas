/////////////////////////////////////////////////////////////////////////////////////////////////////////
//MWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM//
//M                                                                                                   M//
//M                          ___    _     _________     _______       _____                           M//
//M                         |   \  | |   |___   ___|   |  _____|    /  ____/                          M//
//M                         | |\ \ | |       | |       | |__       |  \___                            M//
//M                         | | \ \| |       | |       |  __|       \____ \                           M//
//M                         | |  \   |       | |       | |          ____/  |                          M//
//M                         |_|   \__|       |_|       |_|         /______/                           M//
//M                                                                                                   M//
//M                                                                                                   M//
//M    MMMMM   M   M      MMMMM           MMMM    MMMMM   MMMM   MMM   M   M  MMMMM  MMMM    M   M    M//
//M    M       M   M      M               M   M   M      M      M   M  W   W  M      M   M   W  M     M//
//M    MMM     M   M      MMMM            MMMM    MMMM   M      M   M   M M   MMMM   MMMM     MM      M//
//M    M       M   M      M               M   M   M      M      M   M   W W   M      M   M    M       M//
//M    W       W   WWWWW  WWWWW           W   W   WWWWW   WWWW   WWW     W    WWWWW  W   W   W        M//
//M                                                                                                   M//
//M                                                                                                   M//
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM//
//M                                                                                                   M//
//M   Version : 2.0                                                                                   M//
//M   Author  : Nicolas PAGLIERI                                                                      M//
//M                                                                                                   M//
//M   Website : http://www.ni69.info                                                                  M//
//M   e-mail  : webmaster@ni69.info                                                                   M//
//M                                                                                                   M//
//MWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWMWM//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileDetails, XPMan, ComCtrls, Grids, ValEdit, ExtCtrls, Buttons;

//=====================================================================================================//
//=====================================================================================================//
//                                                                                                     //
//                                   D A T A    S T R U C T U R E S                                    //
//                                                                                                     //
//=====================================================================================================//
//=====================================================================================================//

type // This type will be used for containing every array of disk hex data
  TDynamicCharArray = array of Char;

type
  TBOOT_SEQUENCE = packed record
    _jmpcode : array[1..3] of Byte;
   	cOEMID: array[1..8] of Char;
 	  wBytesPerSector: Word;
 	  bSectorsPerCluster: Byte;
    wSectorsReservedAtBegin: Word;
 	  Mbz1: Byte;
 	  Mbz2: Word;
 	  Reserved1: Word;
 	  bMediaDescriptor: Byte;
 	  Mbz3: Word;
 	  wSectorsPerTrack: Word;
 	  wSides: Word;
 	  dwSpecialHiddenSectors: DWord;
 	  Reserved2: DWord;
 	  Reserved3: DWord;
 	  TotalSectors: Int64;
 	  MftStartLcn: Int64;
 	  Mft2StartLcn: Int64;
 	  ClustersPerFileRecord: DWord;
 	  ClustersPerIndexBlock: DWord;
 	  VolumeSerialNumber: Int64;
 	  _loadercode: array[1..430] of Byte;
 	  wSignature: Word;
  end;

type
  TNTFS_RECORD_HEADER = packed record
    Identifier: array[1..4] of Char; // Here must be 'FILE'
    UsaOffset : Word;
    UsaCount : Word;
    LSN : Int64;
  end;

type
  TFILE_RECORD = packed record
    Header: TNTFS_RECORD_HEADER;
	  SequenceNumber : Word;
	  ReferenceCount : Word;
	  AttributesOffset : Word;
	  Flags : Word; // $0000 = Deleted, $0001 = InUse, $0002 = Directory
	  BytesInUse : DWord;
	  BytesAllocated : DWord;
	  BaseFileRecord : Int64;
	  NextAttributeID : Word;
   // Pading : Word;                // Align to 4 Bytes boundary (XP)
   // MFTRecordNumber : DWord;      // Number of this MFT Record (XP)
  end;

type
  TRECORD_ATTRIBUTE = packed record
    AttributeType : DWord;
    Length : DWord;
    NonResident : Byte;
    NameLength : Byte;
    NameOffset : Word;
    Flags : Word;
    AttributeNumber : Word;
  end;

type
  TRESIDENT_ATTRIBUTE = packed record
    Attribute : TRECORD_ATTRIBUTE;
    ValueLength : DWord;
    ValueOffset : Word;
    Flags : Word;
  end;

type
  TNONRESIDENT_ATTRIBUTE = packed record
    Attribute: TRECORD_ATTRIBUTE;
    LowVCN: Int64;
    HighVCN: Int64;
    RunArrayOffset : Word;
    CompressionUnit : Byte;
    Padding : array[1..5] of Byte;
    AllocatedSize: Int64;
    DataSize: Int64;
    InitializedSize: Int64;
    CompressedSize: Int64;
  end;

type
  TFILENAME_ATTRIBUTE = packed record
	  Attribute: TRESIDENT_ATTRIBUTE;
    DirectoryFileReferenceNumber: Int64;
    CreationTime: Int64;
    ChangeTime: Int64;
    LastWriteTime: Int64;
    LastAccessTime: Int64;
    AllocatedSize: Int64;
    DataSize: Int64;
    FileAttributes: DWord;
    AlignmentOrReserved: DWord;
    NameLength: Byte;
    NameType: Byte;
	  Name: Word;
  end;

type
  TSTANDARD_INFORMATION = packed record
	  Attribute: TRESIDENT_ATTRIBUTE;
	  CreationTime: Int64;
	  ChangeTime: Int64;
	  LastWriteTime: Int64;
	  LastAccessTime: Int64;
	  FileAttributes: DWord;
	  Alignment: array[1..3] of DWord;
	  QuotaID: DWord;
	  SecurityID: DWord;
	  QuotaCharge: Int64;
	  USN: Int64;
  end;






//=====================================================================================================//
//=====================================================================================================//
//                                                                                                     //
//                                    F O R M    I N T E R F A C E                                     //
//                                                                                                     //
//=====================================================================================================//
//=====================================================================================================//

type
  TMainForm = class(TForm)
    DriveComboBox: TComboBox;
    LogLbl: TLabel;
    LogMemo: TRichEdit;
    WaitMsg: TPanel;
    FoundFilesStringGrid: TStringGrid;
    SaveDialog: TSaveDialog;
    Drive_Icon: TImage;
    ScannedFiles_Icon: TImage;
    Drive_Background: TShape;
    Drive_Title: TLabel;
    Drive_MFTLocationLbl: TLabel;
    Drive_SerialLbl: TLabel;
    Drive_SizeLbl: TLabel;
    Drive_NameLbl: TLabel;
    Drive_MFTSizeLbl: TLabel;
    Drive_MFTRecordsCountLbl: TLabel;
    ScannedFiles_Background: TShape;
    ScannedFiles_Title: TLabel;
    Drive_BackgroundSeparator: TShape;
    ScannedFiles_BackgroundSeparator: TShape;
    ScannedFiles_Subtitle1: TLabel;
    ScannedFiles_FileNameEdit: TEdit;
    ScannedFiles_FileNameSearchBtn: TBitBtn;
    ScanBtn: TBitBtn;
    ScannedFiles_Subtitle2: TLabel;
    ScannedFiles_OffsetEdit: TEdit;
    ScannedFiles_DollarSign: TLabel;
    ScannedFiles_OffsetSearchBtn: TBitBtn;
    RecoverBtn: TBitBtn;
    SortRadioGroup: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure ChangeUIEnableStatus(EnableControls: boolean; MaskList: boolean=false);
    procedure DriveComboBoxChange(Sender: TObject);
    procedure Log(Item: string; ItemColor: TColor=clBlack);
    procedure LogChange(Sender: TObject);
    procedure SortStringGrid(var GenStrGrid: TStringGrid; ThatCol: Integer);
    procedure SortRadioGroupClick(Sender: TObject);
    procedure ScannedFiles_OffsetSearchBtnClick(Sender: TObject);
    procedure ScannedFiles_FileNameSearchBtnClick(Sender: TObject);
    function FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;
                                 FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
    procedure FixupUpdateSequence(var RecordData: TDynamicCharArray);
    procedure ScanBtnClick(Sender: TObject);
    procedure RecoverBtnClick(Sender: TObject);
  private
  public
  end;






//=====================================================================================================//
//=====================================================================================================//
//                                                                                                     //
//                        G L O B A L    C O N S T A N T S    &    V A R I A B L E S                   //
//                                                                                                     //
//=====================================================================================================//
//=====================================================================================================//

const

  atAttributeStandardInformation = $10;
  atAttributeFileName = $30;
  atAttributeData = $80; {
      ATTRIBUTE_TYPE Possible Values ( SizeOf DWord ) :
      AttributeStandardInformation = $10,    AttributeAttributeList = $20,
      AttributeFileName = $30,               AttributeObjectId = $40,
      AttributeSecurityDescriptor = $50,     AttributeVolumeName	= $60,
      AttributeVolumeInformation = $70,      AttributeData = $80,
      AttributeIndexRoot = $90,              AttributeIndexAllocation = $A0,
      AttributeBitmap = $B0,                 AttributeReparsePoint	= $C0,
      AttributeEAInformation = $D0,          AttributeEA = $E0,
      AttributePropertySet = $F0,            AttributeLoggedUtilityStream = $100   }

var
  MainForm: TMainForm;

  BytesPerFileRecord: Word;                       //    \
  BytesPerCluster: Word;                          //     |__    Conversion
  BytesPerSector: Word;                           //     |      Ratios
  SectorsPerCluster: Word;                        //    /

  CURRENT_DRIVE: string;                          //    Saves the Drive which is currently used

  MASTER_FILE_TABLE_LOCATION : Int64;             //    \
  MASTER_FILE_TABLE_END : Int64;                  //     |__    MFT Location & Contents
  MASTER_FILE_TABLE_SIZE : Int64;                 //     |      Information
  MASTER_FILE_TABLE_RECORD_COUNT : integer;       //    /

  DEBUG_FOLDER_LOCATION : string;                 //    Debug Path where the log file and other
                                                  //    Status files are saved

  SEARCHING_FLAG : boolean;                       //    Prevents from several FileName researches
                                                  //    to be made at the same time in the Grid

implementation


{$R *.dfm}






//=====================================================================================================//
//=====================================================================================================//
//                                                                                                     //
//                                      I M P L E M E N T A T I O N                                    //
//                                                                                                     //
//=====================================================================================================//
//=====================================================================================================//






//=====================================================================================================//
//  Initializes form components and global variables
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.FormCreate(Sender: TObject);
var
  i: integer;
  Bits: set of 0..25;
  ValidDrives: TStrings;
  tmpStr: string;

begin


  DEBUG_FOLDER_LOCATION := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'Debug\';
  ForceDirectories(DEBUG_FOLDER_LOCATION);

  

  // Refreshes the Drive Selection ComboBox
  ValidDrives := TStringList.Create;
  try
    integer(Bits) := GetLogicalDrives;
    for i := 0 to 25 do begin
      tmpStr := Char(i+Ord('A'))+':';
      if (i in Bits) and (GetDriveType(Pchar(tmpStr+'\'))=DRIVE_FIXED) then ValidDrives.Append(tmpStr);
    end;
    DriveComboBox.Items.Assign(ValidDrives);
    if DriveComboBox.Items.Count<>0 then DriveComboBox.ItemIndex := 0;
    Log('Drives List Updated', clGreen);
  finally
    FreeAndNil(ValidDrives);
  end;



  // Restores the Layout of the StringGrid
  with FoundFilesStringGrid do begin
    RowCount := 1;
    Rows[0].Text := ('Record Location'+#13#10+'File Name'+#13#10+
                     'Size (Bytes)'+#13#10+'Creation Date'+#13#10+'Last Change Date');
  end;



  // Prevents several researches from running at the same time
  SEARCHING_FLAG := false;


end;
//=====================================================================================================//






//=====================================================================================================//
// Normalizes a string by replacing every potential special character in it by a simple one
//-----------------------------------------------------------------------------------------------------//
function NormalizeString(S: string): string;
const
  Source =  'àäâãçéèêëìïîôöòûüùÿÁÀÄÂÃÉÈÊËÍÎÌÔÖÒÓÕÜÛÙÚÝ';
  Destination = 'AAAAAEEEEIIIOOOOOUUUUYAAAAAEEEEIIIOOOOOUUUUY ';
var
  i, position: integer;
begin
  S := Trim(S);
  for i:=1 to Length(S) do begin
    position := Pos(S[i],Source);
    if position > 0 then S[i] := Destination[position];
    if not (S[i] in ['a'..'z','A'..'Z','0'..'9','_','-']) then S[i] := ' ';
  end;
  result := UpperCase(S);
end;
//=====================================================================================================//






//=====================================================================================================//
// Gets a Drive Label
//-----------------------------------------------------------------------------------------------------//
function GetVolumeLabel(Drive: Char): string;
var
   unused, flags: DWord;
   buffer: array [0..MAX_PATH] of Char;
begin
  buffer[0] := #$00;
  if GetVolumeInformation(PChar(Drive + ':\'), buffer, DWord(sizeof(buffer)),nil,unused,flags,nil,0) then
     SetString(result, buffer, StrLen(buffer))
  else result := '';
end;
//=====================================================================================================//






//=====================================================================================================//
//  Converts  Win32File_Time  into  UTC_Time
//-----------------------------------------------------------------------------------------------------//
function Int64TimeToDateTime(aFileTime: Int64): TDateTime;
var
  UTCTime, LocalTime: TSystemTime;
begin
  FileTimeToSystemTime( TFileTime(aFileTime), UTCTime);
  SystemTimeToTzSpecificLocalTime(nil, UTCTime, LocalTime);
  result := SystemTimeToDateTime(LocalTime);
end;
//=====================================================================================================//






//=====================================================================================================//
// Changes the Enable & Visible Status of UI Controls
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.ChangeUIEnableStatus(EnableControls, MaskList: boolean);
begin
  ScanBtn.Enabled := EnableControls;
  DriveComboBox.Enabled := EnableControls;
  RecoverBtn.Enabled := EnableControls;
  SortRadioGroup.Enabled := EnableControls;
  ScannedFiles_FileNameEdit.Enabled := EnableControls;
  ScannedFiles_FileNameSearchBtn.Enabled := EnableControls;
  ScannedFiles_OffsetEdit.Enabled := EnableControls;
  ScannedFiles_OffsetSearchBtn.Enabled := EnableControls;
  FoundFilesStringGrid.Enabled := EnableControls;
  FoundFilesStringGrid.Visible := (not MaskList);
  if EnableControls then LogLbl.Caption := '';
  SEARCHING_FLAG := not EnableControls;
end;
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.DriveComboBoxChange(Sender: TObject);
var
  VolumeLabel: string;
begin
  VolumeLabel := DriveComboBox.Text;
  VolumeLabel := GetVolumeLabel(VolumeLabel[1]);
  if VolumeLabel <> '' then Drive_NameLbl.Caption := 'Name : '+VolumeLabel
  else Drive_NameLbl.Caption := 'Name : Unknown';
  Drive_SerialLbl.Caption := 'Serial : Unknown';
  Drive_SizeLbl.Caption := 'Size : Unknown';
  Drive_MFTLocationLbl.Caption := 'MFT Location : Unknown';
  Drive_MFTSizeLbl.Caption := 'MFT Size : Unknown';
  Drive_MFTRecordsCountLbl.Caption := 'Number of Records : Unknown';
  FoundFilesStringGrid.RowCount := 1;
end;
//=====================================================================================================//






//=====================================================================================================//
// Log File Management (Adds events & Autosaves)
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.Log(Item: string; ItemColor:TColor=clBlack);
var
 i1, i2, i3 : integer;
 Date : string;
begin
 i1 := Length(LogMemo.Lines.Text);
 Date := DateTimeToStr(now)+' | ';
 i2 := i1 + Length(Date);
 LogMemo.Lines.Add(Date+Item);
 i3 := Length(LogMemo.Lines.Text);
 LogMemo.SelStart := i1;
 LogMemo.SelLength := i2-i1;
 LogMemo.SelAttributes.Color := clblack;
 LogMemo.SelStart := i2;
 LogMemo.SelLength := i3-i2;
 LogMemo.SelAttributes.Color := ItemColor;
 LogMemo.SelStart := i3;
 SendMessage(LogMemo.Handle,WM_VScroll,SB_LINEDOWN,0);
end;
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.LogChange(Sender: TObject);
begin
  LogMemo.Lines.SaveToFile(DEBUG_FOLDER_LOCATION+'LOG.RTF');
end;
//=====================================================================================================//






//=====================================================================================================//
// Sorts the FileList
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.SortStringGrid(var GenStrGrid: TStringGrid; ThatCol: Integer);
const
  // Defines the Separator
  SeparatorChar = '@';
var
  CountItem, i, j, k, PositionIndex: integer;
  TmpList: TStringList;
  TmpStr1, TmpStr2: string;
begin
  // Gives the number of rows in the StringGrid
  CountItem := GenStrGrid.RowCount;
  // Creates the List
  TmpList        := TStringList.Create;
  TmpList.Sorted := False;
  try
    begin
      for i := 1 to (CountItem - 1) do
        TmpList.Add(GenStrGrid.Rows[i].Strings[ThatCol] + SeparatorChar + GenStrGrid.Rows[i].Text);
      // Sorts the List
      TmpList.Sort;

      for k := 1 to TmpList.Count do
      begin
        // Takes the String of the line (k – 1)
        TmpStr1 := TmpList.Strings[(k - 1)];
        // Finds the position of the Separator in the String
        PositionIndex := Pos(SeparatorChar, TmpStr1);
        TmpStr2  := '';
        {Eliminates the Text of the column on which we have sorted the StringGrid}
        TmpStr2 := Copy(TmpStr1, (PositionIndex + 1), Length(TmpStr1));
        TmpList.Strings[(k - 1)] := '';
        TmpList.Strings[(k - 1)] := TmpStr2;
      end;

      // Refills the StringGrid
      for j := 1 to (CountItem - 1) do
        GenStrGrid.Rows[j].Text := TmpList.Strings[(j - 1)];
    end;
  finally
    TmpList.Free;
  end;
end;
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.SortRadioGroupClick(Sender: TObject);
begin
  SortStringGrid(FoundFilesStringGrid, SortRadioGroup.ItemIndex);
end;
//=====================================================================================================//






//=====================================================================================================//
//  Research procedures
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.ScannedFiles_FileNameSearchBtnClick(Sender: TObject);
var
  i, StartingRow : integer;
  Found : boolean;
  Request : string;
begin

  // Prevents several researches from running at the same time
  if SEARCHING_FLAG then exit;
  ChangeUIEnableStatus(false);


  Request := NormalizeString(ScannedFiles_FileNameEdit.Text);
  Log('Searching for any FileName attribute containing "'+Request+'"', clGray);
  LogLbl.Caption := 'Searching for any FileName attributes containing "'+Request+'"';
  Application.ProcessMessages;


  Found := false;
  StartingRow := FoundFilesStringGrid.Row+1; // Starts the research from the current line


  // If we're at the end of the list, starts the research from the beginning (first line after header)
  if StartingRow = FoundFilesStringGrid.RowCount-1 then StartingRow := 1;

  for i:=StartingRow to FoundFilesStringGrid.RowCount-1 do begin
    if Pos( Request,
            NormalizeString(FoundFilesStringGrid.Rows[i].Strings[1])) <> 0 then begin
      Found := true;
      FoundFilesStringGrid.Row := i;
      break;
    end;
  end;



  if Found then begin
    Log('Next Occurrence found on line #'+IntToStr(i), clGray);
  end else begin
    Log('The research did not return any matches.', clGray);
    if StartingRow>2 then
      MessageBoxA(Handle,
                  Pchar('The research did not return any matches starting from line #'+
                        IntToStr(StartingRow)+#13#10+
                        'You can try to launch it again from the beginning of the list.'),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST)
    else
      MessageBoxA(Handle,
                  Pchar('The research did not return any matches'),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);

  end;


  ChangeUIEnableStatus(true);

end;
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.ScannedFiles_OffsetSearchBtnClick(Sender: TObject);
var
  i : integer;
  Found : boolean;
  Offset : string;
begin

  // Prevents several researches from running at the same time
  if SEARCHING_FLAG then exit;
  ChangeUIEnableStatus(false);


  Offset := '$'+NormalizeString(ScannedFiles_OffsetEdit.Text);
  Log('Searching for the record corresponding to the Offset '+Offset, clGray);
  LogLbl.Caption := 'Searching for the record corresponding to the Offset '+Offset;
  Application.ProcessMessages;


  Found := false;
  for i:=1 to FoundFilesStringGrid.RowCount-1 do begin
    if FoundFilesStringGrid.Rows[i].Strings[0] = Offset then begin
      Found := true;
      FoundFilesStringGrid.Row := i;
      break;
    end;
  end;


  if Found then begin
    Log('File Record Found', clGray);
  end else begin
    Log('The research did not return any matches.');
    MessageBoxA(Handle,
                Pchar('The research did not return any matches'),
                Pchar('Information'),
                MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;


  ChangeUIEnableStatus(true);

end;
//=====================================================================================================//






//=====================================================================================================//
//  Finds an Attribute according to its name
//-----------------------------------------------------------------------------------------------------//
function TMainForm.FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;
                                      FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
var
  pFileRecord: ^TFILE_RECORD;
  pRecordAttribute: ^TRECORD_ATTRIBUTE;
  NextAttributeOffset: Word;
  TmpRecordData: TDynamicCharArray;
  TotalBytes: Word;
begin
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));
  if  pFileRecord.Header.Identifier[1] + pFileRecord.Header.Identifier[2]
     + pFileRecord.Header.Identifier[3] + pFileRecord.Header.Identifier[4]<>'FILE' then begin
    NextAttributeOffset := 0; // In this case, the parameter is a buffer taken from a recursive call
  end else begin
    NextAttributeOffset := pFileRecord^.AttributesOffset; // Means that it's the first run of recursion
  end;

  TotalBytes := Length(RecordData); // equals to BytesPerFileRecord in the second case (first run)
  Dispose(pFileRecord);

  New(pRecordAttribute);
  ZeroMemory(pRecordAttribute, SizeOf(TRECORD_ATTRIBUTE));

  SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
  TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
  CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));

  while (pRecordAttribute^.AttributeType <> $FFFFFFFF) and
        (pRecordAttribute^.AttributeType <> AttributeType) do begin
    NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
    SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
    TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
    CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));
  end;

  if pRecordAttribute^.AttributeType = AttributeType then begin

    if (FindSpecificFileNameSpaceValue) and (AttributeType=atAttributeFileName)  then begin

      // We test here the FileNameSpace Value directly (without any record structure)
      if (TmpRecordData[$59]=Char($0)) {POSIX} or (TmpRecordData[$59]=Char($1)) {Win32}
         or (TmpRecordData[$59]=Char($3)) {Win32&DOS} then begin
        SetLength(result,pRecordAttribute^.Length);
        result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
      end else begin
        NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
        SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
        TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
        // Recursive Call : finds next matching attributes
        result := FindAttributeByType(TmpRecordData,AttributeType,true);
      end;

    end else begin
      SetLength(result,pRecordAttribute^.Length);
      result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
    end;

  end else begin
    result := nil;
  end;
  Dispose(pRecordAttribute);
end;
//=====================================================================================================//


//=====================================================================================================//
//  Fixes Up an Update Sequence
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.FixupUpdateSequence(var RecordData: TDynamicCharArray);
var
  pFileRecord: ^TFILE_RECORD;
  UpdateSequenceOffset, UpdateSequenceCount: Word;
  UpdateSequenceNumber: array[1..2] of Char;
  i: integer;
begin
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));

  with pFileRecord^.Header do begin
    if Identifier[1]+Identifier[2]+Identifier[3]+Identifier[4] <> 'FILE' then begin
      Dispose(pFileRecord);
      raise Exception.Create('Unable to Fixup the Update Sequence: Invalid Record Data:'+
                             ' No FILE Identifier found');
    end;
  end;

  UpdateSequenceOffset := pFileRecord^.Header.UsaOffset;
  UpdateSequenceCount := pFileRecord^.Header.UsaCount;

  Dispose(pFileRecord);

  UpdateSequenceNumber[1] := RecordData[UpdateSequenceOffset];
  UpdateSequenceNumber[2] := RecordData[UpdateSequenceOffset+1];

  for i:=1 to UpdateSequenceCount-1 do begin
    // Validity Test
    if (RecordData[i*BytesPerSector-2] <> UpdateSequenceNumber[1])
       and (RecordData[i*BytesPerSector-1] <> UpdateSequenceNumber[2]) then begin
      Log('Warning: Invalid Record Data: Sector n°'+IntToStr(i)+' may be corrupt!', clMaroon);
      MessageBoxA(Handle,
                  Pchar('Warning : Invalid Record Data: Sector n°'+IntToStr(i)+' may be corrupt!'+
                        #13#10+'The process will NOT be interrupted.'),
                  Pchar('Warning'),
                  MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    end;
    RecordData[i*BytesPerSector-2] := RecordData[UpdateSequenceOffset+2*i];
    RecordData[i*BytesPerSector-1] := RecordData[UpdateSequenceOffset+1+2*i];
  end;
end;
//=====================================================================================================//


//=====================================================================================================//
//  Starts  the  research  of  Deleted  Files
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.ScanBtnClick(Sender: TObject);
var
  hDevice, hDest : THandle;

  BootData: array[1..512] of Char;
  MFTData: TDynamicCharArray;
  MFTAttributeData: TDynamicCharArray;
  StandardInformationAttributeData: TDynamicCharArray;
  FileNameAttributeData: TDynamicCharArray;
  DataAttributeHeader: TDynamicCharArray;

  dwread: LongWord;
  dwwritten: LongWord;

  pBootSequence: ^TBOOT_SEQUENCE;
  pFileRecord: ^TFILE_RECORD;

  pMFTNonResidentAttribute : ^TNONRESIDENT_ATTRIBUTE;
  pStandardInformationAttribute : ^TSTANDARD_INFORMATION;
  pFileNameAttribute : ^TFILENAME_ATTRIBUTE;
  pDataAttributeHeader: ^TRECORD_ATTRIBUTE;

  CurrentRecordCounter: integer;
  CurrentRecordLocator: Int64;

  FileName: WideString;
  FileCreationTime, FileChangeTime: TDateTime;
  FileParentDirectoryRecordNumber: Int64;
  FileSize: Int64;
  FileSizeArray : TDynamicCharArray;

  i: integer;

begin

  // Updates the current drive
  CURRENT_DRIVE := DriveComboBox.Text;
  if CURRENT_DRIVE = '' then begin
    MessageBoxA(Handle,
                Pchar('No Drive Detected !'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    exit;
  end else begin
    Log('Gathering Information concerning the drive '+CURRENT_DRIVE+'\ ...');
    LogLbl.Caption := 'Gathering Information concerning the drive '+CURRENT_DRIVE+'\ ...';
  end;



  // Changes Controls Accessibility during the research
  ChangeUIEnableStatus(false,true);



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Establishes a connection between Local Application and Physical Hard Drive
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  hDevice := CreateFile( PChar('\\.\'+CURRENT_DRIVE), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
                         nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then begin
    Log('Invalid Handle Value : Error '+IntToStr(GetLastError()), clred);
    MessageBoxA(Handle,
                Pchar('Invalid Handle Value '+#13#10+' Error '+IntToStr(GetLastError())),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    ChangeUIEnableStatus(true);
    exit;
  end else begin
    Log('Drive '+CURRENT_DRIVE+'\ Successfully Opened', clgreen);
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



                      {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                      SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
                      Readfile(hDevice, BootData, 512, dwread, nil);
                      hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'BootSequence.txt'), GENERIC_WRITE,
                                         0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                      WriteFile(hDest,BootData,512, dwwritten, nil);
                      Closehandle(hDest);
                      Log('Boot Sequence File Written : BootSequence.txt ('+IntToStr(dwwritten)+' Bytes)'
                          ,clblue);
                      // ===========================================================================}



  New(PBootSequence);
  ZeroMemory(PBootSequence, SizeOf(TBOOT_SEQUENCE));
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  ReadFile(hDevice,PBootSequence^, 512,dwread,nil);

  // Updates the "Drive Properties" Box
  Drive_NameLbl.Caption := 'Name : '+GetVolumeLabel(CURRENT_DRIVE[1]);
  Drive_SerialLbl.Caption := 'Serial : '+IntToHex(PBootSequence.VolumeSerialNumber,8);

  Log('Boot Sequence Data Read : '+IntToStr(dwread)+' Bytes', clblue);



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Checks if the disk is a NTFS disk
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  with PBootSequence^ do begin
    if  (cOEMID[1]+cOEMID[2]+cOEMID[3]+cOEMID[4] <> 'NTFS') then begin
      MessageBoxA(Handle,
                  Pchar('This is not a NTFS disk !'+#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Log('Error : This is not a NTFS disk !', clred);
      Dispose(PBootSequence);
      Closehandle(hDevice);
      ChangeUIEnableStatus(true);
      exit;
    end else begin
      Log('This is a NTFS disk.', clGreen);
    end;
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Calculates the ratios
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  BytesPerSector := PBootSequence^.wBytesPerSector;
  SectorsPerCluster := PBootSequence^.bSectorsPerCluster;
  BytesPerCluster := SectorsPerCluster * BytesPerSector;
  Log('Bytes Per Sector : '+IntToStr(BytesPerSector));
  Log('Sectors Per Cluster : '+IntToStr(SectorsPerCluster));
  Log('Bytes Per Cluster : '+IntToStr(BytesPerCluster));
  // Updates the "Drive Properties" Box
  Drive_SizeLbl.Caption := 'Size : '+IntToStr(PBootSequence.TotalSectors*BytesPerSector)+' bytes';

  // WARNING : ClustersPerFileRecord is a SIGNED hex value which can't be used directly
  //           when the cluster size is larger than the MFT File Record size !
  if (PBootSequence^.ClustersPerFileRecord < $80) then
      BytesPerFileRecord := PBootSequence^.ClustersPerFileRecord * BytesPerCluster
  else
      BytesPerFileRecord := 1 shl ($100 - PBootSequence^.ClustersPerFileRecord);
  Log('Bytes Per File Record : '+IntToStr(BytesPerFileRecord));
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  MASTER_FILE_TABLE_LOCATION := PBootSequence^.MftStartLcn * PBootSequence^.wBytesPerSector
                                * PBootSequence^.bSectorsPerCluster;
  Log('MFT Location : $'+IntToHex(MASTER_FILE_TABLE_LOCATION,2));
  // Updates the "Drive Properties" Box
  Drive_MFTLocationLbl.Caption := 'MFT Location : $'+IntToHex(MASTER_FILE_TABLE_LOCATION,2);



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    SetLength(MFTData,BytesPerFileRecord);
                    SetFilePointer(hDevice, Int64Rec(MASTER_FILE_TABLE_LOCATION).Lo,
                                   @Int64Rec(MASTER_FILE_TABLE_LOCATION).Hi, FILE_BEGIN);
                    Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);

                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_mainrecord.txt'), GENERIC_WRITE,
                                       0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('MFT File Written : mft_mainrecord.txt ('+IntToStr(dwwritten)+' Bytes)', clBlue);
                    // ===========================================================================}



  SetLength(MFTData,BytesPerFileRecord);
  SetFilePointer(hDevice, Int64Rec(MASTER_FILE_TABLE_LOCATION).Lo,
                 @Int64Rec(MASTER_FILE_TABLE_LOCATION).Hi, FILE_BEGIN);
  Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);
  Log('MFT Data Read : '+IntToStr(dwread)+' Bytes', clBlue);



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Fixes Up the MFT MainRecord Update Sequence
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  try
    FixupUpdateSequence(MFTData);
  except on E: Exception do begin
    Log('Error : '+E.Message, clred);
    MessageBoxA(Handle,
                Pchar(E.Message+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    ChangeUIEnableStatus(true);
    exit;
    end;
  end;
  Log('MFT Data FixedUp');
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_fixedup.txt'), GENERIC_WRITE, 0,
                                       nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('FixedUp MFT File Written : mft_fixedup.txt ('+IntToStr(dwwritten)+' Bytes)',
                        clBlue);
                    // ===========================================================================}



  MFTAttributeData := FindAttributeByType(MFTData,atAttributeData);



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_attrdata.txt'), GENERIC_WRITE, 0,
                                       nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTAttributeData)^, Length(MFTAttributeData), dwwritten, nil);
                    Closehandle(hDest);
                    Log('MFT $ATTRIBUTE_DATA File Written : mft_attrdata.txt ('+IntToStr(dwwritten)+
                        ' Bytes)', clBlue);
                    // ===========================================================================}



  New(pMFTNonResidentAttribute);
  ZeroMemory(pMFTNonResidentAttribute, SizeOf(TNONRESIDENT_ATTRIBUTE));
  CopyMemory(pMFTNonResidentAttribute, MFTAttributeData, SizeOf(TNONRESIDENT_ATTRIBUTE));



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Quickly checks the reliability of the process (if the MFT is sparse, encrypted or compressed all the
  // data structures we're going to deal with are not reliable!)
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  if (pMFTNonResidentAttribute^.Attribute.Flags = $8000)
     or (pMFTNonResidentAttribute^.Attribute.Flags = $4000)
     or (pMFTNonResidentAttribute^.Attribute.Flags = $0001) then begin
    MessageBoxA(Handle,
                Pchar('The MFT is sparse, encrypted or compressed.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Log('Error : The MFT is fragmented : Unable to continue.', clRed);
    Dispose(pMFTNonResidentAttribute);
    ChangeUIEnableStatus(true);
    exit;
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  MASTER_FILE_TABLE_SIZE := pMFTNonResidentAttribute^.HighVCN - pMFTNonResidentAttribute^.LowVCN;
                                                             { \_____________ = 0 _____________/ }


  Dispose(pMFTNonResidentAttribute);


  MASTER_FILE_TABLE_END := MASTER_FILE_TABLE_LOCATION + MASTER_FILE_TABLE_SIZE;
  MASTER_FILE_TABLE_RECORD_COUNT := (MASTER_FILE_TABLE_SIZE * BytesPerCluster) div BytesPerFileRecord;
  Log('MFT Size : '+IntToStr(MASTER_FILE_TABLE_SIZE)+' Clusters');
  Log('Number Of Records : '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT));
  // Updates the "Drive Properties" Box
  Drive_MFTSizeLbl.Caption := 'MFT Size : '+IntToStr(MASTER_FILE_TABLE_SIZE*BytesPerCluster)+' bytes';
  Drive_MFTRecordsCountLbl.Caption := 'Number of Records : '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);


  Log('Scanning for deleted files, please wait...');

  // Skips System File Records
  LogLbl.Caption := 'Analyzing File Record 16 out of '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);
  Application.ProcessMessages;

  // Clears the Found Files List
  FoundFilesStringGrid.RowCount := 1;
  SortRadioGroup.ItemIndex := 0;



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Main Loop
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  for CurrentRecordCounter := 16 to MASTER_FILE_TABLE_RECORD_COUNT-1 do begin


    if (CurrentRecordCounter mod 512) = 0 then begin // Refreshes File Counter every 512 records
       LogLbl.Caption := 'Analyzing File Record '+IntToStr(CurrentRecordCounter)+' out of '
                            +IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);
       Application.ProcessMessages;
    end;

    CurrentRecordLocator := MASTER_FILE_TABLE_LOCATION + CurrentRecordCounter*BytesPerFileRecord;

    // Memory Allocation / Prepares the buffer structure which will contain each File Record
    SetLength(MFTData,BytesPerFileRecord);
    SetFilePointer(hDevice, Int64Rec(CurrentRecordLocator).Lo,
                   @Int64Rec(CurrentRecordLocator).Hi, FILE_BEGIN);
    Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);



    try
      FixupUpdateSequence(MFTData);
    except on E: Exception do begin
      Log('Warning : File Record '+IntToStr(CurrentRecordCounter)+' out of '
          +IntToStr(MASTER_FILE_TABLE_RECORD_COUNT-1)+' : '+E.Message, clMaroon);
      continue;
      end;
    end;



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_filerecord_fixedup.txt'),
                                       GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    ShowMessage('FixedUp MFT FileRecordData Written : '+IntToStr(dwwritten)+' Bytes');
                    // ===========================================================================}



    New(pFileRecord);
    ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
    CopyMemory(pFileRecord, MFTData, SizeOf(TFILE_RECORD));



    if pFileRecord^.Flags=$0 then begin // If the file is set as Deleted

      StandardInformationAttributeData := FindAttributeByType(MFTData, atAttributeStandardInformation);
      if StandardInformationAttributeData<>nil then begin
        New(pStandardInformationAttribute);
        ZeroMemory(pStandardInformationAttribute, SizeOf(TSTANDARD_INFORMATION));
        CopyMemory(pStandardInformationAttribute, StandardInformationAttributeData,
                   SizeOf(TSTANDARD_INFORMATION));
        // Gets Creation & LastChange Times
           FileCreationTime := Int64TimeToDateTime(pStandardInformationAttribute^.CreationTime);
           FileChangeTime := Int64TimeToDateTime(pStandardInformationAttribute^.ChangeTime);
        Dispose(pStandardInformationAttribute);
      end else begin
        continue;
      end;

      FileNameAttributeData := FindAttributeByType(MFTData, atAttributeFileName, true);
      if FileNameAttributeData<>nil then begin
        New(pFileNameAttribute);
        ZeroMemory(pFileNameAttribute, SizeOf(TFILENAME_ATTRIBUTE));
        CopyMemory(pFileNameAttribute, FileNameAttributeData, SizeOf(TFILENAME_ATTRIBUTE));
        // Gets the File Name, which begins at offset $5A of this attribute
           FileName := WideString(Copy(FileNameAttributeData, $5A, pFileNameAttribute^.NameLength*2));
        // Gets the Parent Directory Record Number : for a further use maybe ?
           // FileParentDirectoryRecordNumber := pFileNameAttribute^.DirectoryFileReferenceNumber;
        Dispose(pFileNameAttribute);
      end else begin
        continue;
      end;

      DataAttributeHeader := FindAttributeByType(MFTData, atAttributeData);
      if DataAttributeHeader<>nil then begin
        New(pDataAttributeHeader);
        ZeroMemory(pDataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
        CopyMemory(pDataAttributeHeader, DataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
        // Gets the File Size : there is a little trick to prevent us from loading another data structure
        // which would depend on the value of the Non-Resident Flag...
        // a concrete example greatly helps comprehension of the following lines !
           FileSizeArray := Copy(DataAttributeHeader, $10+(pDataAttributeHeader^.NonResident)*$20,
                                 (pDataAttributeHeader^.NonResident+$1)*$4 );
           FileSize := 0;
           for i:=Length(FileSizeArray)-1 downto 0 do FileSize := (FileSize shl 8)+Ord(FileSizeArray[i]);
        Dispose(pDataAttributeHeader);
      end else begin
        continue;
      end;

      FoundFilesStringGrid.RowCount := FoundFilesStringGrid.RowCount + 1;
      FoundFilesStringGrid.Rows[FoundFilesStringGrid.RowCount-1].Text :=
                        ('$'+IntToHex(CurrentRecordLocator,2)+#13#10
                         +FileName+#13#10
                         +IntToStr(FileSize)+#13#10
                         +FormatDateTime('c',FileCreationTime)+#13#10
                         +FormatDateTime('c',FileChangeTime));

    end;



    Dispose(pFileRecord);



  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  Log('All File Records Analyzed ('+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT)+')',clGreen);
  Application.ProcessMessages;

  FoundFilesStringGrid.FixedRows := 1;
  ChangeUIEnableStatus(true);

  Dispose(PBootSequence);

  Closehandle(hDevice);

end;
//=====================================================================================================//






//=====================================================================================================//
//  Restores a file according to the location of its Record in the MFT
//-----------------------------------------------------------------------------------------------------//
procedure TMainForm.RecoverBtnClick(Sender: TObject);
var
  RecordLocator: Int64;

  hDevice, hDest : THandle;

  MFTFileRecord: TDynamicCharArray;
  StandardInformationAttributeData: TDynamicCharArray;
  FileNameAttributeData: TDynamicCharArray;
  DataAttributeHeader: TDynamicCharArray;
  ResidentDataAttributeData: TDynamicCharArray;
  NonResidentDataAttributeData: TDynamicCharArray;

  pFileRecord: ^TFILE_RECORD;
  pStandardInformationAttribute : ^TSTANDARD_INFORMATION;
  pFileNameAttribute : ^TFILENAME_ATTRIBUTE;
  pDataAttributeHeader : ^TRECORD_ATTRIBUTE;
  pResidentDataAttribute : ^TRESIDENT_ATTRIBUTE;
  pNonResidentDataAttribute : ^TNONRESIDENT_ATTRIBUTE;

  dwread: LongWord;
  dwwritten: LongWord;

  FileName: WideString;
  FileCreationTime, FileChangeTime: TDateTime;
  NonResidentFlag : boolean;

  DataAttributeSize: DWord;

  NonRes_OffsetToDataRuns: Word;
  NonRes_DataSize: Int64;
  NonRes_DataRuns: TDynamicCharArray;
  NonRes_DataRunsIndex: integer;
  NonRes_DataOffset: Int64;
  NonRes_DataOffset_inBytes: Int64;
  NonRes_CurrentLength: Int64;
  NonRes_CurrentOffset: Int64;
  NonRes_CurrentLengthSize: Byte;
  NonRes_CurrentOffsetSize: Byte;
  NonRes_CurrentData: TDynamicCharArray;
  NonRes_PreviousFileDataLength: Int64;

  Res_OffsetToData: Word;
  Res_DataSize: Int64;

  FileData: TDynamicCharArray;
  FileType: string;

  i : integer;
  i64 : Int64;

begin
  if (FoundFilesStringGrid.Row<1) or (FoundFilesStringGrid.Rows[1].Strings[0]='')
     or (FoundFilesStringGrid.Rows[1].Strings[0]=' ') then exit;



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Gets the Location
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  RecordLocator := StrToInt64(FoundFilesStringGrid.Rows[FoundFilesStringGrid.Row].Strings[0]);
  Log('Attempting to restore from FileRecord $'+IntToHex(RecordLocator,2));
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Establishes a connection between local program and Physical Hard Drive
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  hDevice := CreateFile( PChar('\\.\'+CURRENT_DRIVE), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
                         nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then begin
    Log('Invalid Handle Value : Error '+IntToStr(GetLastError()), clred);
    MessageBoxA(Handle,
                Pchar('Invalid Handle Value'+#13#10+'Error '+IntToStr(GetLastError())),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    exit;
  end else begin
    Log('Drive '+CURRENT_DRIVE+'\ Successfully Opened', clGreen);
  end;
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  SetLength(MFTFileRecord,BytesPerFileRecord);
  SetFilePointer(hDevice, Int64Rec(RecordLocator).Lo, @Int64Rec(RecordLocator).Hi, FILE_BEGIN);
  Readfile(hDevice, PChar(MFTFileRecord)^, BytesPerFileRecord, dwread, nil);



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Fixes Up the Record
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  try
    FixupUpdateSequence(MFTFileRecord);
  except on E: Exception do begin
    Log('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+') : '
        +E.Message, clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10+E.Message+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    exit;
    end;
  end;
  Log('FileRecord Data FixedUp', clGreen);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+''), GENERIC_WRITE, 0, nil,
                                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTFileRecord)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('FixedUp FileRecordData Written : filerecord_fixedup.txt ('+IntToStr(dwwritten)
                        +' Bytes)', clBlue);
                    // ===========================================================================}



  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, MFTFileRecord, SizeOf(TFILE_RECORD));



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Checks if the file is really listed as Deleted
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  if pFileRecord^.Flags<>0 then begin
    Log('Error : The file seems no longer listed as Deleted.', clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10'The file seems no longer listed as Deleted.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Dispose(pFileRecord);
    Closehandle(hDevice);
    exit;
  end;
  Log('File actually listed as Deleted.', clGreen);
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Retrieves DateTime Information (in the meanwhile, these pieces of info may have changed...)
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  StandardInformationAttributeData := FindAttributeByType(MFTFileRecord, atAttributeStandardInformation);
  if StandardInformationAttributeData<>nil then begin
    New(pStandardInformationAttribute);
    ZeroMemory(pStandardInformationAttribute, SizeOf(TSTANDARD_INFORMATION));
    CopyMemory(pStandardInformationAttribute, StandardInformationAttributeData,
               SizeOf(TSTANDARD_INFORMATION));
    Log('FileCreationTime : '+IntToStr(pStandardInformationAttribute^.CreationTime), clBlue);
    Log('FileChangeTime : '+IntToStr(pStandardInformationAttribute^.ChangeTime), clBlue);
          FileCreationTime := Int64TimeToDateTime(pStandardInformationAttribute^.CreationTime);
          FileChangeTime := Int64TimeToDateTime(pStandardInformationAttribute^.ChangeTime);
    Dispose(pStandardInformationAttribute);
    Log('DateTime information retrieved', clGreen);
  end else begin
    FileCreationTime := now;
    FileChangeTime := now;
    Log('Warning : Unable to retrieve the file DateTime information.', clMaroon);
    Log('DateTime information recreated (default value: now)', clMaroon);
    MessageBoxA(Handle,
                Pchar('Warning during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                      +')'+#13#10+'Unable to retrieve the file DateTime information.'
                      +#13#10+'Default values will be used instead.'),
                Pchar('Warning'),
                MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Retrieves FileName Information  (in the meanwhile, these pieces of info may have changed...)
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  FileNameAttributeData := FindAttributeByType(MFTFileRecord, atAttributeFileName, true);
  if FileNameAttributeData<>nil then begin
    New(pFileNameAttribute);
    ZeroMemory(pFileNameAttribute, SizeOf(TFILENAME_ATTRIBUTE));
    CopyMemory(pFileNameAttribute, FileNameAttributeData, SizeOf(TFILENAME_ATTRIBUTE));
        // Gets the File Name, which begins at offset $5A of this attribute
          FileName := WideString(Copy(FileNameAttributeData, $5A, pFileNameAttribute^.NameLength*2));
        // Gets the Parent Directory Record Number : for a further use maybe ?
          // FileParentDirectoryRecordNumber := pFileNameAttribute^.DirectoryFileReferenceNumber;
    Log('FileName : '+FileName, clBlue);
    Dispose(pFileNameAttribute);
    Log('FileName information retrieved', clGreen);
  end else begin
    FileName := 'UntitledFile.xxx';
    Log('Warning : Unable to retrieve the file FileName information.', clMaroon);
    Log('FileName information recreated (default value: UntitledFile.xxx)', clMaroon);
    MessageBoxA(Handle,
                Pchar('Warning during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                      +')'+#13#10+'Unable to retrieve the file FileName information.'
                      +#13#10+'Default value will be used instead.'),
                Pchar('Warning'),
                MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Retrieves Data Type Information of the file
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  DataAttributeHeader := FindAttributeByType(MFTFileRecord, atAttributeData);
  if DataAttributeHeader<>nil then begin
    New(pDataAttributeHeader);
    ZeroMemory(pDataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
    CopyMemory(pDataAttributeHeader, DataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
          NonResidentFlag := pDataAttributeHeader^.NonResident=1;
          DataAttributeSize := pDataAttributeHeader^.Length;
    Dispose(pDataAttributeHeader);
    Log('Non-Resident Flag : '+IntToStr(Ord(NonResidentFlag)), clBlue);
    Log('Data Attribute Size : '+IntToStr(DataAttributeSize), clBlue);
  end else begin
    Log('Error : Unable to get any DataType information', clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10+'Unable to get any DataType information.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Dispose(pFileRecord);
    Closehandle(hDevice);
    exit;
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Gathers Data
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  if NonResidentFlag then begin

    Log('The Data Attribute is Non-Resident.');

    // Retrieves NonResident Data Information
    NonResidentDataAttributeData := FindAttributeByType(MFTFileRecord, atAttributeData);
    if NonResidentDataAttributeData<>nil then begin
      New(pNonResidentDataAttribute);
      ZeroMemory(pNonResidentDataAttribute, SizeOf(TNONRESIDENT_ATTRIBUTE));
      CopyMemory(pNonResidentDataAttribute,NonResidentDataAttributeData, SizeOf(TNONRESIDENT_ATTRIBUTE));
            NonRes_OffsetToDataRuns := pNonResidentDataAttribute^.RunArrayOffset;
            NonRes_DataSize := pNonResidentDataAttribute^.DataSize;
      Log('Offset To Data Runs : $'+IntToHex(NonRes_OffsetToDataRuns,2), clBlue);
      Log('Data Size : $'+IntToHex(NonRes_DataSize,2), clBlue);
      Dispose(pNonResidentDataAttribute);
      // Retrieves DataRuns
      SetLength(NonRes_DataRuns, DataAttributeSize-(NonRes_OffsetToDataRuns-1));
      NonRes_DataRuns := Copy(NonResidentDataAttributeData,NonRes_OffsetToDataRuns,
                              DataAttributeSize-(NonRes_OffsetToDataRuns-1));
      Log('Data Runs retrieved.', clGreen);
    end else begin
      Log('Error : Unable to read NonResident Data information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10+'Unable to read NonResident Data information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;

    // DataRuns Processing
    try

      SetLength(FileData, 0);
      NonRes_DataRunsIndex := 0;
      NonRes_DataOffset := 0;

      while NonRes_DataRuns[NonRes_DataRunsIndex] <> Char($00)  do begin

        NonRes_CurrentLengthSize := Ord(NonRes_DataRuns[NonRes_DataRunsIndex]) and $F;
        NonRes_CurrentOffsetSize := (Ord(NonRes_DataRuns[NonRes_DataRunsIndex]) shr 4) and $F;
        NonRes_CurrentLength := 0;
        NonRes_CurrentOffset := 0;

        // Retrieves length and offset contents for the current run
        for i := NonRes_CurrentLengthSize-1 downto 0 do
            NonRes_CurrentLength := (Ord(NonRes_CurrentLength) shl 8)
                                    + Ord(NonRes_DataRuns[1+i+NonRes_DataRunsIndex]);
        for i := NonRes_CurrentLengthSize+NonRes_CurrentOffsetSize-1 downto NonRes_CurrentLengthSize do
            NonRes_CurrentOffset := (Ord(NonRes_CurrentOffset) shl 8)
                                    + Ord(NonRes_DataRuns[1+i+NonRes_DataRunsIndex]);

        // Fixup (negative values may exist as the offset is a signed value)
        if (NonRes_CurrentOffset > ($80 shl ((8*NonRes_CurrentOffsetSize)-1)))
           and (NonRes_DataRunsIndex<>0) then // This is a signed value (first one excepted!!!)
          NonRes_DataOffset := NonRes_DataOffset
                               - ( ($100 shl ((8*NonRes_CurrentOffsetSize)-1) ) - NonRes_CurrentOffset)
        else // Positive Value
          NonRes_DataOffset := NonRes_DataOffset + NonRes_CurrentOffset;

        // Reads the contents of the drive corresponding to the current run
        SetLength(NonRes_CurrentData, NonRes_CurrentLength*BytesPerCluster);
        NonRes_DataOffset_inBytes := NonRes_DataOffset*BytesPerCluster;
        SetFilePointer(hDevice, Int64Rec(NonRes_DataOffset_inBytes).Lo,
                       @Int64Rec(NonRes_DataOffset_inBytes).Hi, FILE_BEGIN);
        Readfile(hDevice, PChar(NonRes_CurrentData)^, NonRes_CurrentLength*BytesPerCluster, dwread, nil);

        // Appends the data to the Global Data
        NonRes_PreviousFileDataLength := Length(FileData);
        SetLength(FileData, NonRes_PreviousFileDataLength + (NonRes_CurrentLength*BytesPerCluster));

        if NonRes_CurrentOffset=0 then begin // Sparse File

          //  Fills with "$00"
          i64 := NonRes_PreviousFileDataLength;
          while i64 <= Length(FileData)-1 do begin
            FileData[i64] := Char($00);
            inc(i64);
          end;
          { The following code cannot be compiled because Int64 isn't considered as an ordinal type
          for i64 := NonRes_PreviousFileDataLength to Length(FileData)-1 do
              FileData[i64] := $00; }

        end else begin

          // Copies the content of the data corresponding to this run
          i64 := NonRes_PreviousFileDataLength;
          while i64 <= Length(FileData)-1 do begin
            FileData[i64] := NonRes_CurrentData[i64-NonRes_PreviousFileDataLength];
            inc(i64);
          end;
          { The following code cannot be compiled because Int64 isn't considered as an ordinal type
          for i64 := NonRes_PreviousFileDataLength to Length(FileData)-1 do
              FileData[i64] := NonRes_CurrentData[i-NonRes_PreviousFileDataLength]; }

        end;

        // Next datarun
        NonRes_DataRunsIndex := NonRes_DataRunsIndex+NonRes_CurrentLengthSize+NonRes_CurrentOffsetSize+1;
      end;

      // Truncates the data to fit the File DataSize Attribute
      SetLength(FileData, NonRes_DataSize);

      Log('Data Runs processed : Data Recovered', clGreen);

    except
      Log('Error : Unable to compute correctly the DataRuns information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10+'Unable to compute correctly the DataRuns information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;



  end else begin // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .



    Log('The Data Attribute is Resident.');

    // Retrieves Resident Data Information
    ResidentDataAttributeData := FindAttributeByType(MFTFileRecord, atAttributeData);
    if ResidentDataAttributeData<>nil then begin
      New(pResidentDataAttribute);
      ZeroMemory(pResidentDataAttribute, SizeOf(TRESIDENT_ATTRIBUTE));
      CopyMemory(pResidentDataAttribute, ResidentDataAttributeData, SizeOf(TRESIDENT_ATTRIBUTE));
            Res_OffsetToData := pResidentDataAttribute^.ValueOffset;
            Res_DataSize := pResidentDataAttribute^.ValueLength;
      Log('Offset To Data : $'+IntToHex(Res_OffsetToData,2), clBlue);
      Log('Data Size : $'+IntToHex(Res_DataSize,2), clBlue);
      Dispose(pResidentDataAttribute);
            SetLength(FileData, Res_DataSize);
            FileData := Copy(ResidentDataAttributeData,Res_OffsetToData,Res_DataSize);
      Log('Data Recovered', clGreen);
    end else begin
      Log('Error : Unable to read Resident Data information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10'Unable to read Resident Data information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;

  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Fills and Shows the FileDetails Window
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  FileDetailsForm.FileNameLbl.Caption := FileName;
  FileDetailsForm.SizeLbl.Caption := IntToStr(Length(FileData))+' Bytes';
  FileDetailsForm.CreationTimeLbl.Caption := 'Creation : '+FormatDateTime('c', FileCreationTime);
  FileDetailsForm.ChangeTimeLbl.Caption := 'Last Change : '+FormatDateTime('c', FileChangeTime);;
  FileDetailsForm.RecordLocationLbl.Caption := 'MFT File Record Location on Hard Drive : $'
                                               +IntToHex(RecordLocator,2);
  FileDetailsForm.SysIco.GetIcon(FileDetailsForm.GetIconIndex(ExtractFileExt(FileName), 0, FileType),
                                 FileDetailsForm.IconImg.Picture.Icon.Create);
  FileDetailsForm.FileTypeLbl.Caption := FileType;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
  // Saves the File
  // . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . //
  if (FileDetailsForm.ShowModal = mrOK) then begin
    SaveDialog.FileName := FileName;
    if SaveDialog.Execute then begin
      // Saves the Restored File
      hDest:= CreateFile(PChar(SaveDialog.FileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL, 0);
      WriteFile(hDest, PChar(FileData)^, Length(FileData), dwwritten, nil);
      Closehandle(hDest);
      Log('Recovered File Written : '+ExtractFileName(SaveDialog.FileName)+' ('
          +IntToStr(dwwritten)+' Bytes)', clBlue);
      Log('File Recovered', clGreen);
      MessageBoxA(Handle,
                  Pchar('The file has been recovered and saved :'+#13#10+SaveDialog.FileName),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    end;
  end;
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //



  Dispose(pFileRecord);
  Closehandle(hDevice);

end;
//=====================================================================================================//








end.
