/*
AHK2 Manager
A toolkit to control all running instances of AutoHotkey(V2.0+)，written using AutoHotkey v2.0+ (http://www.autohotkey.com/)
By Jacques Yip

Copyright 2022-2023 Jacques Yip
--------------------------------
*/

; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetName AHK2Manager
;@Ahk2Exe-SetDescription AHK2Manager
;@Ahk2Exe-SetVersion 0.1.2
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetOrigFilename AHK2Manager.exe
;@Ahk2Exe-SetMainIcon icons\main_light.ico
;@Ahk2Exe-AddResource icons\main_dark.ico, 160
; --------------------- GLOBAL --------------------------

#Requires AutoHotkey >=v2.0

#Include <Array>
#Include <WindowsTheme>
#Include <JSON>
#Include <ConfMan>

SetWorkingDir A_ScriptDir
#SingleInstance Force
SetTitleMatchMode 1
DetectHiddenWindows 1
FileEncoding "UTF-8-RAW"

FolderCheckList := ["lang", "scripts", "icons", "lib"]
for item in FolderCheckList
    If !FileExist(A_ScriptDir "\" item) {
        DirCreate(A_ScriptDir "\" item)
    }

FileInstall(".\lang\en_us.ini", ".\lang\en_us.ini", 1)
FileInstall(".\lang\zh_cn.ini", ".\lang\zh_cn.ini", 1)

Paths := EnvGet("PATH")
EnvSet("PATH", A_ScriptDir "\bin`;" Paths)
SplitPath A_ScriptName, , , , &appName

global sysThemeMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")

global CONF_PATH := A_ScriptDir "\setting.ini"
CONF := ConfMan.GetConf(CONF_PATH)
CONF.Setting := {
    language: "en_us",
    mode: 0
}
CONF.SCRIPTS := {}
CONF.COUNTSDAEMON := {}
CONF.COUNTSONCE := {}
CONF.COUNTSTEMP := {}
CONF.Setting.SetOpts("PARAMS")
CONF.COUNTSDAEMON.SetOpts("PARAMS")
CONF.COUNTSONCE.SetOpts("PARAMS")
CONF.COUNTSTEMP.SetOpts("PARAMS")
CONF.SCRIPTS.SetOpts("PARAMS")

If !FileExist(CONF_Path) {
    FileAppend "", CONF_Path
}
If (FileRead(CONF_Path) = "") {
    CONF.WriteFile()
}
CONF.ReadFile()

If !FileExist(A_ScriptDir "\lang") {
    DirCreate(A_ScriptDir "\lang")
}

If (A_IsCompiled = 1) {
    FileInstall(".\lang\en_us.ini", "lang\en_us.ini", 1)
    FileInstall(".\lang\zh_cn.ini", "lang\zh_cn.ini", 1)
}

global typeEnum := Map("ONCE", 0, "TEMP", 1, "DAEMON", 2)

; global scriptList := Array()
global scriptMap := Map()

unOpenScriptListTemp := Array()
unOpenScriptListOnce := Array()
unOpenScriptListDaemon := Array()

OpenScriptListTemp := Array()
OpenScriptListDaemon := Array()

global langMenu := Menu()
global startMenu := Menu()
global restartMenu := Menu()
global closeMenu := Menu()

WindowsTheme.SetAppMode(!sysThemeMode)

if (A_Args.Length > 0) {
    switch A_Args[1], false {
        case "mode":
            switch A_Args[2], false {
                case "sc":
                    CONF.Setting.mode := 1
                    CONF.WriteFile()
                    ChangeToSCMode()
                case "char":
                    CONF.Setting.mode := 0
                    CONF.WriteFile()
                default:
            }
        default:
    }
}

InitialLanguage()
CreateLangMenu()
CreateTrayMenu()
LoadScript(CONF.Setting.mode)
CreateMenu()

OpenAllTask()

Persistent
Return

; --------------------- SHORTCUTS --------------------------

; Ctrl + Alt + LButton, 启动
^!LButton:: {
    startMenu.Show
    Return
}

; Ctrl + Alt + RButton, 关闭
^!RButton:: {
    closeMenu.Show
    Return
}

; Ctrl + Alt + MButton, 重启
^!MButton:: {
    restartMenu.Show
    Return
}

; Win + Shift + R, 重新加载
#+r:: ReloadTray

; --------------------- MENU EVENT RESPONSE --------------------------
LoadScript(mode) {
    global
    if (mode = 1) {
        Loop Files A_ScriptDir "\scripts\*.ahk" {
            SplitPath A_LoopFileName, &OutFileName, , , &FileNameNoExt
            if (!(DetectConfig("SCRIPTS", FileNameNoExt))) {
                CONF.SCRIPTS.%FileNameNoExt% := 0
            }
        }
        for scriptName, scriptType in CONF.SCRIPTS {
            if (!(FileExist(A_ScriptDir . "\scripts\" . scriptName . ".ahk") == "A")) {
                CONF.SCRIPTS.Delete(scriptName)
                CONF.COUNTSDAEMON.Delete(scriptName)
                CONF.COUNTSONCE.Delete(scriptName)
                CONF.COUNTSTEMP.Delete(scriptName)
                return
            }
            ;@Debug-Output =>  {scriptName} :: {scriptType}
            if (scriptType = typeEnum["DAEMON"]) {
                ;@Debug-Output =>  {scriptName} is DAEMON SCRIPT

                if (!(DetectConfig("COUNTSDAEMON", scriptName))) {
                    original := (IniRead(CONF_PATH, "COUNTSONCE", scriptName, 0)) > (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, 0)) ? (IniRead(CONF_PATH, "COUNTSONCE", scriptName, 0)) : (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, 0))
                    CONF.COUNTSDAEMON.%scriptName% := original

                }
                if (IniRead(CONF_PATH, "COUNTSONCE", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome ONCE
                    CONF.COUNTSONCE.Delete(scriptName)
                }
                if (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome TEMP
                    CONF.COUNTSTEMP.Delete(scriptName)
                }
                if (WinExist(scriptName ".ahk - AutoHotkey", , ,)) {
                    CreateTaskInfo(scriptName, scriptName . ".ahk", scriptType, 1, A_Index)
                } else {
                    CreateTaskInfo(scriptName, scriptName . ".ahk", scriptType, 0, A_Index)

                }
            } else if (scriptType = typeEnum["TEMP"]) {
                ;@Debug-Output =>  {scriptName} is TEMP SCRIPT

                if (!(DetectConfig("COUNTSTEMP", scriptName))) {
                    original := (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, 0)) > (IniRead(CONF_PATH, "COUNTSONCE", scriptName, 0)) ? (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, 0)) : (IniRead(CONF_PATH, "COUNTSONCE", scriptName, 0))
                    CONF.COUNTSTEMP.%scriptName% := original

                }
                if (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome DAEMON
                    CONF.COUNTSDAEMON.Delete(scriptName)
                }
                if (IniRead(CONF_PATH, "COUNTSONCE", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome ONCE
                    CONF.COUNTSONCE.Delete(scriptName)
                }
                if (WinExist(scriptName ".ahk - AutoHotkey", , ,)) {
                    CreateTaskInfo(scriptName, scriptName . ".ahk", scriptType, 1, A_Index)
                } else {
                    CreateTaskInfo(scriptName, scriptName . ".ahk", scriptType, 0, A_Index)
                }
            } else {
                ;@Debug-Output =>  {scriptName} is ONCE SCRIPT

                if (!(DetectConfig("COUNTSONCE", scriptName))) {
                    original := (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, 0)) > (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, 0)) ? (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, 0)) : (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, 0))
                    CONF.COUNTSONCE.%scriptName% := original
                }
                if (IniRead(CONF_PATH, "COUNTSDAEMON", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome DAEMON
                    CONF.COUNTSDAEMON.Delete(scriptName)
                }
                if (IniRead(CONF_PATH, "COUNTSTEMP", scriptName, -1) >= 0) {
                    ;@Debug-Output =>  Deleted frome TEMP
                    CONF.COUNTSTEMP.Delete(scriptName)
                }
                if (!(WinExist(scriptName ".ahk - AutoHotkey", , ,))) {
                ;@Debug-Output =>  {scriptType} to create info

                    CreateTaskInfo(scriptName, scriptName . ".ahk", scriptType, 0, A_Index)
                }
            }
        }
        CONF.WriteFile()
    } else {
        ; 遍历scripts目录下的ahk文件
        Loop Files A_ScriptDir "\scripts\*.ahk" {
            SplitPath A_LoopFileName, &OutFileName, , , &FileNameNoExt
            NeedleRegEx := "(\+|\!)(\s)?([0-9]+.\s)?"
            menuName := RegExReplace(FileNameNoExt, NeedleRegEx)
            If (Instr(OutFileName, "!") == 1) {
                if (WinExist(A_LoopFileName " - AutoHotkey", , ,)) {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["TEMP"], 1, A_Index)
                } else {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["TEMP"], 0, A_Index)
                }
            } else if (Instr(OutFileName, "+") == 1) {
                if (WinExist(A_LoopFileName " - AutoHotkey", , ,)) {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["ONCE"], 1, A_Index)
                } else {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["ONCE"], 0, A_Index)
                }
            } else {
                if (WinExist(A_LoopFileName " - AutoHotkey", , ,)) {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["DAEMON"], 1, A_Index)
                } else {
                    CreateTaskInfo(menuName, OutFileName, typeEnum["DAEMON"], 0, A_Index)
                }
            }
        }
    }
}

OpenTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    Run A_ScriptDir "\scripts\" scriptItem.fileName
    if (scriptItem.scriptType != typeEnum["ONCE"]) {
        UpdateTaskStatus(ItemName, 1)
        RecreateMenu()
    }
    return
}

RestartTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    If WinExist(A_ScriptDir "\scripts\" scriptItem.fileName " - AutoHotkey", , ,) {
        WinClose(A_ScriptDir "\scripts\" scriptItem.fileName " - AutoHotkey", , ,)
    }
    Run A_ScriptDir "\scripts\" scriptItem.fileName
    UpdateTaskStatus(ItemName, 1)
    return
}

CloseTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    If WinExist( A_ScriptDir "\scripts\" scriptItem.fileName " - AutoHotkey", , ,) {
        WinClose( A_ScriptDir "\scripts\" scriptItem.fileName " - AutoHotkey", , ,)
    }
    UpdateTaskStatus(ItemName, 0)
    RecreateMenu()
    return
}

OpenAllTask(*) {
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 0) {
            if (scriptItem.scriptType == typeEnum["DAEMON"]) {
                Run A_ScriptDir "\scripts\" scriptItem.fileName
                UpdateTaskStatus(menuName, 1)
                try startMenu.Delete(menuName)
                restartMenu.Add(menuName, RestartTask)
                closeMenu.Add(menuName, CloseTask)
            }
        }
    }
}

