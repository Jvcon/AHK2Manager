
# AHK2Manager

[English](/README.md) | [中文](/docs/README.md)

基于AutoHotkey(V2.0+)的脚本管理器。

[![Build](https://github.com/Jvcon/AHK2Manager/actions/workflows/main.yml/badge.svg)](https://github.com/Jvcon/AHK2Manager/actions/workflows/main.yml)

## 使用说明

### 切换脚本管理模式

#### 方法 1: 使用命令行自动切换

> [!CAUTION]  
> 使用命令行切换模式，管理器将会移除脚本文件名中的字符，如：`"!,+"` ，重命名后文件名称不可恢复。

```shell
# Swicch to Source Control Mode
AHK2Manager.exe mode sc
# Swicch to Character Mode
AHK2Manager.exe mode char
```

#### 方法 2: 手动设置 `mode` 为 `1`

> 该方法不会更改你的脚本文件.

1. 在 `setting.ini` 中设置 `mode = 1` ，
2. 启动/重启 AHK2Manager 。

### 脚本管理模式

#### 字符模式 (旧模式)

- 文件名不带任何符号前缀，则为守护脚本，并且会随AHK2Manager 启动；
- 文件名带有 `"!"` 前缀，则为临时脚本，通常也是常驻脚本;
- 文件名带有 `"+"` 前缀，则为一次性脚本。

#### 版本控制模式

为了在git/svn仓库中文件命名更美观，使用配置文件来管理脚本类型。

| 类型  | 枚举值  |
|---|---|
| 一次性脚本 | 0   |
| 临时脚本 | 2   |
| 守护脚本 | 3   |

### Hotkey

| 功能  | 快捷键  |
|---|---|
| 唤起启动脚本菜单 | Ctrl + Alt + LButton   |
| 唤起关闭脚本菜单 | Ctrl + Alt + RButton  |
| 唤起启动脚本菜单 | Ctrl + Alt + MButton   |
| 重新加载 | Win + Shift + R   |

## Roadmap

- 支持 "Temp/Once/Daemon" 三种类型脚本管理
- 新增支持白天模式/黑暗模式切换
- 新增多语言支持
- 新增脚本类型的管理模式

## Acknowledgements

- [tex2e/AHKManager](https://github.com/tex2e/AHKManager)
