@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: 检查是否为管理员
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 请以管理员身份运行此脚本。
    pause
    exit /b
)

:: 获取用户输入的共享文件夹路径
set /p folderPath=请输入要共享的文件夹路径（例如：C:\Users\YourUser\Documents\iphone）:

:: 检查文件夹路径是否存在
if not exist "%folderPath%" (
    echo 错误：指定的路径不存在：%folderPath%
    pause
    exit /b
)

:: 启用 SMB 协议
echo 启用 SMB 协议...
dism /online /enable-feature /featurename:SMB1Protocol /all /norestart
net stop "lanmanserver"
net start "lanmanserver"

:: 创建并共享文件夹
echo 设置共享文件夹...
net share iphone="%folderPath%" /GRANT:everyone,FULL

echo 完成！SMB 已启用，'%folderPath%' 文件夹已共享。

pause
ENDLOCAL
