#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为脚本所在目录
SetWorkingDir(A_ScriptDir)

; ========== GDI+ 初始化 ==========
#Include Gdip_All.ahk
if !pToken := Gdip_Startup() {
    MsgBox("GDI+ 初始化失败！")
    ExitApp
}

; ========== 全局变量 ==========
global isRunning := false
global config := Map()
global regionStates := Map()  ; 存储区域状态
global regionTexts := Map()   ; 存储区域文本
global redDotStates := Map()  ; 存储红点状态

; 设置使用绝对屏幕坐标
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ========== 检查Tesseract安装 ==========
CheckTesseract() {
    try {
        RunWait('tesseract --version', , "Hide")
        return true
    } catch {
        MsgBox("未检测到Tesseract OCR！`n`n"
            . "请按照以下步骤安装：`n"
            . "1. 访问 https://github.com/UB-Mannheim/tesseract/wiki`n"
            . "2. 下载并安装最新版本`n"
            . "3. 安装时请确保：`n"
            . "   - 勾选'Add to system PATH'`n"
            . "   - 安装中文语言包(chi_sim)`n"
            . "4. 安装完成后重启脚本", "Tesseract未安装")
        return false
    }
}

; ========== 配置加载 ==========
LoadConfig() {
    global config
    
    ; 加载基本设置
    config["ClickInterval"] := IniRead("..\config\settings.ini", "General", "ClickInterval", "2000")
    config["AutoStart"] := IniRead("..\config\settings.ini", "General", "AutoStart", "false")
    
    ; 加载区域配置
    config["Regions"] := Map()
    for section in IniRead("..\config\settings.ini", "Regions") {
        value := IniRead("..\config\settings.ini", "Regions", section)
        parts := StrSplit(value, ",")
        config["Regions"][section] := Map(
            "name", parts[1],
            "x1", Integer(parts[2]),
            "y1", Integer(parts[3]),
            "x2", Integer(parts[4]),
            "y2", Integer(parts[5])
        )
    }
    
    ; 显示加载的配置信息
    ToolTip("配置已加载：`n"
        . "区域数量: " config["Regions"].Count "`n"
        . "点击间隔: " config["ClickInterval"] "ms`n"
        . "自动开始: " config["AutoStart"])
    SetTimer(RemoveToolTip, -3000)
}

; ========== 截图函数 ==========
CaptureRegion(region) {
    ; 创建截图对象
    screenshot := Gdip_BitmapFromScreen(region["x1"] "|" region["y1"] "|" 
        . (region["x2"] - region["x1"]) "|" (region["y2"] - region["y1"]))
    
    ; 保存截图
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filename := "..\images\" region["name"] "_" timestamp ".png"
    Gdip_SaveBitmapToFile(screenshot, filename)
    
    ; 释放资源
    Gdip_DisposeImage(screenshot)
    
    return filename
}

; ========== OCR函数 ==========
PerformOCR(imagePath) {
    try {
        ; 使用Tesseract OCR进行文字识别
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('tesseract "' imagePath '" stdout -l chi_sim')
        text := exec.StdOut.ReadAll()
        return text ? text : "未识别到文字"
    } catch as err {
        return "OCR错误: " err.Message
    }
}

; ========== 检测红点 ==========
DetectRedDot(region) {
    ; 设置颜色容差
    colorVariation := 30  ; 颜色容差范围
    
    ; 计算右上角10x10区域
    dotX1 := region["x2"] - 10  ; 从右边界向左10像素
    dotY1 := region["y1"]       ; 从顶部开始
    dotX2 := region["x2"]       ; 右边界
    dotY2 := region["y1"] + 10  ; 向下10像素
    
    ; 在指定区域内搜索红色像素
    if (PixelSearch(&foundX, &foundY, dotX1, dotY1, dotX2, dotY2, 0xFF0000, colorVariation)) {
        ; 检查周围像素是否也是红色（确认是红点而不是噪点）
        redCount := 0
        loop 10 {
            loop 10 {
                if (PixelGetColor(foundX + A_Index - 5, foundY + A_Index - 5) ~= "0xFF0000") {
                    redCount++
                }
            }
        }
        return redCount >= 10  ; 如果周围有足够多的红色像素，认为是红点
    }
    return false
}