CloseAllTask(*) {
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 1) {
            try WinClose(A_ScriptDir "\scripts\" scriptItem.fileName " - AutoHotkey", , ,)
            UpdateTaskStatus(menuName, 0)
        }
    }
    RecreateMenu()
}

CreateTaskInfo(ItemName, file, type, status := 0, index := 0) {
    scriptObj := Object()
    scriptObj.menuName := ItemName
    scriptObj.fileName := file
    scriptObj.scriptType := type
    scriptObj.status := status
    scriptObj.index := index
    scriptMap[ItemName] := scriptObj
    return scriptObj
}

UpdateTaskStatus(ItemName, status := 1) {
    scriptItem := scriptMap[ItemName]
    scriptObj := Object()
    scriptObj.fileName := scriptItem.fileName
    scriptObj.menuName := scriptItem.menuName
    scriptObj.index := scriptItem.index
    scriptObj.status := status
    scriptObj.scriptType := scriptItem.scriptType
    scriptMap[ItemName] := scriptObj
}

ProManager(*) {
    WmiInfo := GetWMI("AutoHotkey.exe")
    ShowIndex := 0
    PMGui := Gui()
    WindowsTheme.SetWindowAttribute(PMGui, !sysThemeMode)
    PMGui.SetFont("s9", "Arial")
    PMLV := PMGui.Add("ListView", "x2 y0 w760 h500", [lGUIIndex, lGUIPid, lGUIScriptname, lGUIMemory])
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 1) {
            ShowIndex += 1
            try procId := WinGetPID(scriptItem.fileName " - AutoHotkey")
            try memory := GetProcessMemoryInfo(procId)
            PMLV.Add(, ShowIndex, procId, scriptItem.fileName, memory)
        }
    }
    PMLV.ModifyCol()
    PMLV.ModifyCol(2, "Integer")
    PMLV.ModifyCol(3, "220")
    PMGui.Title := "Process List"
    WindowsTheme.SetWindowTheme(PMGui, !sysThemeMode)
    PMGui.Show
}

ShowTray(*) {
    A_TrayMenu.Show
}

