/*
AHK2 Manager
Written using AutoHotkey v2.0+ (http://www.autohotkey.com/)
By Jacques Yip

Copyright 2022-2023 Jacques Yip
--------------------------------
*/

; --------------------- COMPILER DIRECTIVES --------------------------

;@Ahk2Exe-SetName AHK2 Manager
;@Ahk2Exe-SetDescription AHK2 Manager: A toolkit to control all running instances of AutoHotkey(V2.0+).
;@Ahk2Exe-SetVersion v1.0
;@Ahk2Exe-SetCopyright Jacques Yip
;@Ahk2Exe-SetOrigFilename AHK2Manager.exe

; --------------------- GLOBAL --------------------------

#Requires AutoHotkey >=v2.0

#Include <DefaultInclude>
#Include <Array>

Paths := EnvGet("PATH")
EnvSet("PATH", A_ScriptDir "\bin`;" Paths)

global scriptList := Array()
global scriptMap := Map()

unOpenScriptListTemp := Array()
unOpenScriptListOnce := Array()
unOpenScriptListDeamon := Array()

OpenScriptListTemp := Array()
OpenScriptListDeamon := Array()

global startMenu := Menu()
global restartMenu := Menu()
global closeMenu := Menu()

CreateMenu()

If !FileExist(A_ScriptDir "\scripts"){
    DirCreate(A_ScriptDir "\scripts")
}

; 遍历scripts目录下的ahk文件
Loop Files A_ScriptDir "\scripts\*.ahk"
{
    if (WinExist(A_LoopFileName " - AutoHotkey", , ,)) {
        WinKill
    }
    SplitPath A_LoopFileName, &OutFileName, , , &FileNameNoExt
    NeedleRegEx:="(\+|\!)(\w|\s)([0-9]+.\s)?"
    menuName:= RegExReplace(FileNameNoExt,NeedleRegEx)
    scriptObj := Object()
    scriptObj.fileName := OutFileName
    scriptObj.menuName := menuName
    scriptObj.index := A_Index
    scriptObj.status := 0
    If (Instr(OutFileName, "!") == 1) {
        unOpenScriptListTemp.Push(menuName)
        scriptObj.scriptType := "TEMP"
    }
    else if (Instr(OutFileName, "+") == 1) {
        unOpenScriptListOnce.Push(menuName)
        scriptObj.scriptType := "ONCE"
    }
    else {
        unOpenScriptListDeamon.Push(menuName)
        scriptObj.scriptType := "DEAMON"
    }
    scriptList.Push(scriptObj)
    scriptMap[menuName] := scriptObj
}

AddMenuItem(unOpenScriptListTemp, 0, true)
AddMenuItem(unOpenScriptListOnce, 0, true)
AddMenuItem(unOpenScriptListDeamon, 0, false)

OpenAllTask()

; A_TrayMenu := A_TrayMenu
TraySetIcon(A_ScriptDir "\icons\quesbox_darkmode.ico")
A_IconTip:= "Quesbox"
A_TrayMenu.Delete
A_TrayMenu.ClickCount := 1
A_TrayMenu.Add "Quesbox", ShowTray
A_TrayMenu.ToggleEnable("Quesbox")
A_TrayMenu.Default := "Quesbox"
A_TrayMenu.Add
A_TrayMenu.Add "Run", startMenu
A_TrayMenu.Add
A_TrayMenu.Add "Restart", restartMenu
A_TrayMenu.Add "Close", closeMenu
A_TrayMenu.Add "Close All", CloseAllTask
A_TrayMenu.Add
A_TrayMenu.Add "Proccess Manager", ProManager
A_TrayMenu.Add
A_TrayMenu.Add "Reload", ReloadTray
A_TrayMenu.Add "Exit", ExitTray

Persistent
Return

; --------------------- SHORTCUTS --------------------------

; Ctrl + Alt + LButton, 启动
^!LButton::{
    startMenu.Show
    Return
}

; Ctrl + Alt + RButton, 关闭
^!RButton::{
    closeMenu.Show
    Return
}

; Ctrl + Alt + MButton, 重启
^!MButton::{
    restartMenu.Show
    Return
}

; Ctrl + Shift + R, 重新加载
#+r::ReloadTray

; --------------------- MENU EVENT RESPONSE --------------------------

OpenTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    Run A_ScriptDir "\scripts\" scriptItem.fileName
    if (scriptItem.scriptType != "Once") {
        UpdateTaskStatus(ItemName, 1)
        ; ; debug
        ; newScripts := scriptMap[ItemName]
        ; MsgBox newScripts.status
        RecreateMenu()
    }
    return
}

RestartTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    If WinExist(scriptItem.fileName " - AutoHotkey", , ,) {
        WinClose(scriptItem.fileName " - AutoHotkey", , ,)
    }
    Run A_ScriptDir "\scripts\" scriptItem.fileName
    UpdateTaskStatus(ItemName, 1)
    return
}

CloseTask(ItemName, ItemPos, MyMenu) {
    scriptItem := scriptMap[ItemName]
    WinClose(scriptItem.fileName " - AutoHotkey", , ,)
    UpdateTaskStatus(ItemName, 0)
    RecreateMenu()
    return
}

OpenAllTask(*) {
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 0) {
            if (scriptItem.scriptType = "DEAMON") {
                Run A_ScriptDir "\scripts\" scriptItem.fileName
                UpdateTaskStatus(menuName, 1)
                startMenu.Delete(menuName)
                restartMenu.Add(menuName, RestartTask)
                closeMenu.Add(menuName, CloseTask)
            }
        }
    }
}

CloseAllTask(*) {
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 1) {
            WinClose(scriptItem.fileName " - AutoHotkey", , ,)
            UpdateTaskStatus(menuName, 0)
        }
    }
    RecreateMenu()
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
    PMGui.SetFont("s9", "Arial")
    PMLV := PMGui.Add("ListView", "x2 y0 w250 h200", ["Index", "PID", "Script Name", "Memory"])
    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 1) {
            ShowIndex += 1
            procId := WinGetPID(scriptItem.fileName " - AutoHotkey")
            memory := GetMemory(WmiInfo, procId)
            PMLV.Add(, ShowIndex, procId, scriptItem.fileName, memory)
        }
    }
    PMLV.ModifyCol()
    PMGui.Title := "Process List"
    PMGui.Show
}

ShowTray(*) {
    A_TrayMenu.Show
}

Test(ItemName, ItemPos, MyMenu) {
    MsgBox("You selected" ItemName)
}

ReloadTray(*){
    Reload
    Return
}

ExitTray(*){
    ExitApp
    Return
}

CreateMenu(*) {
    startMenu.Add("Start", Test)
    startMenu.ToggleEnable("Start")
    startMenu.Default := "Start"
    startMenu.Add

    closeMenu.Add("Close", Test)
    closeMenu.ToggleEnable("Close")
    closeMenu.Default := "Close"
    closeMenu.Add

    restartMenu.Add("Restart", Test)
    restartMenu.ToggleEnable("Restart")
    restartMenu.Default := "Restart"
    restartMenu.Add
}

RecreateMenu(*) {
    startMenu.Delete
    closeMenu.Delete
    restartMenu.Delete

    CreateMenu()

    unOpenScriptListTemp := Array()
    unOpenScriptListOnce := Array()
    unOpenScriptListDeamon := Array()

    OpenScriptListTemp := Array()
    OpenScriptListDeamon := Array()


    for menuName, scriptItem in scriptMap {
        If (scriptItem.status = 0) {
            if (scriptItem.scriptType = "TEMP") {
                unOpenScriptListTemp.Push(menuName)
            }
            else if (scriptItem.scriptType = "ONCE") {
                unOpenScriptListOnce.Push(menuName)
            }
            else {
                unOpenScriptListDeamon.Push(menuName)
            }
        }
        If (scriptItem.status = 1) {
            if (scriptItem.scriptType = "TEMP") {
                OpenScriptListTemp.Push(menuName)
            }
            else {
                OpenScriptListDeamon.Push(menuName)

            }
        }
    }

    AddMenuItem(unOpenScriptListOnce, 0, true)
    AddMenuItem(unOpenScriptListTemp, 0, true)
    AddMenuItem(unOpenScriptListDeamon, 0, false)

    AddMenuItem(OpenScriptListTemp, 1, true)
    AddMenuItem(OpenScriptListDeamon, 1, false)

}

; --------------------- MENU FUNCTION --------------------------


AddMenuItem(list, status := 0, split := true) {
    list.sort("C")
    if (status = 1) {
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
    }
    if (status = 0) {
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


; --------------------- FUNCTION --------------------------

; 给定进程名称，返回该进程的所有信息
GetWMI(ProcessName)
{
    objWMI := ComObjGet("winmgmts:\\.\root\cimv2")    ; 连接到WMI服务
    StrSql := 'SELECT * FROM Win32_Process WHERE Name=""'
    StrSql .= ProcessName
    StrSql .= '""'
    Info := objWMI.ExecQuery(StrSql)
    Return Info
}

; 给定进程PID，获取其内存消耗
GetMemory(WmiInfo, PID)
{
    for ObjProc in WmiInfo
    {
        if (ObjProc.ProcessID = PID)
        {
            usage := Round(ObjProc.WorkingSetSize / 1024)
            Return '%' usage . "K"
        }
    }

    Return "0K"
}
