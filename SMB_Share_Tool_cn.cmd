@echo off
:: 强制使用 UTF-8 环境
chcp 65001 >nul
SETLOCAL ENABLEDELAYEDEXPANSION

:: 自动请求管理员权限
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
cd /d "%~dp0"

:: --- 核心信息定义（为了防乱码，这里使用变量保护） ---
set "NAME=光速分享"
set "YT=www.youtube.com/@光速分享"
set "GH=github.com/Cotton059/Light-Help"

title SMB 1.0 Share Tool
mode con cols=95 lines=32
color 0F

:MainMenu
cls
echo.
echo   =======================================================================================
echo   #                 S M B   1 . 0   Quick Share Tool (CMD Version)                      #
echo   =======================================================================================
echo.
:: 这里直接输出，不再使用复杂的边框嵌套中文
echo   [ Auth ] : %NAME%
echo   [ Home ] : %YT%
echo   [ Project ] : %GH%
echo.
echo   [ Info ] : 正在开启 SMB 1.0 协议并配置 Everyone 匿名共享权限...
echo   ---------------------------------------------------------------------------------------
echo.

:: --- 权限检测 ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo   [!] Error: Please run as Administrator!
    echo       错误：请使用管理员权限运行！
    pause
    exit /b
)

:: --- 磁盘扫描 ---
echo   [+] Scanning Drives... 正在获取可用驱动器...
echo   ---------------------------------------------------------------------------------------
set counter=1
for /f "skip=1 tokens=1" %%a in ('wmic logicaldisk get name') do (
    set "item=%%a"
    if not "!item!"=="" (
        set "drive[!counter!]=!item!"
        echo      [!counter!]  Drive !item!
        set /a counter+=1
    )
)
echo   ---------------------------------------------------------------------------------------
echo.

set /p driveChoice="   [?] Select Drive Number 请输入数字编号 (1, 2, 3...): "
set "driveLetter=!drive[%driveChoice%]!"

if "!driveLetter!"=="" (
    color 0C
    echo   [!] Invalid Choice. 无效输入。
    timeout /t 3 >nul
    exit /b
)

set /p shareName="   [?] Share Name 请输入共享名称 (e.g. MyShare): "
set "fullPath=!driveLetter!\!shareName!"

:: --- 执行逻辑 ---
cls
echo.
echo   =======================================================================================
echo   Processing... Please wait 1-3 minutes. 正在部署，请稍候...
echo   =======================================================================================
echo.

echo   [1/4] Enabling SMB 1.0... 正在启用协议...
dism /online /enable-feature /featurename:SMB1Protocol /all /norestart >nul

echo   [2/4] Restarting Services... 正在重启服务...
net stop "lanmanserver" /y >nul 2>&1
net start "lanmanserver" >nul 2>&1

if not exist "!fullPath!" (
    echo   [3/4] Creating Folder... 正在创建文件夹: !fullPath!
    mkdir "!fullPath!"
)
echo         Configuring NTFS Permissions... 正在配置权限...
icacls "!fullPath!" /grant Everyone:(OI)(CI)F /t /q >nul

echo   [4/4] Activating Share... 正在开启网络共享...
net share "!shareName!"="!fullPath!" /GRANT:everyone,FULL /REMARK:"Auto-shared" >nul

:: --- 结果展示 ---
echo.
echo   =======================================================================================
if %errorlevel% equ 0 (
    color 0A
    echo   [ SUCCESS ] Done! 部署成功！
    echo   ---------------------------------------------------------------------------------------
    echo     - Path 访问路径: \\%COMPUTERNAME%\!shareName!
    echo     - Local 物理路径: !fullPath!
    echo   ---------------------------------------------------------------------------------------
    echo     * 提示: 如果是首次开启，请重启电脑以生效。
) else (
    color 0C
    echo   [ FAILED ] 部署失败，请检查名称是否冲突。
)
echo   =======================================================================================
echo.
pause
