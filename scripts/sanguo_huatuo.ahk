#Requires AutoHotkey v2.0
#SingleInstance force

; 设置工作目录为脚本所在目录
SetWorkingDir(A_ScriptDir)

; ========== 全局变量 ==========
global isRunning := false
global totalLoops := 10
global currentLoop := 0
global coords := []
global config := Map()

; 设置使用绝对屏幕坐标
CoordMode("Mouse", "Screen")

; ========== 配置加载 ==========
LoadConfig() {
    global config, coords, totalLoops
    
    ; 加载基本设置
    config["ClickInterval"] := IniRead("..\config\settings.ini", "General", "ClickInterval", "2000")
    config["AutoStart"] := IniRead("..\config\settings.ini", "General", "AutoStart", "false")
    
    ; 加载华佗任务配置
    totalLoops := Integer(IniRead("..\config\settings.ini", "Tasks", "HuaTuoLoops", "10"))
    coords := ParseCoords(IniRead("..\config\settings.ini", "Tasks", "HuaTuoCoords", "1255,235|1260,770|1080,670|1070,345|1070,600|1070,800"))
    
    ; 显示加载的配置信息
    ToolTip("配置已加载：`n"
        . "总轮数: " totalLoops "`n"
        . "坐标数: " coords.Length "`n"
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

; ========== 主函数 ==========
Main() {
    ; 加载配置
    LoadConfig()
    
    ToolTip("三国召唤华佗脚本已启动，按F1开始/暂停，按F2停止")
    SetTimer(CheckStatus, 1000)
    
    ; 如果配置了自动开始，则启动脚本
    if (config["AutoStart"] = "true") {
        isRunning := true
    }
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
            Sleep(300000)  ; 每轮之间等待5分钟（300000毫秒）
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
        . "1. 自动点击指定坐标位置召唤华佗`n"
        . "2. 每轮包含5个点击位置`n"
        . "3. 点击间隔为2秒`n"
        . "4. 每轮之间等待5分钟`n"
        . "5. 默认执行10轮`n`n"
        . "配置说明：`n"
        . "1. 在config/settings.ini中修改点击坐标`n"
        . "2. 可以调整点击间隔和等待时间`n"
        . "3. 可以修改总轮数", "三国召唤华佗脚本帮助")
}

; ========== 工具函数 ==========
RemoveToolTip() {
    ToolTip()
}

; ========== 启动脚本 ==========
Main() 