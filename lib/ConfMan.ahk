; ----------------------------------------------------------------------------------------------------------------------
; Class ........: ConfMan
; Description ..: Ini files management class, implementing an object central storage and an interface dealing with the
; ..............: underlined classes. ConfMan.IniInterface filters and redirect requests and calls to ConfMan.IniRoot,
; ..............: ConfMan.IniSection and ConfMan.IniFuncs.
; ..............: IniRoot and IniSections are basically Maps objects where the property notation is translated to item 
; ..............: notation, allowing to define a complete "ini" file structure like an object literal.
; ..............: ConfMan is a static class. Do not instantiate, use the available public methods to interact with it.
; Pub. Method ..: ConfMan.GetConf(sFileName, funcs*)
; Description ..: It initializes the object central storage and returns a ConfMan.IniInterface object.
; Parameters ...: sFileName - "Ini" file full path. If the file itself is not existing, it can be created with
; ..............:             a write operation. If the path to the file is not valid, an error will be thrown.
; ..............: funcs*    - Variadic parameter allowing for a series of function objects to be injected into the
; ..............:             ConfMan.IniFunc class. Injected functions must accept 2 parameters: "this" and the
; ..............:             ConfMan.IniRoot object used to process all "ini" file sections.
; Return .......: ConfMan.IniInterface object to be used for all interactions.
; Pub. Method ..: ConfMan.DiscardStorage()
; Description ..: Discard all object central storage.
; Interface ....: ConfMan.IniInterface (instantiated objects will be referred next as "objInterface")
; Description ..: objInterface allow the user to configure the object representing the "ini" file with literal notation
; ..............: and address the contained sections with property and item notations. objInterface "shadows" the
; ..............: ConfMan.IniRoot object and allow to interact with the ConfMan.IniSection objects.
; Obj. Config ..: Use literal notation: { SECTION1: {key1: value, key2: value}, SECTION2: {key1: value, key2: value} }
; ..............: Each section can be accessed as objInterface.SECTION1 or objInterface["SECTION1"].
; ..............: Each section can be configured with the "SetOpts" method with the following "options" (boolean flags):
; ..............: LOCKED  - This section should not be overridden by any operation.
; ..............: NOWRITE - This section is not written to file.
; ..............: NOEXKEY - Extra section keys will not be added to the configuration object when reading the file.
; ..............: PARAMS  - This section can be overridden by command line parameters.
; ..............: OBJECT  - When reading or overriding this section, the value in the key:value pair will be replaced by
; ..............:           a simple object with the "Value" property set (eg: { Value: value }).
; ..............: *** Please note that a section cannot have both the LOCKED and PARAMS options set.
; Pub. Method ..: objInterface.ReadFile()
; Description ..: Read file content and override all sections with the option LOCKED unset with the relative key:value 
; ..............: pairs.
; Pub. Method ..: objInterface.WriteFile()
; Description ..: Truncate the ini file if existing and create a new "ini" file with the ConfMan.IniRoot object content.
; Pub. Method ..: objInterface.ParseParams()
; Description ..: Parse command line parameters and override all sections with the option LOCKED unset and with the
; ..............: option PARAM set. The command line parameters must follow the notation [SECTION]key=value. The
; ..............: [SECTION] part can be omitted if only 1 section is marked with the PARAM option. If the value contains
; ..............: spaces, it can be enclosed in double quotes, that will be removed at processing time. New lines can be
; ..............: specified with the AutoHotkey notation `n.
; Pub. Method ..: objInterface.Section.SetOpts(sOptions)
; Description ..: Allow to specify a space separated list of option for the section. If the option is not present in the
; ..............: list, it will be set to 0 (eg: "LOCKED OBJECT" will set LOCKED=1, PARAMS=0, OBJECT=1).
; Parameters ...: sOpts - Space separated list containing the allowed options (LOCKED, PARAMS, OBJECT).
; Pub. Method ..: objInterface.Section.GetOpt(sOpt)
; Description ..: Get the value of the desired section option.
; Parameters ...: sOpt - Option to be retrieved (LOCKED, PARAMS, OBJECT).
; AHK Version ..: AHK v2 x32/64 Unicode
; Author .......: cyruz - http://ciroprincipe.info
; License ......: WTFPL - http://www.wtfpl.net/txt/copying/
; Changelog ....: Jan. 17, 2023 - v0.0.1 - First version.
; ..............: Jan. 18, 2023 - v0.0.2 - Fixed object override when OBJECT option is set and an object is already set.
; ..............:                          Added the NOWRITE option.
; ..............: Jan. 19, 2023 - v0.0.3 - Fixed an issue with the ReadFile function where the "Default" property of the
; ..............:                          ConfMan.IniRoot object was requested if the read Key was not present in the
; ..............:                          ConfMan.IniSection object.
; ..............: Jan. 22, 2023 - v0.0.4 - Added the NOEXKEY option.
; Thanks .......: swagfag - https://www.autohotkey.com/boards/memberlist.php?mode=viewprofile&u=75383
; ----------------------------------------------------------------------------------------------------------------------
; Class Diagram Description:
;
;  ┌───────┐
;  │ConfMan│
;  │       ├───────┬────────────────────────┬─────────────────────────┬──────────────────────┐
;  │Static │       │(parent)                │(parent)                 │(parent)              │(provide)
;  └───┬───┘       ▼                        ▼                         ▼                      ▼
;      │   ┌───────────────┐    ┌───────────────────────┐    ┌─────────────────┐    ┌ ─ ─ ─ ─ ─ ─ ─ ─ ┐        
;      │   │ConfMan.IniRoot│    │ConfMan.IniSection     │    │ConfMan.IniFuncs │    │Object Storage   │ 
;      │   │Extends Map    │◄───┤Extends ConfMan.IniRoot│    │                 │    │Map              │
;      │   │               │    │                       │    │Static           │    │Static Class Var.│ 
;      │   └───────────────┘    └───────────────────────┘    └─────────────────┘    └ ─ ─ ─ ─ ─ ─ ─ ─ ┘
;      │           ▲                        ▲                         ▲                      ▲
;      │           │(shadow)                │(shadow)                 │(forward calls)       │
;      │           └────────────────────────┼─────────────────────────┘                      │
;      │                                    │                                                │
;      │                         ┌──────────┴──────────┐                                     │
;      │(parent - return)        │ConfMan.IniInterface │      (store ConfMan.IniRoot objects)│
;      └────────────────────────►│Extends Buffer       ├─────────────────────────────────────┘
;                                │Interface            │
;                                └─────────────────────┘
;
; ----------------------------------------------------------------------------------------------------------------------

class ConfMan
{
    ; Object central storage.
    ; This will be instantiated as a Map().
    static objStor := ""
    
    static Call(params*)
    {
        throw Error("This is a static class. Please use <ConfMan.GetConf(sFileName)> to get an object.")
    }
    
    ; MAIN METHOD - Returns a ConfMan.IniInterface object after central storage initialization.
    static GetConf(sFileName, funcs*)
    {
        (!IsObject(ConfMan.objStor)) && ConfMan.objStor := Map()     
        return ConfMan.IniInterface(sFileName, funcs*)
    }
    
    ; Completely discard all central storage content.
    static DiscardStorage() => ConfMan.objStor := ""
    
    ; Collection of functions working on IniRoot objects.
    ; Custom functions can be injected, each function must accept 2 parameters:
    ; 1. this (to be ignored, it will be the ConfMan.IniInterface object).
    ; 2. oRoot (the ConfMan.IniRoot object to process all ConfMan.IniSection objects).
    class IniFuncs
    {
        static Call(params*)
        {
            throw Error("Static class.")
        }
        
        static ReadFile(oRoot)
        {
            sFileName := oRoot.__GetProp("FILENAME")
            
            if !FileExist(sFileName)
               throw Error("File not existing.", sFileName)
               
            sIniFile := IniRead(sFileName)
            loop parse, sIniFile, "`n"
            {
                if oRoot.Has(A_LoopField)
                {
                    if oRoot[A_LoopField].__GetProp("OPT_LOCKED")
                        continue
                    
                    sSectionName    := A_LoopField
                    sSectionContent := IniRead(sFileName, sSectionName)
                    bObject         := oRoot[A_LoopField].__GetProp("OPT_OBJECT")
                    bNoKeys         := oRoot[A_LoopField].__GetProp("OPT_NOEXKEY")
                    
                    loop parse, sSectionContent, "`n"
                    {
                        ; Match oM.1 = KEY / oM.2 = VALUE
                        if RegExMatch(A_LoopField, "S)^\s*(\w+)\s*\=\s*(.*)\s*$", &oM:=0)
                        {
                            if bNoKeys && !oRoot[sSectionName].Has(oM.1)
                                continue
                                
                            oM.2 := ConfMan.IniFuncs.__UnescapeNewLine(oM.2)
                            if bObject
                                (oRoot[sSectionName].Has(oM.1) && IsObject(oRoot[sSectionName][oM.1]))
                               ? oRoot[sSectionName][oM.1].Value := oM.2
                               : oRoot[sSectionName][oM.1] := { Value: oM.2 }
                            else oRoot[sSectionName][oM.1] := oM.2
                            bUpdated := 1
                        }
                    }
                }
            }
            
            return IsSet(bUpdated) ? 1 : 0
        }
        
        static WriteFile(oRoot)
        {
            sFileName := oRoot.__GetProp("FILENAME")
            
            try
            {
                f := FileOpen(sFileName, "w")
                for sec,cont in oRoot
                {
                    if cont.__GetProp("OPT_NOWRITE")
                        continue
                    f.WriteLine("[" sec "]")
                    for k,v in cont
                    {   ; If our IniSection key:value pair value is an object, get its "Value" property.
                        (IsObject(v) && v.HasOwnProp("Value")) && v := v.Value
                        f.WriteLine(k "=" ConfMan.IniFuncs.__EscapeNewLine(v))
                    }
                }
            }
            catch Error as e
                throw e
            finally
                (IsSet(f)) && f.Close()
            
            return 1
        }

        static ParseParams(oRoot)
        {
            ; Take note of the sections marked with the PARAMS option.
            sParamSec := "", nCount := 0
            for sec,cont in oRoot
                if cont.__GetProp("OPT_PARAMS")
                    sParamSec := sec, nCount++

            if !nCount
                throw ValueError("No section has been marked with the PARAMS option.")
            
            loop A_Args.Length
            {
                ; Match oM.1 = SECTION / oM.2 = KEY / oM.3 = VALUE
                if RegExMatch(A_Args[A_Index], "S)^(?:\[([^\[\]]+)\])*([\w]+)\=(.+)$", &oM:=0)
                {
                    ; Throw if:
                    ; * There are multiple sections marked to be overridden by parameters but none has been specified.
                    ; * A section has been specified but it does not exists or it is not marked to be overridden.
                    
                    if oM.1 == "" && nCount > 1
                        throw ValueError("Multiple section marked with PARAMS option but none has been specified.")
                    if oM.1 != "" && (!oRoot.Has(oM.1) || !oRoot[oM.1].__GetProp("OPT_PARAMS"))
                        throw ValueError("Section [" oM.1 "] does not exists or is not marked with PARAMS option.")
                    
                    ; If we have only one section marked with PARAMAS option we can avoid the
                    ; [SECTION] part in the command line parameter, so we perform this assignment.
                    (oM.1 == "") && oM.1 := sParamSec
                    
                    ; Do not throw if the section is marked with the NOEXKEY option, just skip the key.
                    if oRoot[oM.1].__GetProp("OPT_NOEXKEY") && !oRoot[oM.1].Has(oM.2)
                        continue
                    
                    ; Remove surrounding double quotes if present and unescape new lines.
                    (InStr(oM.3, "`"", 1) = 1) && (InStr(oM.3, "`"",, -1) = StrLen(oM.3)) && oM.3 := SubStr(oM.3, 2, -1)
                    oM.3 := ConfMan.IniFuncs.__UnescapeNewLine(oM.3)
                    
                    ; Perform the assignment.
                    if oRoot[oM.1].__GetProp("OPT_OBJECT")
                        (IsObject(oRoot[oM.1][oM.2]))
                       ? oRoot[oM.1][oM.2].Value := oM.3
                       : oRoot[oM.1][oM.2] := { Value: oM.3 }
                    else oRoot[oM.1][oM.2] := oM.3
                }
                else throw ValueError("Wrong parameter format: " A_Args[A_Index])
            }
        }
        
        static __EscapeNewLine(sText)   => StrReplace(sText, "`n", "``n")
        static __UnescapeNewLine(sText) => StrReplace(sText, "``n", "`n")
    }
    
    ; Implements a "Ini" file root.
    ; It manages __Get and __Set request blending the property and item notation.
    ; It defines the "Props" dynamic property and getters/setters to manage object properties.
    class IniRoot extends Map
    {    
        __New(params*)
        {
            if Mod(params.Length, 2) != 0
                throw ValueError("Constructor parameters are property,value pairs.")

            ; We use DefineProp to bypass __Get & __Set.
            this.DefineProp("Props", { Value: Map() })
            this.__SetProps(params*)
            
            super.__New()
            return this
        }
        
        ; Return an item, even if a property has been requested.
        __Get(name, params)
        {
            if this.Has(name)
                return params.Length > 0 ? this[name][params*] : this[name]
            else throw PropertyError("Key not found: " name)
        }
        
        ; Set an item, even if the property notation has been used.
        __Set(name, params, value) => params.Length > 0 ? this[name][params*] := value : this[name] := value
        
        ; We want the user to interact with "properties" only through methods.
        ; Due to the ConfMan.IniInterface object "shadowing" the ConfMan.IniRoot object and 
        ; forwarding method calls to the outer class, these methods will be accessible only if 
        ; using its "Root" prop (eg: <Root.Root.__GetProp("FILENAME")>).
        ; These same methods can, instead, be called directly on ConfMan.IniSection objects
        ; (eg: <Root["section"].__GetProp("NAME")> or <Root.section.__GetProp("NAME")>).
        
        __GetProp(name)        => this.Props[name]
        __GetProps()           => this.Props
        __SetProp(name, value) => this.Props[name] := value
        __SetProps(params*)
        {
            tmp := Map(), idx := 1
            Loop params.Length//2
            {
                prop := params[idx]
                tmp[prop] := params[idx+1]
                idx += 2
            }
            
            if !tmp.Has("FILENAME")
                throw ValueError("IniRoot objects need at least a FILENAME property.")
            
            if !FileExist(RegExReplace(tmp["FILENAME"], "[^\\]+$"))
                throw ValueError("File path not valid: " tmp["FILENAME"])
            
            this.Props := tmp
        }
    }
    
    ; Implements a "Ini" file section.
    ; ConfMan.IniSection class extends ConfMan.IniRoot adding the management of section options.
    ; ConfMan.IniSection "options" are boolean flags built on top of ConfMan.IniRoot properties.
    class IniSection extends ConfMan.IniRoot
    {
        __New(params*) => super.__New(params*)
        
        ; Override the __SetProps method to enforce specific checks.
        __SetProps(params*)
        {
            tmp := Map(), idx := 1
            Loop params.Length//2
            {
                prop := params[idx]
                tmp[prop] := params[idx+1]
                idx += 2
            }
            
            if !tmp.Has("NAME")
                throw ValueError("IniSection objects need at least a NAME property.")  
                
            this.Props := tmp
        }
        
        ; Build on top of __GetProp, to return a single option.
        GetOpt(sOpt) => this.__GetProp("OPT_" sOpt)
        
        ; Build on top of __SetProp to set a list of section options.
        ; If it's present in the string, set the relative option to 1, otherwise to 0.
        SetOpts(sOpts)
        {
            if InStr(sOpts, "LOCKED") && InStr(sOpts, "PARAMS")
                throw ValueError("IniSection objects can't be locked and overridden by parameters.")            

            for k in this.__GetProps()
                (RegExMatch(k, "OPT_([\w]+)", &oM:=0)) && this.__SetProp(k, InStr(sOpts, oM.1) ? 1 : 0)
        }
    }
    
    ; Acts as a proxy for all object interactions dispatching calls/requests to the sibling/parent classes.
    class IniInterface extends Buffer
    {
        __New(sFileName, funcs*)
        {
            ; "Inject" the function objects in the ConfMan.IniFuncs class if there are any.
            ; Each function must declare two parameters: "this" and the IniRoot object.
            loop funcs.Length
            {
                if IsObject(funcs[A_Index]) && funcs[A_Index].HasMethod()
                    ConfMan.IniFuncs.DefineProp(funcs[A_Index].name, { Call: funcs[A_Index] })
                else throw ValueError("funcs* items must be function objects.")
            }
            
            ; Initialize the Buffer properties.
            super.__New()
            
            ; We use the Buffer "Ptr" property as Map key for our objects central storage.
            ; That object will be removed at this object release by the __Delete meta function.
            ConfMan.objStor[this.Ptr] := ConfMan.IniRoot("FILENAME", sFileName)
            
            ; Define the Root property to have a ready access to the IniRoot object in the storage.
            this.DefineProp("Root", { Value: ConfMan.objStor[this.Ptr] })
            return this
        }
        
        ; Remove the object from the central storage.
        __Delete() => (IsObject(this.Root)) && ConfMan.objStor.Delete(this.Ptr)
        
        ; Forward method calls to the IniFuncs class.
        __Call(name, params) => ConfMan.IniFuncs.%name%(this.Root)
        
        ; Forward property requests to the IniRoot object.
        __Get(name, params) => this.Root.__Get(name, params)
        
        ; Create a "translation" layer that allows only selected operations. More specifically:
        ; * Allow <Root["section"]["key"] := value> notation.
        ; * Allow defining sections with the literal notation, translating properties to items:
        ;   <Root.section := { key1: value, ..., keyN: value }>
        
        __Set(name, params, value)
        {            
            ; Disallow setting non-object properties but only if there are no parameters [] in the call.
            ; This to allow item notation assignments for simple key:value pairs that will be managed next.
            
            if !params.Length && !IsObject(value)
                throw ValueError("IniRoot properties can be only objects defined with literal notation.")
            
            ; Disallow Root["section"]["param1",..,"paramN"] calls.
            if params.Length > 1
                throw PropertyError("IniSection properties are simple key:value pairs.")
            
            ; Create the IniSection object as IniRoot item in the central storage, if not present.
            (!this.Root.Has(name)) && this.Root[name] := ConfMan.IniSection( "NAME",        name
                                                                           , "OPT_LOCKED",  0
                                                                           , "OPT_NOWRITE", 0
                                                                           , "OPT_NOEXKEY", 0
                                                                           , "OPT_PARAMS",  0
                                                                           , "OPT_OBJECT",  0 )
            
            ; Allow item notation assignments (eg: <Root["section"]["key"] := value>).
            if params.Length
                return this.Root[name][params*] := value
            
            ; Translate object literal notation into item notation.
            for k,v in value.OwnProps()
                this.Root[name][k] := v
            
            ; Return for assignments chain.
            return this.Root[name]
        }
        
        ; Redirect __Item calls to __Get & __Set (eg: Root["section"]).
        __Item[params]
        {
            get => this.__Get(params, [])
            set => this.__Set(params, [], value)
        }
    }
}

/* Test Code:

#Include <Class_ConfMan>

a := ConfMan.GetConf("c:\test.ini", functest, functestobj)

a.WWWW :=
{
  WHAT  : "Nothing"
, WHO   : "No one" 
, WHERE : "Nowhere"
, WHEN  : "Never"
}

a.WWWW.SetOpts("OBJECT PARAMS")
a.WriteFile()

Msgbox a.functest()

a.ReadFile()

Msgbox a.functestobj()


functest(this, oRoot)
{
    return oRoot.WWWW.WHAT
}

functestobj(this, oRoot)
{
    return oRoot.WWWW.WHO.Value
}

*/