#Requires AutoHotkey v2.0
#SingleInstance Force

; 设置坐标模式为屏幕绝对坐标
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")

; 全局变量
global clickX := 0
global clickY := 0
global clickInterval := 0
global isDoubleClick := false
global doubleClickInterval := 0.1
global isRunning := false
global clickTimer := 0
global statusTip := ""
global captureMode := false
global lastClickTime := 0
global pendingClick := false
global clickPosTemp := {x: 0, y: 0}
global doubleClickTimeout := 0
global totalClicks := 0

; 创建主窗口
MyGui := Gui("+Resize")  ; 添加可调整大小的样式
MyGui.Title := "自动点击器"
MyGui.SetFont("s10")  ; 设置字体大小
MyGui.Add("Text", "w260", "自动点击器")
MyGui.Add("Button", "w260", "点击捕获位置").OnEvent("Click", StartCapture)
ClickPosText := MyGui.Add("Text", "w260", "点击位置: 未设置")
ClickModeText := MyGui.Add("Text", "w260", "点击模式: 未设置")
MyGui.Add("Button", "w260", "测试点击").OnEvent("Click", TestClick)
MyGui.Add("Text", "w260", "设置间隔时间 (秒):")
IntervalNumber := MyGui.Add("Edit", "w260", "1")
MyGui.Add("Button", "w260", "开始点击").OnEvent("Click", StartClicking)
MyGui.Add("Button", "w260", "停止点击").OnEvent("Click", StopClicking)
TotalClicksText := MyGui.Add("Text", "w260", "总点击次数: 0")
MyGui.Add("Button", "w260", "重置点击计数").OnEvent("Click", ResetClickCount)

; 显示窗口
MyGui.Show()

; 显示状态提示
ShowStatusTip(text) {
    global statusTip
    statusTip := text
    ToolTip(text, A_ScreenWidth/2, A_ScreenHeight/2)  ; 在屏幕中央显示提示
    SetTimer(() => ToolTip(), -3000)  ; 3秒后自动消失
}

; 显示鼠标坐标
ShowMouseCoords() {
    MouseGetPos(&x, &y)
    ToolTip("X: " x " Y: " y "`n点击确定此位置`n单击或双击将被自动检测`n按ESC取消", x + 20, y + 20)
}

; 开始捕获模式
StartCapture(*) {
    global captureMode
    captureMode := true
    SetTimer(ShowMouseCoords, 10)  ; 每10ms更新一次
    ShowStatusTip("移动鼠标到目标位置，点击设置坐标")
    
    ; 注册全局热键
    Hotkey("LButton", CaptureClick, "On")
    Hotkey("Escape", CancelCapture, "On")
}

; 取消捕获
CancelCapture(*) {
    global captureMode, pendingClick, doubleClickTimeout
    if (!captureMode)
        return
        
    captureMode := false
    SetTimer(ShowMouseCoords, 0)
    ToolTip()
    
    ; 清理可能存在的双击检测计时器
    if (doubleClickTimeout) {
        SetTimer(doubleClickTimeout, 0)
        doubleClickTimeout := 0
    }
    
    pendingClick := false
    
    ; 注销全局热键
    Hotkey("LButton", "Off")
    Hotkey("Escape", "Off")
    
    ShowStatusTip("已取消捕获")
}

; 捕获点击
CaptureClick(*) {
    global clickX, clickY, isDoubleClick, captureMode, pendingClick, clickPosTemp
    global doubleClickTimeout, ClickPosText, ClickModeText
    
    if (!captureMode)
        return
    
    ; 获取点击坐标
    MouseGetPos(&currentX, &currentY)
    
    ; 如果已经有一个挂起的点击，这是第二次点击（双击）
    if (pendingClick) {
        ; 清除挂起的超时计时器
        if (doubleClickTimeout) {
            SetTimer(doubleClickTimeout, 0)
            doubleClickTimeout := 0
        }
        
        pendingClick := false
        isDoubleClick := true
        clickX := clickPosTemp.x
        clickY := clickPosTemp.y
        
        ; 完成捕获
        FinishCapture()
    } else {
        ; 这是第一次点击，记录并等待可能的第二次点击
        pendingClick := true
        clickPosTemp.x := currentX
        clickPosTemp.y := currentY
        
        ; 设置超时，如果没有第二次点击发生，则视为单击
        doubleClickTimeout := SetTimer(SingleClickTimeout, -500)  ; 500ms内没有第二次点击则视为单击
    }
}

; 单击超时处理
SingleClickTimeout() {
    global pendingClick, clickPosTemp, clickX, clickY, isDoubleClick
    
    if (pendingClick) {
        pendingClick := false
        isDoubleClick := false
        clickX := clickPosTemp.x
        clickY := clickPosTemp.y
        
        ; 完成捕获
        FinishCapture()
    }
}

; 完成捕获过程
FinishCapture() {
    global captureMode, clickX, clickY, isDoubleClick, ClickPosText, ClickModeText
    
    ; 停止捕获模式
    captureMode := false
    SetTimer(ShowMouseCoords, 0)
    ToolTip()
    
    ; 注销全局热键
    Hotkey("LButton", "Off")
    Hotkey("Escape", "Off")
    
    ; 更新界面显示
    ClickPosText.Text := "点击位置: X" clickX " Y" clickY
    ClickModeText.Text := "点击模式: " (isDoubleClick ? "双击" : "单击")
    
    ; 显示状态提示
    ShowStatusTip("已设置" (isDoubleClick ? "双击" : "单击") " 位置: X" clickX " Y" clickY)
}

; 测试点击
TestClick(*) {
    global clickX, clickY, isDoubleClick, doubleClickInterval, totalClicks, TotalClicksText
    if (clickX = 0 && clickY = 0) {
        ShowStatusTip("请先设置点击位置！")
        return
    }
    
    ; 执行一次点击
    if (isDoubleClick) {
        Click(clickX " " clickY)
        Sleep(doubleClickInterval * 1000)
        Click(clickX " " clickY)
    } else {
        Click(clickX " " clickY)
    }
    
    ; 更新点击计数（测试点击也计入总数）
    totalClicks += 1
    TotalClicksText.Text := "总点击次数: " totalClicks
    
    ShowStatusTip("测试点击位置: X" clickX " Y" clickY)
}

; 开始点击
StartClicking(*) {
    global clickX, clickY, clickInterval, isDoubleClick, doubleClickInterval, isRunning, clickTimer
    if (clickX = 0 && clickY = 0) {
        ShowStatusTip("请先设置点击位置！")
        return
    }
    
    clickInterval := IntervalNumber.Value
    isRunning := true
    
    ; 立即执行第一次点击
    PerformClick()
    
    ; 设置定时器，持续执行点击
    clickTimer := SetTimer(PerformClick, clickInterval * 1000)
    
    ; 显示开始信息
    mode := isDoubleClick ? "双击" : "单击"
    ShowStatusTip("开始" mode " - 间隔: " clickInterval "秒")
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

; 执行点击
PerformClick() {
    global clickX, clickY, isDoubleClick, doubleClickInterval, isRunning, totalClicks, TotalClicksText
    if (!isRunning)
        return
        
    if (isDoubleClick) {
        Click(clickX " " clickY)
        Sleep(doubleClickInterval * 1000)
        Click(clickX " " clickY)
    } else {
        Click(clickX " " clickY)
    }
    
    ; 更新点击计数（无论单击还是双击都只计数一次）
    totalClicks += 1
    TotalClicksText.Text := "总点击次数: " totalClicks
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

; 关闭窗口时退出
MyGui.OnEvent("Close", (*) => ExitApp())