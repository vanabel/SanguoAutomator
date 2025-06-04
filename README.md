# GameAutomator

一个使用AutoHotkey实现的游戏自动化工具，可以模拟用户点击和键盘操作来完成游戏中的重复性任务。目前支持三国冰河时代游戏的自动化操作。

## 功能特点

- 模拟鼠标点击和移动
- 模拟键盘按键
- 支持定时执行
- 可配置的自动化脚本
- 支持图像识别（需要额外配置）
- 支持多任务工作流
- 支持自定义任务序列

## 系统要求

- Windows 操作系统
- AutoHotkey v1.1 或更高版本

## 安装步骤

1. 安装 [AutoHotkey](https://www.autohotkey.com/)
2. 克隆此仓库到本地
3. 根据需要修改脚本文件

## 使用方法

### 基本使用

1. 打开 `scripts` 文件夹
2. 选择要运行的脚本：
   - `sanguo_bandit.ahk`: 仅刷流寇
   - `sanguo_workflow.ahk`: 完整工作流（刷流寇+采集资源）
3. 运行脚本（双击 .ahk 文件）
4. 使用快捷键控制脚本：
   - F1: 开始/暂停脚本
   - F2: 停止脚本
   - F3: 显示帮助信息

### 工作流说明

当前支持的工作流包括：

1. 基础刷流寇流程
   - 自动点击指定位置
   - 默认执行10轮
   - 每轮间隔70秒

2. 完整工作流
   - 刷流寇（10轮）
   - 采集肉
   - 采集木
   - 采集煤
   - 采集铁

## 配置说明

### 1. 基本配置 (config/settings.ini)

```ini
[General]
ClickInterval=2000        ; 点击间隔（毫秒）
AutoStart=false          ; 是否自动开始

[Hotkeys]
StartStop=F1            ; 开始/暂停快捷键
Stop=F2                 ; 停止快捷键
Help=F3                 ; 帮助快捷键
```

### 2. 任务配置

每个任务都可以配置以下参数：
- 名称
- 点击坐标
- 等待时间
- 循环次数

示例：
```ini
[Tasks]
; 刷流寇任务
BanditName=刷流寇
BanditCoords=890,533|1077,649|1078,348|1067,800
BanditWait=52000
BanditLoops=10
```

### 3. 工作流配置 (config/script_flows.ini)

可以配置多个工作流，每个工作流包含多个任务：

```ini
[Flow1]
Name=基础刷流寇
Description=简单的刷流寇自动化流程
Steps=1
Step1=scripts/sanguo_bandit.ahk

[Flow2]
Name=完整工作流
Description=包含刷流寇和资源采集的完整工作流
Steps=1
Step1=scripts/sanguo_workflow.ahk
```

## 自定义配置

### 1. 修改点击坐标

1. 打开 `config/settings.ini`
2. 找到对应任务的坐标配置
3. 修改坐标值（格式：X,Y|X,Y|X,Y）

### 2. 调整时间参数

1. 打开 `config/settings.ini`
2. 修改以下参数：
   - `ClickInterval`: 点击间隔
   - `DelayBetweenTasks`: 任务间隔
   - 各任务的 `Wait` 参数

### 3. 修改任务顺序

1. 打开 `scripts/sanguo_workflow.ahk`
2. 修改 `taskQueue` 数组中的任务顺序
3. 或创建新的工作流配置文件

## 注意事项

- 使用前请确保游戏窗口处于活动状态
- 建议在测试环境中先进行测试
- 某些游戏可能禁止自动化操作，请遵守游戏规则
- 坐标值需要根据实际屏幕分辨率调整
- 时间参数可能需要根据网络延迟调整

## 常见问题

1. 脚本无法启动
   - 检查是否安装了正确版本的AutoHotkey
   - 检查脚本文件权限

2. 点击位置不准确
   - 检查游戏窗口是否处于活动状态
   - 检查坐标值是否正确
   - 考虑使用相对坐标

3. 时间参数不合适
   - 根据网络延迟调整等待时间
   - 根据游戏响应速度调整点击间隔

## 贡献

欢迎提交 Pull Request 或创建 Issue 来改进项目。

## 许可证

MIT License 