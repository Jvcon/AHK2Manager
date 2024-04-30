
# AHK2Manager

A toolkit to control all running instances of AutoHotkey(V2.0+).

[![Build](https://github.com/Jvcon/AHK2Manager/actions/workflows/main.yml/badge.svg)](https://github.com/Jvcon/AHK2Manager/actions/workflows/main.yml)

## Usage

### Swich Scripts Manage Mode

#### Method 1: Switch mode with command automatically

> [!CAUTION]  
> Use this command to change mode to Source Control Mode, it will rename you file without `"!,+"`, and couldn't recovery.

```shell
# Swicch to Source Control Mode
AHK2Manager.exe mode sc
# Swicch to Character Mode
AHK2Manager.exe mode char
```

#### Method 2: Set the `mode` to `1` manually

> A method doesn't modify your scripts.

1. Set the `mode = 1` in `setting.ini`,
2. Start or reboot the AHK2Manager.

### Scripts Manage Mode

#### Character Mode (Original)

- Filename start without any symbols, means DAEMON script, it will startup when the AHK2Manager started;
- Filename start wtih "!" means TEMP，most was a president script;
- Filename start wtih "+" means ONCE.

#### Source Control Mode

for git/svn repositories, don't want the file name with symbol or space character, use configuration to define type of script.

| Type  | Enum  |
|---|---|
| ONCE | 0   |
| TEMP | 2   |
| DAEMON | 3   |

### Hotkey

| Function  | Hotkey  |
|---|---|
| Start Menu | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>LButton</kbd>   |
| Close Menu | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>RButton</kbd>  |
| Restart Menu | <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>MButton</kbd>   |
| Reload Manager | <kbd>Win</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd>  |

## Roadmap

- Supported "Temp/Once/Daemon" AHK script management
- Add Dark/Light mode adaptation
- Add localization supported
- Support source control mode

## Acknowledgements

- [tex2e/AHKManager](https://github.com/tex2e/AHKManager)
