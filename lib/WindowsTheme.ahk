class WindowsTheme {
    static PreferredAppMode := Map("Default", 0, "AllowDark", 1, "ForceDark", 2, "ForceLight", 3, "Max", 4)
    static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
    static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", this.uxtheme, "ptr", 135, "ptr")
    static FlushMenuThemes := DllCall("GetProcAddress", "ptr", this.uxtheme, "ptr", 136, "ptr")

    static SetAppMode(DarkMode := True) {
        switch DarkMode{
            case True:
                {
                    DllCall(this.SetPreferredAppMode, "Int", this.PreferredAppMode["ForceDark"])
                    DllCall(this.FlushMenuThemes)
                }
            default:
                {
                    DllCall(this.SetPreferredAppMode, "Int", this.PreferredAppMode["Default"])
                    DllCall(this.FlushMenuThemes)
                }
        }
    }

    static SetWindowAttribute(GuiObj, DarkMode := True)
    {
        global DarkColors := Map("Background", "0x202020", "Controls", "0x404040", "Font", "0xE0E0E0")
        global TextBackgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Background"], "Ptr")

        if (VerCompare(A_OSVersion, "10.0.17763") >= 0)
        {
            DWMWA_USE_IMMERSIVE_DARK_MODE := 19
            if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
            {
                DWMWA_USE_IMMERSIVE_DARK_MODE := 20
            }
            switch DarkMode
            {
                case True:
                {
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
                    DllCall(this.SetPreferredAppMode, "Int", this.PreferredAppMode["ForceDark"])
                    DllCall(this.FlushMenuThemes)
                    GuiObj.BackColor := DarkColors["Background"]
                }
                default:
                {
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", False, "Int", 4)
                    DllCall(this.SetPreferredAppMode, "Int", this.PreferredAppMode["Default"])
                    DllCall(this.FlushMenuThemes)
                    GuiObj.BackColor := "Default"
                }
            }
        }
    }

    static SetWindowTheme(GuiObj, DarkMode := True)
    {
        static GWL_WNDPROC := -4
        static GWL_STYLE := -16
        static ES_MULTILINE := 0x0004
        static LVM_GETTEXTCOLOR := 0x1023
        static LVM_SETTEXTCOLOR := 0x1024
        static LVM_GETTEXTBKCOLOR := 0x1025
        static LVM_SETTEXTBKCOLOR := 0x1026
        static LVM_GETBKCOLOR := 0x1000
        static LVM_SETBKCOLOR := 0x1001
        static LVM_GETHEADER := 0x101F
        static GetWindowLong := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
        static SetWindowLong := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
        static Init := False
        static LV_Init := False
        global IsDarkMode := DarkMode

        Mode_Explorer := (DarkMode ? "DarkMode_Explorer" : "Explorer")
        Mode_CFD := (DarkMode ? "DarkMode_CFD" : "CFD")
        Mode_ItemsView := (DarkMode ? "DarkMode_ItemsView" : "ItemsView")

        for hWnd, GuiCtrlObj in GuiObj
        {
            switch GuiCtrlObj.Type
            {
                case "Button", "CheckBox", "ListBox", "UpDown":
                    {
                        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
                    }
                case "ComboBox", "DDL":
                    {
                        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
                    }
                case "Edit":
                    {
                        if (DllCall("user32\" GetWindowLong, "Ptr", GuiCtrlObj.hWnd, "Int", GWL_STYLE) & ES_MULTILINE)
                        {
                            DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
                        }
                        else
                        {
                            DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
                        }
                    }
                case "ListView":
                    {
                        if !(LV_Init)
                        {
                            static LV_TEXTCOLOR := SendMessage(LVM_GETTEXTCOLOR, 0, 0, GuiCtrlObj.hWnd)
                            static LV_TEXTBKCOLOR := SendMessage(LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
                            static LV_BKCOLOR := SendMessage(LVM_GETBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
                            LV_Init := True
                        }
                        GuiCtrlObj.Opt("-Redraw")
                        switch DarkMode
                        {
                            case True:
                            {
                                SendMessage(LVM_SETTEXTCOLOR, 0, DarkColors["Font"], GuiCtrlObj.hWnd)
                                SendMessage(LVM_SETTEXTBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
                                SendMessage(LVM_SETBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
                            }
                            default:
                            {
                                SendMessage(LVM_SETTEXTCOLOR, 0, LV_TEXTCOLOR, GuiCtrlObj.hWnd)
                                SendMessage(LVM_SETTEXTBKCOLOR, 0, LV_TEXTBKCOLOR, GuiCtrlObj.hWnd)
                                SendMessage(LVM_SETBKCOLOR, 0, LV_BKCOLOR, GuiCtrlObj.hWnd)
                            }
                        }
                        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)

                        ; To color the selection - scrollbar turns back to normal
                        ;DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_ItemsView, "Ptr", 0)

                        ; Header Text needs some NM_CUSTOMDRAW coloring
                        LV_Header := SendMessage(LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
                        DllCall("uxtheme\SetWindowTheme", "Ptr", LV_Header, "Str", Mode_ItemsView, "Ptr", 0)
                        GuiCtrlObj.Opt("+Redraw")
                    }
            }
        }

        if !(Init)
        {
            ; https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm#ExSubclassGUI
            global WindowProcNew := CallbackCreate(WindowProc)  ; Avoid fast-mode for subclassing.
            global WindowProcOld := DllCall("user32\" SetWindowLong, "Ptr", GuiObj.Hwnd, "Int", GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
            Init := True
        }
    }

    static ToggleTheme(GuiCtrlObj, *)
    {
        switch GuiCtrlObj.Text
        {
            case "DarkMode":
                {
                    this.SetWindowAttribute(GuiCtrlObj)
                    this.SetWindowTheme(GuiCtrlObj)
                }
            default:
                {
                    this.SetWindowAttribute(GuiCtrlObj, False)
                    this.SetWindowTheme(GuiCtrlObj, False)
                }
        }
    }
}


WindowProc(hwnd, uMsg, wParam, lParam)
{
    critical
    static WM_CTLCOLOREDIT := 0x0133
    static WM_CTLCOLORLISTBOX := 0x0134
    static WM_CTLCOLORBTN := 0x0135
    static WM_CTLCOLORSTATIC := 0x0138
    static DC_BRUSH := 18

    if (IsDarkMode)
    {
        switch uMsg
        {
            case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
            {
                DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
                DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
                DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Controls"], "UInt")
                return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
            }
            case WM_CTLCOLORBTN:
            {
                DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Background"], "UInt")
                return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
            }
            case WM_CTLCOLORSTATIC:
            {
                DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
                DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
                return TextBackgroundBrush
            }
        }
    }
    return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}
