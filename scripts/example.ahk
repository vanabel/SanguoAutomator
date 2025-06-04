#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为脚本所在目录
SetWorkingDir(A_ScriptDir)

; 全局变量
global isRunning := false
global clickInterval := 1000  ; 点击间隔（毫秒）

; 主函数
Main() {
    ToolTip("脚本已启动，按F1开始/暂停，按F2停止")
    SetTimer(CheckStatus, 1000)
}

; 检查状态并执行操作
CheckStatus() {
    global isRunning, clickInterval
    if (isRunning) {
        ; 在这里添加你的自动化操作
        Click()  ; 模拟鼠标点击
        Sleep(clickInterval)  ; 等待指定时间
    }
}

; 热键定义
F1:: {  ; 开始/暂停
    global isRunning
    isRunning := !isRunning
    if (isRunning) {
        ToolTip("脚本运行中...")
    } else {
        ToolTip("脚本已暂停")
    }
}

F2:: {  ; 停止
    global isRunning
    isRunning := false
    ToolTip("脚本已停止")
}

F3:: {  ; 显示帮助
    MsgBox("快捷键说明：`n"
        . "F1 - 开始/暂停脚本`n"
        . "F2 - 停止脚本`n"
        . "F3 - 显示此帮助信息`n`n"
        . "配置说明：`n"
        . "1. 修改 clickInterval 变量可以调整点击间隔`n"
        . "2. 在 CheckStatus 函数中添加你的自动化操作", "帮助信息")
}

; 启动脚本
Main() 