VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FileUtils"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Private fs As Object
Private destPath As String

Private Sub Class_Initialize()
    Set fs = CreateObject("Scripting.FileSystemObject")
End Sub

Private Sub Class_Terminate()
    Set fs = Nothing
End Sub

Function mkdirs(path As String)
        Dim dStack As String: dStack = IIf(InStr(path, ".") = 1, ThisWorkbook.path, "")
        lpath = Replace(path, ".", "")
        Dim splitpath() As String: splitpath = Split(lpath, "\")
        
        For Each Item In splitpath
          dStack = dStack & Item
          If Not fs.FolderExists(dStack) Then fs.CreateFolder dStack
          dStack = dStack & "\"
        Next
End Function

Function CreateFolder(path)
    setPath (path)
    CreateFolder = fs.CreateFolder(destPath)
End Function

Function FileCopy(source As String, dest As String, Optional overwrite As Boolean)
    setPath (dest)
    fs.CopyFile source, destPath
End Function

Function FolderExists(path As String) As Boolean
    setPath (path)
    FolderExists = fs.FolderExists(destPath)
End Function

Function getFileName(path As String) As String
    getFileName = Dir(path)
End Function

Function appendTimeStamp(fileName As String) As String
    Dim fileNames() As String: fileNames = devideFileNames2(fileName)
    Dim cal As String: cal = Year(Date) & Format(Month(Date), "00") & Format(day(Date), "00")
    Dim clock As String: clock = Hour(time) & Format(Minute(time), "00") & Format(Second(time), "00")
    Dim returnName As String
    Dim count As Integer
    
    returnName = fileNames(0) & cal & clock & fileNames(1)
    appendTimeStamp = returnName
End Function

Function getObject() As Object
     getObject = fs
End Function

Function setPath(path As String)
    If InStr(path, ".") = 1 Then
        destPath = ThisWorkbook.path & path
    Else
       destPath = path
    End If
    
End Function

'��������Ȃ�
Function devideFileNames(fileName As String) As String()
   Dim delimiterPos As String: delimiterPos = InStrRev(fileName, ".")
   Dim splied(2) As String
   splied(0) = Mid(fileName, 1, delimiterPos - 1)
   splied(1) = Mid(fileName, delimiterPos)
   devideFileNames = splied
End Function

Function devideFileNames2(fileName As String) As String()
   Dim splied(2) As String
   splied(0) = fs.GetBaseName(fileName)
   splied(1) = "." & fs.GetExtensionName(fileName)
   devideFileNames2 = splied
End Function

Function getLastUpdateDay(fileName As String) As Date
      getLastUpdateDay = fs.getFile(fileName).DateLastModified()
End Function

Function isUpdate(left As String, right As String) As Boolean
    If fs.fileExists(left) And fs.fileExists(right) Then
        'right��left���A�V����
         If getLastUpdateDay(right) > getLastUpdateDay(left) Then isUpdate = True
    End If
End Function

Function isOpen(BookName As String) As Boolean

  Dim bk As Workbook

  isOpen = False

  For Each bk In Workbooks
    If bk.Name = BookName Then
      isOpen = True
      Exit For
    End If
  Next

End Function

Function getWorkbookObject(targetPath As String) As Workbook
    Dim remotePath As String: remotePath = targetPath
    Dim localPath As String: localPath = "c:\ExcelTemp\"
    
    If FolderExists(localPath) = False Then CreateFolder (localPath)

        '�t�@�C���̃_�E�����[�h
    If isUpdate(localPath, remotePath) Or Len(Dir(localPath & "\" & fs.getFileName(remotePath))) <= 0 Then
        FileCopy remotePath, localPath
    End If

    '�I�u�W�F�N�g�̍쐬
    If isOpen(fs.getFileName(remotePath)) Then
        Set IFlist = Workbooks(fs.getFileName(remotePath))
    Else
        Set IFlist = Workbooks.Open(localPath & "\" & fs.getFileName(remotePath), ReadOnly:=True)
    End If
    
    Set getWorkbookObject = IFlist
End Function

Function ReadFile(target As String, Optional encode As String = "UTF-8")
    If Len(target) = 0 Then Exit Function
    Dim buf As String
    With CreateObject("ADODB.Stream")
        .Charset = encode
        .Open
        .LoadFromFile target
         buf = .readText
        .Close
    End With
    ReadFile = buf
End Function

Sub SaveFile(path As String, Text As String)
    If Len(Text) = 0 Then Exit Sub
    With CreateObject("ADODB.Stream")
        .Charset = "UTF-8"
        .Open
        .LoadFromFile path
        .Position = .Size
        .WriteText Text, 1
        .SaveToFile path, 2
        .Close
    End With
End Sub

Sub SaveBinary(path As String, data() As Byte)
    If UBound(data) = 0 Then Exit Sub
    With CreateObject("ADODB.Stream")
        .Open
        .Type = 1
        .Write data
        .SaveToFile path, 2
        .Close
    End With
End Sub

Function SaveFile_Extra(path As String, Text As String, Optional sEncoding As String = "UTF-8")
'-----------------------------------------------------------
'   OutputFile()
'       ����F�f�[�^�t�@�C���̏o�́iWindows���T�|�[�g����C�ӂ̕����G���R�[�h�j
'       �����F�o�̓f�[�^�iString�^�j�A�t�@�C�����́i�t���p�X�j
'       �߂�l�F�Ȃ�
'-----------------------------------------------------------
    Dim DataBuffer As Variant
    Dim adTypeBinary: adTypeBinary = 1
    Dim adTypeText: adTypeText = 2
    Dim adSaveCreateOverWrite: adSaveCreateOverWrite = 2

    If Len(path) = 0 Then Exit Function
    Dim stream As Variant
    Set stream = CreateObject("ADODB.Stream")
        '�e�L�X�g���[�h��Stream�ɏ�������
        stream.Type = adTypeText
        stream.Charset = sEncoding
        stream.Open
        stream.WriteText Text, 1
        
        'ADODB.Stream��UTF-8��ۑ������BOM���t���̂ŁABOM����������
        If sEncoding = "UTF-8" Then
            '�o�C�i�����[�h�œǂݍ���
            stream.Position = 0
            stream.Type = adTypeBinary
            '�ŏ���3�o�C�g(BOM)���΂��ēǂݍ���
            stream.Position = 3
            DataBuffer = stream.Read()
            LastData = (DataBuffer(UBound(DataBuffer)) & DataBuffer(UBound(DataBuffer) - 1)) & DataBuffer(UBound(DataBuffer) - 2) & DataBuffer(UBound(DataBuffer) - 3)
            If LastData = "10131013" Then ReDim Preserve DataBuffer(UBound(DataBuffer) - 2)
            stream.Close
            'BOM��������UTF-8��Stream�ɏ�������
            Dim stream2: Set stream2 = CreateObject("ADODB.Stream")
            stream2.Open
            stream2.Position = 0
            stream2.Type = adTypeBinary
            stream2.Write (DataBuffer)
        End If
        
        '�t�@�C���ɏ�������
        stream2.SaveToFile path, 2
        'Stream��j��
        stream2.Close
End Function

Function readText(filePath As String)
    Dim resultCollection As New Collection
    setWorkingSheet.Activate
    If Len(Dir(filePath)) = 0 Then Exit Function
    Open filePath For Input As #1
    Do Until EOF(1)
        Line Input #1, temp
        resultCollection.Add (temp)
    Loop
    Close #1
    Set readText = resultCollection
End Function

Function saveCollection(filePath As String, textCollection As Collection, Optional delimiter As String = vbCrLf)
    Dim buffer As String
    For Each Text In textCollection
        If Len(Text) <> 0 Then
         buffer = buffer & Text & delimiter
        End If
    Next
    SaveFile_Extra filePath, buffer
End Function