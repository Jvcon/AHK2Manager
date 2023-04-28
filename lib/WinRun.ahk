OpenApplication(exe, fileDirectory)
{
  OpenApplicationRaw("ahk_exe " . exe, fileDirectory . exe)
}

OpenApplicationRaw(identifier, runCommand)
{
  windowHandleIds := WinGetList(identifier)
  if (windowHandleIds.length !== 0) {

    ; select second window in list ...
    selectWindowIndex := 2

    ; ... unless any of application's windows are not in focus, then select the first window
    if (!WinActive(identifier)) {
      selectWindowIndex := 1
    }

    ; ... unless there is only 1 window in the list, then select the first (and only) window
    if (windowHandleIds.length == 1) {
      selectWindowIndex := 1
    }

    WinActivate("ahk_id " . windowHandleIds[selectWindowIndex])
  } else {
    Run(runCommand)
    WinWait(identifier)
    WinActivate(identifier)
  }
}

Run_AsUser(Program) {
  ComObject("Shell.Application")    .Windows.FindWindowSW(0, 0, 0x08, 0, 0x01)      .Document.Application.ShellExecute(Program) 
}

WinControlPannel(cpl:=""){
    Run "control" %cpl%
    Return
}

; 注意: 如果希望从命令提示符运行命令，必须在 Windows 文件夹下进行操作。
; 同时，请注意您的计算机可能并没有本文中所列的所有工具，因为您的 Windows 安装可能没有包括所有这些组件。
;
;    Control panel tool             Command
;    -----------------------------------------------------------------
;    Accessibility Options          control access.cpl
;    Add New Hardware               control sysdm.cpl add new hardware
;    Add/Remove Programs            control appwiz.cpl
;    Date/Time Properties           control timedate.cpl
;    Display Properties             control desk.cpl
;    FindFast                       control findfast.cpl
;    Fonts Folder                   control fonts
;    Internet Properties            control inetcpl.cpl
;    Joystick Properties            control joy.cpl
;    Keyboard Properties            control main.cpl keyboard
;    Microsoft Exchange             control mlcfg32.cpl
;       (or Windows Messaging)
;    Microsoft Mail Post Office     control wgpocpl.cpl
;    Modem Properties               control modem.cpl
;    Mouse Properties               control main.cpl
;    Multimedia Properties          control mmsys.cpl
;    Network Properties             control netcpl.cpl
;                                   NOTE: In Windows NT 4.0, Network
;                                   properties is Ncpa.cpl, not Netcpl.cpl
;    Password Properties            control password.cpl
;    PC Card                        control main.cpl pc card (PCMCIA)
;    Power Management (Windows 95)  control main.cpl power
;    Power Management (Windows 98)  control powercfg.cpl
;    Printers Folder                control printers
;    Regional Settings              control intl.cpl
;    Scanners and Cameras           control sticpl.cpl
;    Sound Properties               control mmsys.cpl sounds
;    System Properties              control sysdm.cpl
;
;
; 注意: “扫描仪与数字相机”程序 (sticpl.cpl) 无法在 Windows Millenium 中运行。
; 该程序已经被“扫描仪与数字相机”文件夹取代，其功能与如“打印机”文件夹和“拨号网络”文件夹之类的文件夹类似。
;
; Windows 以要运行的工具名称替换 %1%。。例如：
; “rundll32.exe shell32.dll,Control_RunDLL appwiz.cpl”。
; 要运行“控制面板”中的“用户”工具，请键入 control Ncpa.cpl users，然后按 ENTER 键。
;
; 要运行 Windows 95/98/ME 的“用户”工具，请键入“control inetcpl.cpl users”（不键入引号），然后按 ENTER 键。
