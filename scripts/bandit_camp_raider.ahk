#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为项目根目录
SetWorkingDir(A_ScriptDir "\..")

; ========== 全局变量 ==========
global isRunning := false
global banditCampCoords := []
global banditCampCount := 0
global maxBanditCampCount := 10
global lastBanditCampTime := 0
global banditCampInterval := 300000  ; 5分钟 = 300000毫秒

; ========== 加载配置 ==========
LoadConfig() {
    try {
        ; 加载基本设置
        LogMessage("正在加载配置文件...")
        configPath := "config\settings.ini"
        LogMessage("配置文件路径: " configPath)
        
        maxBanditCampCount := Integer(IniRead(configPath, "Tasks", "BanditCampLoops", "10"))
        banditCampInterval := Integer(IniRead(configPath, "Tasks", "BanditCampWait", "300000"))
        
        ; 加载坐标点
        banditCampCoords := []
        coordsStr := IniRead(configPath, "Tasks", "BanditCampCoords", "")
        LogMessage("读取到的坐标字符串: " coordsStr)
        
        if (coordsStr != "ERROR") {
            for coord in StrSplit(coordsStr, "|") {
                parts := StrSplit(coord, ",")
                if (parts.Length >= 2) {
                    banditCampCoords.Push({
                        x: Integer(parts[1]),
                        y: Integer(parts[2])
                    })
                    LogMessage("添加坐标点: " parts[1] ", " parts[2])
                }
            }
        }
        
        if (banditCampCoords.Length = 0) {
            throw Error("没有找到有效的坐标点配置")
        }
        
        LogMessage("配置已加载：最大次数: " maxBanditCampCount 
            . ", 间隔时间: " (banditCampInterval / 60000) "分钟"
            . ", 坐标点数量: " banditCampCoords.Length)
    } catch as err {
        LogMessage("加载配置错误: " err.Message, "ERROR")
        throw err
    }
}

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
        logMessage := timestamp " [" level "] " message "`r`n"
        
        ; 写入日志文件（使用UTF-8编码）
        FileAppend(logMessage, logFile, "UTF-8")
        
        ; 同时显示在工具提示中
        ToolTip(message)
        SetTimer(RemoveToolTip, -3000)
    } catch as err {
        ToolTip("日志写入错误: " err.Message)
        SetTimer(RemoveToolTip, -3000)
    }
}

; ========== 刷山贼营寨 ==========
RaidBanditCamp() {
    global banditCampCount, maxBanditCampCount, lastBanditCampTime, banditCampInterval, banditCampCoords
    
    ; 检查是否达到最大次数
    if (banditCampCount >= maxBanditCampCount) {
        LogMessage("已达到最大刷山贼次数: " maxBanditCampCount)
        return
    }
    
    ; 检查时间间隔
    currentTime := A_TickCount
    if (currentTime - lastBanditCampTime < banditCampInterval) {
        remainingTime := (banditCampInterval - (currentTime - lastBanditCampTime)) / 1000
        LogMessage("距离下次刷山贼还需等待: " Round(remainingTime) "秒")
        return
    }
    
    ; 随机选择一个坐标
    if (banditCampCoords.Length = 0) {
        LogMessage("坐标点数组为空，重新加载配置")
        LoadConfig()
        if (banditCampCoords.Length = 0) {
            throw Error("没有可用的坐标点")
        }
    }
    
    randomIndex := Random(1, banditCampCoords.Length)
    coord := banditCampCoords[randomIndex]
    
    ; 点击坐标
    Click(coord.x, coord.y)
    LogMessage("点击山贼营寨坐标: " coord.x ", " coord.y)
    
    ; 等待确认按钮出现并点击
    Sleep(1000)
    Click(coord.x + 50, coord.y + 50)  ; 点击确认按钮位置
    
    ; 更新计数和时间
    banditCampCount++
    lastBanditCampTime := currentTime
    
    LogMessage("完成第 " banditCampCount " 次刷山贼")
}

; ========== 主循环 ==========
MainLoop() {
    global isRunning
    if (isRunning) {
        try {
            RaidBanditCamp()
            Sleep(1000)  ; 每秒检查一次
        } catch as err {
            LogMessage("执行错误: " err.Message, "ERROR")
            Sleep(5000)  ; 发生错误时等待5秒再继续
        }
    }
}

; ========== 热键定义 ==========
F1:: {  ; 开始/暂停
    global isRunning, banditCampCount
    isRunning := !isRunning
    if (isRunning) {
        banditCampCount := 0  ; 重置刷山贼计数
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
        . "1. 自动刷山贼营寨`n"
        . "2. 最多执行" maxBanditCampCount "次`n"
        . "3. 每次间隔" (banditCampInterval / 60000) "分钟`n"
        . "4. 随机选择坐标点"
    LogMessage("显示帮助信息")
    MsgBox(helpMsg, "刷山贼营寨脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 主函数 ==========
Main() {
    try {
        LogMessage("刷山贼营寨脚本启动")
        
        ; 加载配置
        LoadConfig()
        
        ; 如果配置了自动开始，则启动脚本
        if (IniRead("config\settings.ini", "General", "AutoStart", "false") = "true") {
            isRunning := true
            LogMessage("自动开始已启用")
        }
        
        LogMessage("按F1开始/暂停，按F2停止，按F3显示帮助")
        SetTimer(MainLoop, 1000)  ; 每秒执行一次主循环
    } catch as err {
        LogMessage("脚本启动错误: " err.Message, "ERROR")
    }
}

; ========== 启动脚本 ==========
Main() 