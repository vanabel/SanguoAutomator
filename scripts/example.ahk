#NoEnv  ; 推荐使用
#SingleInstance force  ; 强制单实例运行
SetWorkingDir %A_ScriptDir%  ; 确保一致的工作目录

; 全局变量
global isRunning := false
global clickInterval := 1000  ; 点击间隔（毫秒）

; 主函数
Main() {
    ToolTip, 脚本已启动，按F1开始/暂停，按F2停止
    SetTimer, CheckStatus, 1000
    return
}

; 检查状态并执行操作
CheckStatus:
    if (isRunning) {
        ; 在这里添加你的自动化操作
        Click  ; 模拟鼠标点击
        Sleep, %clickInterval%  ; 等待指定时间
    }
return

; 热键定义
F1::  ; 开始/暂停
    isRunning := !isRunning
    if (isRunning) {
        ToolTip, 脚本运行中...
    } else {
        ToolTip, 脚本已暂停
    }
return

F2::  ; 停止
    isRunning := false
    ToolTip, 脚本已停止
return

F3::  ; 显示帮助
    MsgBox, 0, 帮助信息,
    (
    快捷键说明：
    F1 - 开始/暂停脚本
    F2 - 停止脚本
    F3 - 显示此帮助信息
    
    配置说明：
    1. 修改 clickInterval 变量可以调整点击间隔
    2. 在 CheckStatus 标签下添加你的自动化操作
    )
return

; 启动脚本
Main() 