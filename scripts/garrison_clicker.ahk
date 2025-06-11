#Requires AutoHotkey v2.0
#SingleInstance Force

; 设置坐标模式为屏幕绝对坐标
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")
CoordMode("Pixel", "Screen")  ; 添加像素坐标模式

; 全局变量
global clickX1 := 0
global clickY1 := 0
global clickX2 := 0
global clickY2 := 0
global startTime := "20:00"
global intervalTime := 4
global delayTime := 1
global warriorCount := 2  ; 新增：默认发送2队武将
global isRunning := false
global clickTimer := 0
global statusTip := ""
global captureMode := 0  ; 0: 未捕获, 1: 捕获第一个点, 2: 捕获第二个点
global totalClicks := 0
global MyGui := 0

; 创建主窗口
MyGui := Gui("+Resize")  ; 添加可调整大小的样式
MyGui.Title := "驻防自动点击器"
MyGui.SetFont("s10")  ; 设置字体大小
MyGui.Add("Text", "w260", "驻防自动点击器")

; 添加捕获按钮
CaptureButton := MyGui.Add("Button", "w260", "点击捕获位置")
CaptureButton.OnEvent("Click", StartCapture)
ClickPosText1 := MyGui.Add("Text", "w260", "点击位置1: 未设置")
ClickPosText2 := MyGui.Add("Text", "w260", "点击位置2: 未设置")

; 添加时间设置
MyGui.Add("Text", "w260", "首次启动时间 (HH:MM):")
StartTimeEdit := MyGui.Add("Edit", "w260", startTime)
MyGui.Add("Text", "w260", "间隔时间 (分钟):")
IntervalEdit := MyGui.Add("Edit", "w260", intervalTime)
MyGui.Add("Text", "w260", "延迟时间 (秒，可为负数):")
DelayEdit := MyGui.Add("Edit", "w260", delayTime)
MyGui.Add("Text", "w260", "发送武将数量 (队):")
WarriorCountEdit := MyGui.Add("Edit", "w260", warriorCount)

; 添加控制按钮
StartButton := MyGui.Add("Button", "w260", "开始点击").OnEvent("Click", StartClicking)
StopButton := MyGui.Add("Button", "w260", "停止点击").OnEvent("Click", StopClicking)
TotalClicksText := MyGui.Add("Text", "w260", "总点击次数: 0")
MyGui.Add("Button", "w260", "重置点击计数").OnEvent("Click", ResetClickCount)
MyGui.Add("Text", "w260 vShortcutText", "快捷键: F1=开始/停止 F2=重载 F3=帮助")

; 显示窗口并设置位置
MyGui.Show()
WinGetPos(&X, &Y, &Width, &Height, "驻防自动点击器")
MyGui.Move(0, A_ScreenHeight - Height - 50)

; 显示状态提示
ShowStatusTip(text) {
    global statusTip
    statusTip := text
    ToolTip(text, A_ScreenWidth/2, A_ScreenHeight/2)
    SetTimer(() => ToolTip(), -3000)
}

; 显示鼠标坐标
ShowMouseCoords() {
    MouseGetPos(&x, &y)
    ToolTip("X: " x " Y: " y "`n点击确定此位置`n按ESC取消", x + 20, y + 20)
}

; 开始捕获模式
StartCapture(*) {
    global captureMode, CaptureButton
    captureMode := 1
    SetTimer(ShowMouseCoords, 10)
    ShowStatusTip("移动鼠标到第一个目标位置，点击设置坐标")
    
    CaptureButton.Text := "等待捕获第一个位置..."
    CaptureButton.Opt("+BackgroundFFA500")  ; 橙色背景
    
    Hotkey("LButton", CaptureClick, "On")
    Hotkey("Escape", CancelCapture, "On")
}

; 取消捕获
CancelCapture(*) {
    global captureMode, CaptureButton
    if (!captureMode)
        return
        
    captureMode := 0
    SetTimer(ShowMouseCoords, 0)
    ToolTip()
    
    CaptureButton.Text := "点击捕获位置"
    CaptureButton.Opt("+BackgroundDefault")
    
    Hotkey("LButton", "Off")
    Hotkey("Escape", "Off")
    
    ShowStatusTip("已取消捕获")
}

; 捕获点击
CaptureClick(*) {
    global clickX1, clickY1, clickX2, clickY2, captureMode, CaptureButton, ClickPosText1, ClickPosText2
    
    if (!captureMode)
        return
    
    MouseGetPos(&currentX, &currentY)
    
    if (captureMode = 1) {
        ; 捕获第一个点
        clickX1 := currentX
        clickY1 := currentY
        ClickPosText1.Text := "点击位置1: X" clickX1 " Y" clickY1
        captureMode := 2
        CaptureButton.Text := "等待捕获第二个位置..."
        ShowStatusTip("已设置第一个位置，请移动鼠标到第二个目标位置")
    } else if (captureMode = 2) {
        ; 捕获第二个点
        clickX2 := currentX
        clickY2 := currentY
        ClickPosText2.Text := "点击位置2: X" clickX2 " Y" clickY2
        
        ; 完成捕获
        captureMode := 0
        SetTimer(ShowMouseCoords, 0)
        ToolTip()
        
        Hotkey("LButton", "Off")
        Hotkey("Escape", "Off")
        
        CaptureButton.Text := "已捕获位置"
        CaptureButton.Opt("+Background90EE90")  ; 浅绿色背景
        
        ShowStatusTip("已设置所有点击位置")
    }
}

