#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为脚本所在目录的父目录
SetWorkingDir(A_ScriptDir "\..")

; ========== 全局变量 ==========
global isRunning := false
global currentTask := 0
global currentLoop := 0
global totalTasks := 0
global config := Map()

; 设置使用绝对屏幕坐标
CoordMode("Mouse", "Screen")

; ========== 配置加载 ==========
LoadConfig() {
    global config
    config := Map()
    
    ; 加载基本设置
    config["ClickInterval"] := IniRead("config/settings.ini", "General", "ClickInterval", "2000")
    config["AutoStart"] := IniRead("config/settings.ini", "General", "AutoStart", "false")
    
    ; 加载任务配置
    config["Tasks"] := Map()
    
    ; 刷流寇任务
    config["Tasks"]["Bandit"] := Map(
        "name", IniRead("config/settings.ini", "Tasks", "BanditName", "刷流寇"),
        "coords", ParseCoords(IniRead("config/settings.ini", "Tasks", "BanditCoords", "890,533|1077,649|1078,348|1067,800")),
        "wait", IniRead("config/settings.ini", "Tasks", "BanditWait", "52000"),
        "loop", IniRead("config/settings.ini", "Tasks", "BanditLoops", "10")
    )
    
    ; 采集任务
    config["Tasks"]["CollectMeat"] := Map(
        "name", IniRead("config/settings.ini", "Tasks", "CollectMeatName", "采集肉"),
        "coords", ParseCoords(IniRead("config/settings.ini", "Tasks", "CollectMeatCoords", "888,530|1070,740|1070,645|1070,340|1080,800")),
        "wait", IniRead("config/settings.ini", "Tasks", "CollectMeatWait", "2000"),
        "loop", IniRead("config/settings.ini", "Tasks", "CollectMeatLoops", "1")
    )
    
    config["Tasks"]["CollectWood"] := Map(
        "name", IniRead("config/settings.ini", "Tasks", "CollectWoodName", "采集木"),
        "coords", ParseCoords(IniRead("config/settings.ini", "Tasks", "CollectWoodCoords", "888,530|1130,740|1070,645|1070,340|1080,800")),
        "wait", IniRead("config/settings.ini", "Tasks", "CollectWoodWait", "2000"),
        "loop", IniRead("config/settings.ini", "Tasks", "CollectWoodLoops", "1")
    )
    
    config["Tasks"]["CollectCoal"] := Map(
        "name", IniRead("config/settings.ini", "Tasks", "CollectCoalName", "采集煤"),
        "coords", ParseCoords(IniRead("config/settings.ini", "Tasks", "CollectCoalCoords", "888,530|1200,740|1070,645|1070,340|1080,800")),
        "wait", IniRead("config/settings.ini", "Tasks", "CollectCoalWait", "2000"),
        "loop", IniRead("config/settings.ini", "Tasks", "CollectCoalLoops", "1")
    )
    
    config["Tasks"]["CollectIron"] := Map(
        "name", IniRead("config/settings.ini", "Tasks", "CollectIronName", "采集铁"),
        "coords", ParseCoords(IniRead("config/settings.ini", "Tasks", "CollectIronCoords", "888,530|1270,740|1070,645|1070,340|1080,800")),
        "wait", IniRead("config/settings.ini", "Tasks", "CollectIronWait", "2000"),
        "loop", IniRead("config/settings.ini", "Tasks", "CollectIronLoops", "1")
    )
    
    ; 显示加载的配置信息
    ToolTip("配置已加载：`n"
        . "任务数: " config["Tasks"].Count "`n"
        . "点击间隔: " config["ClickInterval"] "ms`n"
        . "自动开始: " config["AutoStart"])
    SetTimer(RemoveToolTip, -3000)
}

; 解析坐标字符串
ParseCoords(coordStr) {
    coords := []
    for coord in StrSplit(coordStr, "|") {
        xy := StrSplit(coord, ",")
        coords.Push([Integer(xy[1]), Integer(xy[2])])
    }
    return coords
}

; 任务队列定义
global taskQueue := []

; ========== 主函数 ==========
Main() {
    global totalTasks, taskQueue, config
    
    ; 加载配置
    LoadConfig()
    
    ; 构建任务队列
    taskQueue := [
        config["Tasks"]["Bandit"],
        config["Tasks"]["CollectMeat"],
        config["Tasks"]["CollectWood"],
        config["Tasks"]["CollectCoal"],
        config["Tasks"]["CollectIron"]
    ]
    
    totalTasks := taskQueue.Length
    ToolTip("三国工作流脚本已启动，按F1开始/暂停，按F2停止")
    SetTimer(CheckStatus, 1000)
    
    ; 如果配置了自动开始，则启动脚本
    if (config["AutoStart"] = "true") {
        isRunning := true
    }
}

; ========== 状态检查 ==========
CheckStatus() {
    global isRunning, currentTask, currentLoop, totalTasks, taskQueue
    if (isRunning) {
        if (currentTask < totalTasks) {
            task := taskQueue[currentTask + 1]
            if (currentLoop < task["loop"]) {
                ; 执行当前任务的点击序列
                for coord in task["coords"] {
                    if (!isRunning)
                        break
                    Click(coord[1], coord[2])
                    ToolTip("任务 [" task["name"] "] 点击位置: " coord[1] ", " coord[2])
                    SetTimer(RemoveToolTip, -1000)
                    Sleep(2000)
                }
                currentLoop++
                ToolTip("任务 [" task["name"] "] 进度: " currentLoop "/" task["loop"])
                Sleep(task["wait"])
            } else {
                currentTask++
                currentLoop := 0
                ToolTip("完成任务 [" task["name"] "]，准备下一个任务")
                SetTimer(RemoveToolTip, -2000)
            }
        } else {
            isRunning := false
            ToolTip("所有任务已完成")
            SetTimer(RemoveToolTip, -3000)
        }
    }
}

; ========== 热键定义 ==========
F1:: {  ; 开始/暂停
    global isRunning, currentTask, currentLoop, totalTasks, taskQueue
    isRunning := !isRunning
    if (isRunning) {
        if (currentTask >= totalTasks) {
            currentTask := 0
            currentLoop := 0
        }
        task := taskQueue[currentTask + 1]
        ToolTip("脚本运行中... 当前任务: " task["name"] " 进度: " currentLoop "/" task["loop"])
    } else {
        ToolTip("脚本已暂停")
    }
}

F2:: {  ; 停止
    global isRunning, currentTask, currentLoop
    isRunning := false
    currentTask := 0
    currentLoop := 0
    ToolTip("脚本已停止")
}

F3:: {  ; 显示帮助
    MsgBox("快捷键说明：`n" 
        . "F1 - 开始/暂停脚本`n"
        . "F2 - 停止脚本`n"
        . "F3 - 显示此帮助信息`n`n"
        . "功能说明：`n"
        . "1. 自动执行多个任务序列`n"
        . "2. 支持自定义点击坐标`n"
        . "3. 支持自定义等待时间`n"
        . "4. 支持自定义循环次数`n"
        . "5. 任务包括：刷流寇、采集资源等`n`n"
        . "配置说明：`n"
        . "1. 在config/settings.ini中修改任务配置`n"
        . "2. 可以调整点击间隔和等待时间`n"
        . "3. 可以修改任务顺序和循环次数", "三国工作流脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 启动脚本 ==========
Main() 