Test(ItemName, ItemPos, MyMenu) {
    MsgBox("You selected" ItemName)
}

ChangeToSCMode(*) {
    Loop Files A_ScriptDir "\scripts\*.ahk" {
        SplitPath A_LoopFileName, &OutFileName, , , &FileNameNoExt
        NeedleRegEx := "(\+|\!)(\s)?([0-9]+.\s)?"
        menuName := RegExReplace(FileNameNoExt, NeedleRegEx)
        if (Instr(OutFileName, "!") == 1) {
            CONF.SCRIPTS.%menuName% := 1
            FileMove A_LoopFilePath, A_LoopFileDir . "/" . menuName . ".ahk", true
            CONF.WriteFile()
        } else if (Instr(OutFileName, "+") == 1) {
            CONF.SCRIPTS.%menuName% := 0
            FileMove A_LoopFilePath, A_LoopFileDir . "/" . menuName . ".ahk", true
            CONF.WriteFile()
        } else {
            if (!(DetectConfig("SCRIPTS", menuName))) {
                CONF.SCRIPTS.%menuName% := 2
            }
        }
    }
}

SwitchLanguage(ItemName, ItemPos, MyMenu) {
    CONF.Setting.language := ItemName
    InitialLanguage()
    CreateTrayMenu()
    CreateLangMenu()
}

InitialLanguage(*) {
    LANG_PATH := A_ScriptDir "\lang\" CONF.Setting.language ".ini"

    global lTrayExit := IniRead(LANG_PATH, "Tray", "exit")
    global lTrayReload := IniRead(LANG_PATH, "Tray", "reload")
    global lTrayProcMan := IniRead(LANG_PATH, "Tray", "procman")
    global lTrayLang := IniRead(LANG_PATH, "Tray", "lang")
    global lTrayCloseAll := IniRead(LANG_PATH, "Tray", "closeall")
    global lTrayClose := IniRead(LANG_PATH, "Tray", "close")
    global lTrayRestart := IniRead(LANG_PATH, "Tray", "restart")
    global lTrayStart := IniRead(LANG_PATH, "Tray", "start")

    global lGUIIndex := IniRead(LANG_PATH, "GUI", "index")
    global lGUIMemory := IniRead(LANG_PATH, "GUI", "memory")
    global lGUIPid := IniRead(LANG_PATH, "GUI", "pid")
    global lGUIScriptname := IniRead(LANG_PATH, "GUI", "scriptname")
}

ReloadTray(*) {
    CreateLangMenu()
    CreateTrayMenu()
    CreateMenu()
    LoadScript(CONF.Setting.mode)
    OpenAllTask()
    Return
}

ExitTray(*) {
    CloseAllTask()
    CONF.WriteFile()
    ExitApp
    Return
}

CreateTrayMenu(*) {
    ; A_TrayMenu := A_TrayMenu
    if (A_IsCompiled) {
        if (sysThemeMode) {
            TraySetIcon(A_ScriptName, -159)
        } else {
            TraySetIcon(A_ScriptName, -160)
        }
    } else {
        if (sysThemeMode) {
            TraySetIcon(A_ScriptDir "\icons\main_light.ico")
        } else {
            TraySetIcon(A_ScriptDir "\icons\main_dark.ico")
        }
    }
    A_IconTip := appName
    A_TrayMenu.Delete
    A_TrayMenu.ClickCount := 1
    A_TrayMenu.Add appName, ShowTray
    A_TrayMenu.ToggleEnable(appName)
    A_TrayMenu.Default := appName
    A_TrayMenu.Add
    A_TrayMenu.Add lTrayStart, startMenu
    A_TrayMenu.Add
    A_TrayMenu.Add lTrayRestart, restartMenu
    A_TrayMenu.Add lTrayClose, closeMenu
    A_TrayMenu.Add lTrayCloseAll, CloseAllTask
    A_TrayMenu.Add
    A_TrayMenu.Add lTrayLang, langMenu
    A_TrayMenu.Add lTrayProcMan, ProManager
    A_TrayMenu.Add
    A_TrayMenu.Add lTrayReload, ReloadTray
    A_TrayMenu.Add lTrayExit, ExitTray
}

CreateLangMenu(*) {
    langMenu.Delete
    Loop Files A_ScriptDir "\lang\*.ini" {
        SplitPath A_LoopFileName, , , , &FileNameNoExt
        langMenu.Add(FileNameNoExt, SwitchLanguage)
    }
    langMenu.Check(CONF.Setting.language)
}

