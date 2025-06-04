#Requires AutoHotkey v2.0
#SingleInstance force

; ========== 全局变量 ==========
global isRunning := false
global totalLoops := 10
global currentLoop := 0
global coords := [[890, 533], [1077, 649], [1078, 348], [1067, 800]]  ; 屏幕坐标

; ========== 主函数 ==========
Main() {
    ToolTip("三国刷流寇脚本已启动，按F1开始/暂停，按F2停止")
    SetTimer(CheckStatus, 1000)
}

; ========== 状态检查 ==========
CheckStatus() {
    global isRunning, totalLoops, currentLoop, coords
    if (isRunning) {
        if (currentLoop < totalLoops) {
            ; 执行点击序列
            for coord in coords {
                if (!isRunning)
                    break
                Click(coord[1], coord[2])
                ToolTip("点击位置: " coord[1] ", " coord[2])
                SetTimer(RemoveToolTip, -1000)
                Sleep(2000)
            }
            currentLoop++
            ToolTip("完成第 " currentLoop "/" totalLoops " 轮")
            Sleep(70000)  ; 每轮之间等待70秒
        } else {
            isRunning := false
            ToolTip("脚本已完成所有 " totalLoops " 轮")
            SetTimer(RemoveToolTip, -3000)
        }
    }
}

; ========== 热键定义 ==========
F1:: {  ; 开始/暂停
    global isRunning, currentLoop, totalLoops
    isRunning := !isRunning
    if (isRunning) {
        ToolTip("脚本运行中... 当前进度: " currentLoop "/" totalLoops)
    } else {
        ToolTip("脚本已暂停")
    }
}

F2:: {  ; 停止
    global isRunning, currentLoop
    isRunning := false
    currentLoop := 0
    ToolTip("脚本已停止")
}

F3:: {  ; 显示帮助
    MsgBox("快捷键说明：`n"
        . "F1 - 开始/暂停脚本`n"
        . "F2 - 停止脚本`n"
        . "F3 - 显示此帮助信息`n`n"
        . "功能说明：`n"
        . "1. 自动点击指定坐标位置`n"
        . "2. 每轮包含4个点击位置`n"
        . "3. 点击间隔为2秒`n"
        . "4. 每轮之间等待70秒`n"
        . "5. 默认执行10轮`n`n"
        . "配置说明：`n"
        . "1. 在config/settings.ini中修改点击坐标`n"
        . "2. 可以调整点击间隔和等待时间`n"
        . "3. 可以修改总轮数", "三国刷流寇脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 启动脚本 ==========
Main()