; 执行点击序列
PerformClickSequence() {
    global clickX1, clickY1, clickX2, clickY2, delayTime, totalClicks, TotalClicksText, isRunning, warriorCount
    
    if (!isRunning)
        return
    
    ; 循环发送指定数量的武将
    Loop warriorCount {
        ; 点击序列 - 使用绝对屏幕坐标
        ToolTip("点击位置 1: X" clickX1 " Y" clickY1, clickX1 + 20, clickY1 + 20)
        Click(clickX1 " " clickY1)  ; 第一个用户捕获的位置
        Sleep(delayTime * 1000)
        ToolTip()
        
        ToolTip("点击位置 2: X" clickX2 " Y" clickY2, clickX2 + 20, clickY2 + 20)
        Click(clickX2 " " clickY2)  ; 第二个用户捕获的位置
        Sleep(delayTime * 1000)
        ToolTip()
        
        ToolTip("点击位置 3: X1080 Y740", 1080 + 20, 740 + 20)
        Click("1080 740")  ; 第三个固定位置
        Sleep(delayTime * 1000)
        ToolTip()
        
        ToolTip("点击位置 4: X1080 Y800", 1080 + 20, 800 + 20)
        Click("1080 800")  ; 第四个固定位置
        Sleep(delayTime * 1000)
        ToolTip()
        
        ; 更新点击计数
        totalClicks += 1
        TotalClicksText.Text := "总点击次数: " totalClicks
        
        ; 如果不是最后一队，等待一下再发送下一队
        if (A_Index < warriorCount) {
            Sleep(100)  ; 等待2秒再发送下一队
        }
    }
}

; 开始点击
StartClicking(*) {
    global clickX1, clickY1, clickX2, clickY2, startTime, intervalTime, delayTime, warriorCount, isRunning, clickTimer
    
    if (clickX1 = 0 && clickY1 = 0 || clickX2 = 0 && clickY2 = 0) {
        ShowStatusTip("请先设置所有点击位置！")
        return
    }
    
    ; 获取设置的值
    startTime := StartTimeEdit.Value
    intervalTime := IntervalEdit.Value
    delayTime := DelayEdit.Value
    warriorCount := WarriorCountEdit.Value
    
    isRunning := true
    
    ; 计算首次执行时间
    currentTime := FormatTime(, "HH:mm")
    currentMinutes := TimeToMinutes(currentTime)
    targetMinutes := TimeToMinutes(startTime)
    
    if (currentMinutes >= targetMinutes) {
        ; 如果当前时间已经超过启动时间，立即开始
        PerformClickSequence()
        clickTimer := SetTimer(PerformClickSequence, intervalTime * 60 * 1000)
    } else {
        ; 否则等待到指定时间
        timeToWait := (targetMinutes - currentMinutes) * 60
        SetTimer(StartDelayedSequence, timeToWait * 1000)
    }
    
    ShowStatusTip("已开始点击 - 间隔: " intervalTime "分钟 - 每次发送" warriorCount "队武将")
}

; 延迟启动序列
StartDelayedSequence() {
    global clickTimer, intervalTime
    PerformClickSequence()
    clickTimer := SetTimer(PerformClickSequence, intervalTime * 60 * 1000)
}

; 将时间转换为分钟数
TimeToMinutes(timeStr) {
    timeParts := StrSplit(timeStr, ":")
    return timeParts[1] * 60 + timeParts[2]
}

; 停止点击
StopClicking(*) {
    global isRunning, clickTimer
    if (!isRunning) {
        ShowStatusTip("当前未在运行")
        return
    }
    
    isRunning := false
    if (clickTimer) {
        SetTimer(clickTimer, 0)
        clickTimer := 0
    }
    ShowStatusTip("已停止点击")
}

; 重置点击计数
ResetClickCount(*) {
    global totalClicks, TotalClicksText
    totalClicks := 0
    TotalClicksText.Text := "总点击次数: 0"
    ShowStatusTip("点击计数已重置")
}

; 按ESC键退出程序(当不在捕获模式时)
#HotIf WinActive("ahk_class AutoHotkeyGUI") and !captureMode
Esc::ExitApp()
#HotIf

; F1 切换开始/停止
F1::ToggleClicking()

; F2 重载脚本
F2::Reload()

; F3 显示帮助
F3::ShowHelp()

; 切换开始/停止
ToggleClicking() {
    global isRunning
    
    if (isRunning) {
        StopClicking()
    } else {
        StartClicking()
    }
}

; 显示帮助
ShowHelp() {
    helpText := "快捷键说明：`n"
        . "F1 - 开始/停止点击`n"
        . "F2 - 重载脚本`n"
        . "F3 - 显示此帮助信息`n`n"
        . "功能说明：`n"
        . "1. 点击《点击捕获位置》按钮设置初始点击位置`n"
        . "2. 设置首次启动时间（默认20:00）`n"
        . "3. 设置间隔时间（默认4分钟）`n"
        . "4. 设置延迟时间（默认1秒，可为负数）`n"
        . "5. 点击《开始点击》或按F1开始`n"
        . "6. 点击次数会自动计数，可通过按钮重置"
    
    MsgBox(helpText, "驻防自动点击器帮助")
}

; 关闭窗口时退出
MyGui.OnEvent("Close", (*) => ExitApp()) 