CreateMenu(*) {
    startMenu.Add(lTrayStart, Test)
    startMenu.ToggleEnable(lTrayStart)
    startMenu.Default := lTrayStart
    startMenu.Add

    closeMenu.Add(lTrayClose, Test)
    closeMenu.ToggleEnable(lTrayClose)
    closeMenu.Default := lTrayClose
    closeMenu.Add

    restartMenu.Add(lTrayRestart, Test)
    restartMenu.ToggleEnable(lTrayRestart)
    restartMenu.Default := lTrayRestart
    restartMenu.Add

    unOpenScriptListTemp := Array()
    unOpenScriptListOnce := Array()
    unOpenScriptListDaemon := Array()

    OpenScriptListTemp := Array()
    OpenScriptListDaemon := Array()


    for menuName, scriptItem in scriptMap {
        if (scriptItem.scriptType = typeEnum["ONCE"]) {
            unOpenScriptListOnce.Push(menuName)
        }
        if (scriptItem.scriptType = typeEnum["TEMP"]) {
            If (scriptItem.status = 0) {
                unOpenScriptListTemp.Push(menuName)
            } else {
                OpenScriptListTemp.Push(menuName)
            }
        } else {
            If (scriptItem.status = 0) {
                unOpenScriptListDaemon.Push(menuName)
            } else {
                OpenScriptListDaemon.Push(menuName)
            }
        }
    }

    AddMenuItem(unOpenScriptListTemp, 0, unOpenScriptListTemp.Length > 0)
    AddMenuItem(unOpenScriptListOnce, 0, unOpenScriptListOnce.Length > 0)
    AddMenuItem(unOpenScriptListDaemon, 0, false)

    AddMenuItem(OpenScriptListTemp, 1, OpenScriptListTemp.Length > 0)
    AddMenuItem(OpenScriptListDaemon, 1, false)
}

RecreateMenu(*) {
    startMenu.Delete
    closeMenu.Delete
    restartMenu.Delete

    CreateMenu()

}

; --------------------- MENU FUNCTION --------------------------


AddMenuItem(list, status := 0, split := true, title := "") {
    list.sort("C")
    if (list.Length < 1) {
        return
    }
    if (status = 1) {
        if (title != "") {
            restartMenu.Add(title, Test)
            closeMenu.Add(title, Test)
        }
        for k, menuName in list {
            restartMenu.Add(menuName, RestartTask)
            closeMenu.Add(menuName, CloseTask)
        }
        if (split = true) {
            for k in list {
                restartMenu.Add
                closeMenu.Add
                Break
            }
        }
    } else {
        if (title != "") {
            startMenu.Add(title, Test)
        }
        for k, menuName in list {
            startMenu.Add(menuName, OpenTask)
        }
        if (split = true) {
            for k in list {
                startMenu.Add
                Break
            }
        }
    }
}

DetectConfig(section, name) {
    global CONF_PATH
    result := IniRead(CONF_PATH, section, name, false)
    return result
}


; --------------------- FUNCTION --------------------------

; 给定进程名称，返回该进程的所有信息
GetWMI(ProcessName) {
    objWMI := ComObjGet("winmgmts:\\.\root\cimv2")    ; 连接到WMI服务
    StrSql := 'SELECT * FROM Win32_Process WHERE Name=""'
    StrSql .= ProcessName
    StrSql .= '""'
    Info := objWMI.ExecQuery(StrSql)
    Return Info
}

; 给定进程PID，获取其内存消耗
GetProcessMemoryInfo(PID) {
    size := 440
    pmcex := Buffer(size, 0) ; V1toV2: if 'pmcex' is a UTF-16 string, use 'VarSetStrCapacity(&pmcex, size)'
    ret := ""

    hProcess := DllCall("OpenProcess", "UInt", 0x400 | 0x0010, "Int", 0, "Ptr", PID, "Ptr")
    if (hProcess) {
        if (DllCall("psapi.dll\GetProcessMemoryInfo", "Ptr", hProcess, "Ptr", pmcex, "UInt", size))
            ret := NumGet(pmcex, (A_PtrSize = 8 ? "16" : "12"), "UInt") / 1024 . " K"
        DllCall("CloseHandle", "Ptr", hProcess)
    }
    return ret
}
