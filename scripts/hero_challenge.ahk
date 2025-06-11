#Requires AutoHotkey v2.0
#SingleInstance Force

; 设置坐标模式为屏幕绝对坐标
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")
CoordMode("Pixel", "Screen")  ; 添加像素坐标模式

; 全局变量
global intervalTime := 30  ; 默认间隔30秒
global maxCount := 30      ; 默认执行30次
global currentCount := 0   ; 当前执行次数
global isRunning := false
global clickTimer := 0
global statusTip := ""
global MyGui := 0
global configFile := A_ScriptDir "\..\config\settings.ini"
global isGroupAttack := false  ; 是否集结攻击

; 定义坐标序列
global defaultCoords := "945,640|1080,700|1140,300|1080,800"
global groupAttackCoords := "945,640|1080,700|1120,300|1080,800"  ; 集结攻击的坐标序列

; 从配置文件加载设置
LoadSettings() {
    global intervalTime, maxCount, currentCount, isGroupAttack
    
    if (FileExist(configFile)) {
        intervalTime := IniRead(configFile, "HeroChallenge", "Interval", "30")
        maxCount := IniRead(configFile, "HeroChallenge", "Count", "30")
        currentCount := IniRead(configFile, "HeroChallenge", "CurrentCount", "0")
        isGroupAttack := IniRead(configFile, "HeroChallenge", "IsGroupAttack", "false")
    }
}

; 保存设置到配置文件
SaveSettings() {
    global intervalTime, maxCount, currentCount, isGroupAttack
    
    if (FileExist(configFile)) {
        IniWrite(intervalTime, configFile, "HeroChallenge", "Interval")
        IniWrite(maxCount, configFile, "HeroChallenge", "Count")
        IniWrite(currentCount, configFile, "HeroChallenge", "CurrentCount")
        IniWrite(isGroupAttack, configFile, "HeroChallenge", "IsGroupAttack")
    }
}

; 加载设置
LoadSettings()

; 创建主窗口
MyGui := Gui("+Resize")  ; 添加可调整大小的样式
MyGui.Title := "煮酒论英雄-个人挑战"
MyGui.SetFont("s10")  ; 设置字体大小
MyGui.Add("Text", "w260", "煮酒论英雄-个人挑战")

; 添加设置
MyGui.Add("Text", "w260", "间隔时间 (秒):")
IntervalEdit := MyGui.Add("Edit", "w260", intervalTime)
MyGui.Add("Text", "w260", "执行次数:")
CountEdit := MyGui.Add("Edit", "w260", maxCount)

; 添加攻击模式选择
MyGui.Add("Text", "w260", "攻击模式:")
Radio1 := MyGui.Add("Radio", "w260 vAttackMode" (isGroupAttack ? "" : " Checked"), "单独攻击")
Radio2 := MyGui.Add("Radio", "w260" (isGroupAttack ? " Checked" : ""), "集结攻击")

; 添加事件处理
Radio1.OnEvent("Click", (*) => UpdateAttackMode(1))
Radio2.OnEvent("Click", (*) => UpdateAttackMode(2))

; 更新攻击模式
UpdateAttackMode(mode) {
    global isGroupAttack, intervalTime, IntervalEdit
    
    isGroupAttack := mode = 2
    
    ; 根据攻击模式更新间隔时间
    if (isGroupAttack) {
        intervalTime := 200  ; 集结攻击默认200秒
    } else {
        intervalTime := 30   ; 单独攻击默认30秒
    }
    
    ; 更新间隔时间输入框
    IntervalEdit.Value := intervalTime
    
    ; 保存设置
    SaveSettings()
    
    ; 显示提示
    ShowStatusTip("已切换到" (isGroupAttack ? "集结攻击" : "单独攻击") "模式 - 间隔时间: " intervalTime "秒")
    
    ; 显示当前坐标序列
    ShowCoordinateSequence()
}

; 显示当前坐标序列
ShowCoordinateSequence(*) {
    global isGroupAttack, defaultCoords, groupAttackCoords
    
    coords := isGroupAttack ? groupAttackCoords : defaultCoords
    coordArray := StrSplit(coords, "|")
    
    sequence := "当前点击序列：`n"
    for index, coord in coordArray {
        xy := StrSplit(coord, ",")
        x := xy[1]
        y := xy[2]
        sequence .= index ". X" x " Y" y "`n"
        
        ; 如果是集结攻击且是第三个位置，添加额外的点击
        if (isGroupAttack && index = 3) {
            sequence .= "3.5. X1070 Y595 (集结模式额外点击)`n"
        }
    }
    
    MsgBox(sequence, "当前点击序列")
}

; 添加控制按钮
StartButton := MyGui.Add("Button", "w260", "《开始挑战》").OnEvent("Click", StartChallenge)
StopButton := MyGui.Add("Button", "w260", "停止挑战").OnEvent("Click", StopChallenge)
CurrentCountText := MyGui.Add("Text", "w260", "当前执行次数: " currentCount)
MyGui.Add("Button", "w260", "重置计数").OnEvent("Click", ResetCount)
MyGui.Add("Button", "w260", "显示当前序列").OnEvent("Click", ShowCoordinateSequence)
MyGui.Add("Text", "w260 vShortcutText", "快捷键: F1=开始/停止 F2=重载 F3=帮助")