; ========== 分析区域状态 ==========
AnalyzeRegionState() {
    global config, regionTexts, regionStates, redDotStates
    
    ; 遍历所有区域
    for regionKey, region in config["Regions"] {
        ; 检测红点
        hasRedDot := DetectRedDot(region)
        redDotStates[regionKey] := hasRedDot
        
        ; 捕获并识别文本
        imagePath := CaptureRegion(region)
        text := PerformOCR(imagePath)
        
        ; 存储文本
        regionTexts[regionKey] := text
        
        ; 分析状态
        state := AnalyzeText(regionKey, text)
        regionStates[regionKey] := state
        
        ; 显示状态
        ToolTip("区域 [" region["name"] "] 状态: " state "`n"
            . "文本: " text "`n"
            . "红点: " (hasRedDot ? "有" : "无"))
        SetTimer(RemoveToolTip, -1000)
    }
}

; ========== 分析文本状态 ==========
AnalyzeText(regionKey, text) {
    ; 根据不同区域分析状态
    switch regionKey {
        case "AvatarRegion":
            return AnalyzeAvatarState(text)
        case "TitleRegion":
            return AnalyzeTitleState(text)
        case "ResourceRegion":
            return AnalyzeResourceState(text)
        case "PopularityRegion":
            return AnalyzePopularityState(text)
        case "WorkStatusRegion":
            return AnalyzeWorkStatusState(text)
        case "StaminaRegion":
            return AnalyzeStaminaState(text)
        case "CombatPowerRegion":
            return AnalyzeCombatPowerState(text)
        case "BuffRegion":
            return AnalyzeBuffState(text)
        case "ActivityRegion":
            return AnalyzeActivityState(text)
        case "MarchStatusRegion":
            return AnalyzeMarchStatusState(text)
        case "QueueRegion":
            return AnalyzeQueueState(text)
        case "BanditRegion":
            return AnalyzeBanditState(text)
        case "ExpeditionQueueRegion":
            return AnalyzeExpeditionQueueState(text)
        case "MessageRegion":
            return AnalyzeMessageState(text)
        case "ChatRegion":
            return AnalyzeChatState(text)
        case "ConquestRegion":
            return AnalyzeConquestState(text)
        case "HeroRegion":
            return AnalyzeHeroState(text)
        case "BagRegion":
            return AnalyzeBagState(text)
        case "AllianceRegion":
            return AnalyzeAllianceState(text)
        case "TownRegion":
            return AnalyzeTownState(text)
        default:
            return "未知状态"
    }
}

; ========== 区域状态分析函数 ==========
AnalyzeAvatarState(text) {
    if (InStr(text, "疲劳")) {
        return "疲劳"
    }
    return "正常"
}

AnalyzeTitleState(text) {
    return text
}

AnalyzeResourceState(text) {
    return text
}

AnalyzePopularityState(text) {
    return text
}

AnalyzeWorkStatusState(text) {
    if (InStr(text, "空闲")) {
        return "空闲"
    } else if (InStr(text, "工作中")) {
        return "工作中"
    }
    return "未知"
}

AnalyzeStaminaState(text) {
    ; 提取数字
    if (RegExMatch(text, "\d+", &match)) {
        stamina := Integer(match[0])
        if (stamina >= 100) {
            return "体力充足"
        } else if (stamina >= 50) {
            return "体力中等"
        } else {
            return "体力不足"
        }
    }
    return "未知"
}

AnalyzeCombatPowerState(text) {
    return text
}

AnalyzeBuffState(text) {
    return text
}

AnalyzeActivityState(text) {
    return text
}

AnalyzeMarchStatusState(text) {
    if (InStr(text, "行军")) {
        return "行军"
    }
    return "静止"
}

