#NoEnv  ; 推荐使用
#SingleInstance force  ; 强制单实例运行
SetWorkingDir %A_ScriptDir%  ; 确保一致的工作目录

; 全局变量
global isRunning := false
global totalLoops := 10
global currentLoop := 0
global coords := [[890, 533], [1077, 649], [1078, 348], [1067, 800]]  ; 屏幕坐标

; 主函数
Main() {
    ToolTip, 三国刷流寇脚本已启动，按F1开始/暂停，按F2停止
    SetTimer, CheckStatus, 1000
    return
}

; 检查状态并执行操作
CheckStatus:
    if (isRunning) {
        if (currentLoop < totalLoops) {
            ; 执行点击序列
            for index, coord in coords {
                if (!isRunning)
                    break
                Click, % coord[1] ", " coord[2]
                ToolTip, 点击位置: %coord[1]%, %coord[2]%
                SetTimer, RemoveToolTip, -1000
                Sleep, 2000  ; 点击间隔1秒
            }
            currentLoop++
            ToolTip, 完成第 %currentLoop%/%totalLoops% 轮
            Sleep, 70000  ; 每轮之间等待70秒
        } else {
            isRunning := false
            ToolTip, 脚本已完成所有 %totalLoops% 轮
            SetTimer, RemoveToolTip, -3000
        }
    }
return

; 热键定义
F1::  ; 开始/暂停
    isRunning := !isRunning
    if (isRunning) {
        ToolTip, 脚本运行中... 当前进度: %currentLoop%/%totalLoops%
    } else {
        ToolTip, 脚本已暂停
    }
return

F2::  ; 停止
    isRunning := false
    currentLoop := 0
    ToolTip, 脚本已停止
return

F3::  ; 显示帮助
    MsgBox, 0, 三国刷流寇脚本帮助,
    (
    快捷键说明：
    F1 - 开始/暂停脚本
    F2 - 停止脚本
    F3 - 显示此帮助信息
    
    功能说明：
    1. 自动点击指定坐标位置
    2. 每轮包含4个点击位置
    3. 点击间隔为1秒
    4. 每轮之间等待70秒
    5. 默认执行10轮
    
    配置说明：
    1. 在config/settings.ini中修改点击坐标
    2. 可以调整点击间隔和等待时间
    3. 可以修改总轮数
    )
return

; 清除提示
RemoveToolTip:
    ToolTip
return

; 启动脚本
Main()