; 显示窗口并设置位置
MyGui.Show()
WinGetPos(&X, &Y, &Width, &Height, "煮酒论英雄-个人挑战")
MyGui.Move(0, A_ScreenHeight - Height - 50)

; 显示状态提示
ShowStatusTip(text) {
    global statusTip
    statusTip := text
    ToolTip(text, A_ScreenWidth/2, A_ScreenHeight/2)
    SetTimer(() => ToolTip(), -3000)
}

; 执行点击序列
PerformClickSequence() {
    global currentCount, CurrentCountText, isRunning, maxCount, isGroupAttack, defaultCoords, groupAttackCoords
    
    if (!isRunning)
        return
    
    ; 检查是否达到最大次数
    if (currentCount >= maxCount) {
        StopChallenge()
        ShowStatusTip("已完成" maxCount "次挑战")
        return
    }
    
    ; 根据攻击模式选择坐标序列
    coords := isGroupAttack ? groupAttackCoords : defaultCoords
    coordArray := StrSplit(coords, "|")
    
    ; 点击序列
    for index, coord in coordArray {
        xy := StrSplit(coord, ",")
        x := xy[1]
        y := xy[2]
        
        ToolTip("点击位置 " index ": X" x " Y" y, x + 20, y + 20)
        Click(x " " y)
        
        ; 第二个位置后等待更长时间以处理弹窗
        if (index = 2) {
            Sleep(2000)  ; 等待2秒处理弹窗
        } else {
            Sleep(1000)  ; 其他位置等待1秒
        }
        
        ToolTip()
        
        ; 如果是集结攻击且是第三个位置，添加额外的点击
        if (isGroupAttack && index = 3) {
            ToolTip("点击位置 3.5: X1070 Y595", 1070 + 20, 595 + 20)
            Click("1070 595")
            Sleep(1000)
            ToolTip()
        }
    }
    
    ; 更新计数
    currentCount += 1
    CurrentCountText.Text := "当前执行次数: " currentCount
    SaveSettings()  ; 保存当前计数
}

; 开始挑战
StartChallenge(*) {
    global intervalTime, maxCount, isRunning, clickTimer, currentCount, isGroupAttack
    
    ; 获取设置的值
    isGroupAttack := MyGui["AttackMode"].Value = 2  ; 更新攻击模式
    
    ; 根据攻击模式设置默认间隔时间
    if (isGroupAttack) {
        intervalTime := 200  ; 集结攻击默认200秒
    } else {
        intervalTime := 30   ; 单独攻击默认30秒
    }
    
    ; 更新间隔时间输入框
    IntervalEdit.Value := intervalTime
    
    maxCount := CountEdit.Value
    
    ; 检查是否已经完成
    if (currentCount >= maxCount) {
        ShowStatusTip("已达到设定的执行次数，请重置后重试")
        return
    }
    
    isRunning := true
    
    ; 立即执行第一次
    PerformClickSequence()
    
    ; 设置定时器
    clickTimer := SetTimer(PerformClickSequence, intervalTime * 1000)
    
    ShowStatusTip("已开始挑战 - 间隔: " intervalTime "秒 - 目标次数: " maxCount " - 模式: " (isGroupAttack ? "集结攻击" : "单独攻击"))
}

; 停止挑战
StopChallenge(*) {
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
    ShowStatusTip("已停止挑战")
}

; 重置计数
ResetCount(*) {
    global currentCount, CurrentCountText
    currentCount := 0
    CurrentCountText.Text := "当前执行次数: 0"
    SaveSettings()  ; 保存重置后的计数
    ShowStatusTip("执行次数已重置")
}

; 按ESC键退出程序
#HotIf WinActive("ahk_class AutoHotkeyGUI")
Esc::ExitApp()
#HotIf

; F1 切换开始/停止
F1::ToggleChallenge()

; F2 重载脚本
F2::Reload()

; F3 显示帮助
F3::ShowHelp()

; 切换开始/停止
ToggleChallenge() {
    global isRunning
    
    if (isRunning) {
        StopChallenge()
    } else {
        StartChallenge()
    }
}

; 显示帮助
ShowHelp() {
    helpText := "快捷键说明：`n"
        . "F1 - 开始/停止挑战`n"
        . "F2 - 重载脚本`n"
        . "F3 - 显示此帮助信息`n`n"
        . "功能说明：`n"
        . "1. 设置间隔时间（默认30秒，集结攻击默认200秒）`n"
        . "2. 设置执行次数（默认30次）`n"
        . "3. 选择攻击模式（单独/集结）`n"
        . "4. 点击《开始挑战》或按F1开始`n"
        . "5. 执行次数会自动计数，可通过按钮重置"
    
    MsgBox(helpText, "煮酒论英雄-个人挑战帮助")
}

; 关闭窗口时退出
MyGui.OnEvent("Close", (*) => ExitApp()) 