AnalyzeQueueState(text) {
    return text
}

AnalyzeBanditState(text) {
    if (InStr(text, "流寇")) {
        return "有流寇"
    }
    return "无流寇"
}

AnalyzeExpeditionQueueState(text) {
    return text
}

AnalyzeMessageState(text) {
    if (InStr(text, "新消息")) {
        return "有新消息"
    }
    return "无消息"
}

AnalyzeChatState(text) {
    return text
}

AnalyzeConquestState(text) {
    return text
}

AnalyzeHeroState(text) {
    return text
}

AnalyzeBagState(text) {
    return text
}

AnalyzeAllianceState(text) {
    return text
}

AnalyzeTownState(text) {
    return text
}

; ========== 执行操作 ==========
ExecuteAction() {
    global regionStates, redDotStates
    
    ; 遍历所有区域状态，执行相应操作
    for regionKey, state in regionStates {
        ; 检查红点状态
        if (redDotStates[regionKey]) {
            switch regionKey {
                case "MessageRegion":
                    ExecuteMessageAction()
                case "BagRegion":
                    ExecuteBagAction()
                case "HeroRegion":
                    ExecuteHeroAction()
                case "AllianceRegion":
                    ExecuteAllianceAction()
            }
        }
        
        ; 检查文本状态
        switch regionKey {
            case "BanditRegion":
                if (state = "有流寇") {
                    ExecuteBanditAction()
                }
            case "WorkStatusRegion":
                if (state = "空闲") {
                    ExecuteWorkAction()
                }
            case "MarchStatusRegion":
                if (state = "行军") {
                    ExecuteMarchAction()
                }
        }
    }
}

; ========== 具体操作函数 ==========
ExecuteBanditAction() {
    ; 实现流寇相关操作
    ToolTip("执行流寇操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteWorkAction() {
    ; 实现工作相关操作
    ToolTip("执行工作操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteMessageAction() {
    ; 实现消息相关操作
    ToolTip("执行消息操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteMarchAction() {
    ; 实现行军相关操作
    ToolTip("执行行军操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteBagAction() {
    ; 实现行囊相关操作
    ToolTip("执行行囊操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteHeroAction() {
    ; 实现武将相关操作
    ToolTip("执行武将操作")
    SetTimer(RemoveToolTip, -1000)
}

ExecuteAllianceAction() {
    ; 实现同盟相关操作
    ToolTip("执行同盟操作")
    SetTimer(RemoveToolTip, -1000)
}

; ========== 主函数 ==========
Main() {
    ; 检查Tesseract是否安装
    if (!CheckTesseract()) {
        return
    }
    
    ; 加载配置
    LoadConfig()
    
    ToolTip("区域OCR脚本已启动，按F1开始/暂停，按F2停止")
    SetTimer(CheckStatus, 1000)
    
    ; 如果配置了自动开始，则启动脚本
    if (config["AutoStart"] = "true") {
        isRunning := true
    }
}

; ========== 状态检查 ==========
CheckStatus() {
    global isRunning
    if (isRunning) {
        ; 分析区域状态
        AnalyzeRegionState()
        
        ; 执行相应操作
        ExecuteAction()
        
        ; 等待指定时间后继续
        Sleep(config["ClickInterval"])
    }
}

; ========== 热键定义 ==========
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
        . "功能说明：`n"
        . "1. 识别预定义的屏幕区域`n"
        . "2. 分析每个区域的文字内容`n"
        . "3. 根据分析结果执行相应操作`n`n"
        . "配置说明：`n"
        . "1. 在config/settings.ini中修改区域配置`n"
        . "2. 可以调整区域坐标和大小`n"
        . "3. 需要安装Tesseract OCR", "区域OCR脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 退出处理 ==========
ExitFunc(ExitReason, ExitCode) {
    global pToken
    Gdip_Shutdown(pToken)
}

OnExit(ExitFunc)

; ========== 启动脚本 ==========
Main() 
Main() 