' ===== Создаём основные объекты =====
Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

' Путь к файлу и папкам
localAppData = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
targetFolder = localAppData & "\Xeno\workspace"
tempPath = targetFolder & "\verification_key.txt"
scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)

' ===== Проверка: если файл уже существует — открываем и выходим =====
If fso.FileExists(tempPath) Then
    ' Открываем текстовый файл (используем правильный объект WshShell)
    WshShell.Run "notepad.exe """ & tempPath & """", 1, False
    
    ' Запускаем UI менеджер из папки со скриптом
    WshShell.Run """" & scriptFolder & "\ui_manager.exe""", 0, False
    
    WScript.Quit
End If

' ===== Получаем MAC-адрес через WMI =====
Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
Set adapters = objWMI.ExecQuery("SELECT MACAddress FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL")

mac = ""
For Each adapter In adapters
    ' Берем первый попавшийся активный MAC
    mac = adapter.MACAddress
    If mac <> "" Then Exit For
Next

If mac = "" Then mac = "00:00:00:00:00:00"

' ===== Генерация ключа =====
' Убираем двоеточия и приводим к верхнему регистру
cleanMac = UCase(Replace(mac, ":", ""))

' Гарантируем длину в 12 символов (дополняем нулями если нужно)
cleanMac = Left(cleanMac & "000000000000", 12)

part1 = Mid(cleanMac, 1, 4)
part2 = Mid(cleanMac, 5, 4)
part3 = Mid(cleanMac, 9, 4)

' Генерируем случайные 4 цифры
Randomize
rand4 = Int((9999 - 1000 + 1) * Rnd + 1000)

' Итоговый формат: NEXY-XXXX-XXXX-XXXX-RAND
key = "NEXY-" & part1 & "-" & part2 & "-" & part3 & "-" & rand4

' ===== Сохранение ключа =====
' Проверяем и создаем дерево папок, если их нет
If Not fso.FolderExists(localAppData & "\Xeno") Then fso.CreateFolder(localAppData & "\Xeno")
If Not fso.FolderExists(targetFolder) Then fso.CreateFolder(targetFolder)

' Записываем ключ в файл
Set file = fso.CreateTextFile(tempPath, True)
file.Write key
file.Close

' ===== Запуск приложений после создания ключа =====
' Открываем созданный файл
WshShell.Run "notepad.exe """ & tempPath & """", 1, False

' Запускаем UI менеджер
WshShell.Run """" & scriptFolder & "\ui_manager.exe""", 0, False