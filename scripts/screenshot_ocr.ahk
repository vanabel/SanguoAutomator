#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为项目根目录
SetWorkingDir(A_ScriptDir "\..")

; ========== 日志函数 ==========
LogMessage(message, level := "INFO") {
    try {
        ; 获取日志目录
        logDir := "logs"
        if !DirExist(logDir)
            DirCreate(logDir)
            
        ; 生成日志文件名（按日期）
        logFile := logDir "\" FormatTime(, "yyyyMMdd") ".log"
        
        ; 格式化日志消息
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        logMessage := timestamp " [" level "] " message "`n"
        
        ; 写入日志文件
        FileAppend(logMessage, logFile)
        
        ; 同时显示在工具提示中
        ToolTip(message)
        SetTimer(RemoveToolTip, -3000)
    } catch as err {
        ToolTip("日志写入错误: " err.Message)
        SetTimer(RemoveToolTip, -3000)
    }
}

; ========== GDI+ 初始化 ==========
#Include Gdip_All.ahk
if !pToken := Gdip_Startup() {
    LogMessage("GDI+ 初始化失败！", "ERROR")
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

; ========== 检查并创建必要的目录 ==========
EnsureDirectories() {
    try {
        ; 创建images目录
        imagesDir := "images"
        if !DirExist(imagesDir) {
            DirCreate(imagesDir)
            LogMessage("创建截图目录: " imagesDir)
        }
        
        ; 创建临时目录
        tempDir := "temp"
        if !DirExist(tempDir) {
            DirCreate(tempDir)
            LogMessage("创建临时目录: " tempDir)
        }
        
        return Map(
            "images", imagesDir,
            "temp", tempDir
        )
    } catch as err {
        LogMessage("创建目录错误: " err.Message, "ERROR")
        return Map()
    }
}

; ========== 检查Tesseract安装 ==========
CheckTesseract() {
    try {
        RunWait('tesseract --version', , "Hide")
        LogMessage("Tesseract OCR 检查通过")
        return true
    } catch as err {
        LogMessage("未检测到Tesseract OCR！请安装Tesseract并确保添加到系统PATH", "ERROR")
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
    try {
        global config
        
        ; 加载基本设置
        config["ClickInterval"] := IniRead("config\settings.ini", "General", "ClickInterval", "2000")
        config["AutoStart"] := IniRead("config\settings.ini", "General", "AutoStart", "false")
        
        ; 加载区域配置
        config["Regions"] := Map()
        
        ; 读取所有区域配置
        regions := IniRead("config\settings.ini", "Regions")
        if (regions != "ERROR") {
            for line in StrSplit(regions, "`n") {
                if (line = "" || SubStr(line, 1, 1) = ";")
                    continue
                    
                parts := StrSplit(line, "=")
                if (parts.Length >= 2) {
                    section := Trim(parts[1])
                    value := Trim(parts[2])
                    valueParts := StrSplit(value, ",")
                    
                    if (valueParts.Length >= 5) {
                        config["Regions"][section] := Map(
                            "name", valueParts[1],
                            "x1", Integer(valueParts[2]),
                            "y1", Integer(valueParts[3]),
                            "x2", Integer(valueParts[4]),
                            "y2", Integer(valueParts[5])
                        )
                    }
                }
            }
        }
        
        LogMessage("配置已加载：区域数量: " config["Regions"].Count 
            . ", 点击间隔: " config["ClickInterval"] "ms"
            . ", 自动开始: " config["AutoStart"])
    } catch as err {
        LogMessage("加载配置错误: " err.Message, "ERROR")
    }
}

; ========== 截图函数 ==========
CaptureRegion(region, regionKey) {
    try {
        ; 获取目录路径
        dirs := EnsureDirectories()
        imagesDir := dirs["images"]
        
        ; 创建截图对象
        screenshot := Gdip_BitmapFromScreen(region["x1"] "|" region["y1"] "|" 
            . (region["x2"] - region["x1"]) "|" (region["y2"] - region["y1"]))
        
        if !screenshot {
            throw Error("截图失败")
        }
        
        ; 保存截图
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        ; 使用英文名称作为文件名前缀
        regionName := Map(
            "AvatarRegion", "avatar",
            "TitleRegion", "title",
            "ResourceRegion", "resource",
            "PopularityRegion", "popularity",
            "WorkStatusRegion", "work_status",
            "StaminaRegion", "stamina",
            "CombatPowerRegion", "combat_power",
            "BuffRegion", "buff",
            "ActivityRegion", "activity",
            "MarchStatusRegion", "march_status",
            "QueueRegion", "queue",
            "BanditRegion", "bandit",
            "ExpeditionQueueRegion", "expedition_queue",
            "MessageRegion", "message",
            "ChatRegion", "chat",
            "ConquestRegion", "conquest",
            "HeroRegion", "hero",
            "BagRegion", "bag",
            "AllianceRegion", "alliance",
            "TownRegion", "town"
        )
        
        ; 获取英文名称，如果不存在则使用区域键名
        namePrefix := regionName.Has(regionKey) ? regionName[regionKey] : regionKey
        filename := imagesDir "\" namePrefix "_" timestamp ".png"
        
        ; 保存图片
        result := Gdip_SaveBitmapToFile(screenshot, filename)
        if (result != 0) {
            throw Error("保存图片失败，错误代码: " result)
        }
        
        ; 验证文件是否成功创建
        if !FileExist(filename) {
            throw Error("文件创建失败: " filename)
        }
        
        ; 释放资源
        Gdip_DisposeImage(screenshot)
        
        LogMessage("截图成功: " filename)
        return filename
    } catch as err {
        LogMessage("截图错误: " err.Message "`n路径: " (filename ?? "未知"), "ERROR")
        return ""
    }
}

; ========== OCR函数 ==========
PerformOCR(imagePath) {
    try {
        if !FileExist(imagePath) {
            throw Error("图片文件不存在: " imagePath)
        }
        
        ; 使用Tesseract OCR进行文字识别
        shell := ComObject("WScript.Shell")
        exec := shell.Exec('tesseract "' imagePath '" stdout -l chi_sim --psm 6')
        text := exec.StdOut.ReadAll()
        
        ; 清理文本
        text := Trim(text)
        if (text) {
            LogMessage("OCR识别成功: " text)
            return text
        } else {
            LogMessage("未识别到文字", "WARNING")
            return "未识别到文字"
        }
    } catch as err {
        LogMessage("OCR错误: " err.Message, "ERROR")
        return "OCR错误: " err.Message
    }
}

; ========== 检测红点 ==========
DetectRedDot(region) {
    try {
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
            hasRedDot := redCount >= 10
            LogMessage("红点检测: " (hasRedDot ? "发现红点" : "未发现红点"))
            return hasRedDot
        }
        LogMessage("红点检测: 未发现红点")
        return false
    } catch as err {
        LogMessage("红点检测错误: " err.Message, "ERROR")
        return false
    }
}

; ========== 分析区域状态 ==========
AnalyzeRegionState() {
    global config, regionTexts, regionStates, redDotStates
    
    ; 遍历所有区域
    for regionKey, region in config["Regions"] {
        try {
            ; 检测红点
            hasRedDot := DetectRedDot(region)
            redDotStates[regionKey] := hasRedDot
            
            ; 捕获并识别文本
            imagePath := CaptureRegion(region, regionKey)
            if (imagePath) {
                text := PerformOCR(imagePath)
                
                ; 存储文本
                regionTexts[regionKey] := text
                
                ; 分析状态
                state := AnalyzeText(regionKey, text)
                regionStates[regionKey] := state
                
                LogMessage("区域 [" region["name"] "] 状态: " state 
                    . "`n文本: " text 
                    . "`n红点: " (hasRedDot ? "有" : "无"))
            }
        } catch as err {
            LogMessage("区域分析错误 [" region["name"] "]: " err.Message, "ERROR")
        }
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
    try {
        LogMessage("脚本启动")
        
        ; 检查Tesseract是否安装
        if (!CheckTesseract()) {
            LogMessage("Tesseract未安装，脚本退出", "ERROR")
            return
        }
        
        ; 确保必要的目录存在
        EnsureDirectories()
        
        ; 加载配置
        LoadConfig()
        
        LogMessage("区域OCR脚本已启动，按F1开始/暂停，按F2停止")
        SetTimer(CheckStatus, 1000)
        
        ; 如果配置了自动开始，则启动脚本
        if (config["AutoStart"] = "true") {
            isRunning := true
            LogMessage("自动开始已启用")
        }
    } catch as err {
        LogMessage("脚本启动错误: " err.Message, "ERROR")
    }
}

; ========== 状态检查 ==========
CheckStatus() {
    global isRunning
    if (isRunning) {
        try {
            ; 分析区域状态
            AnalyzeRegionState()
            
            ; 执行相应操作
            ExecuteAction()
            
            ; 等待指定时间后继续
            Sleep(config["ClickInterval"])
        } catch as err {
            LogMessage("状态检查错误: " err.Message, "ERROR")
        }
    }
}

; ========== 热键定义 ==========
F1:: {  ; 开始/暂停
    global isRunning
    isRunning := !isRunning
    if (isRunning) {
        LogMessage("脚本运行中...")
    } else {
        LogMessage("脚本已暂停")
    }
}

F2:: {  ; 停止
    global isRunning
    isRunning := false
    LogMessage("脚本已停止")
}

F3:: {  ; 显示帮助
    helpMsg := "快捷键说明：`n"
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
        . "3. 需要安装Tesseract OCR"
    LogMessage("显示帮助信息")
    MsgBox(helpMsg, "区域OCR脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 退出处理 ==========
ExitFunc(ExitReason, ExitCode) {
    global pToken
    LogMessage("脚本退出，原因: " ExitReason)
    Gdip_Shutdown(pToken)
}

OnExit(ExitFunc)

; ========== 启动脚本 ==========
Main() 