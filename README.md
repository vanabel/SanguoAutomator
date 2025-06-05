# SanguoAutomator

一个使用AutoHotkey v2.0实现的游戏自动化工具，可以模拟用户点击和键盘操作来完成游戏中的重复性任务。目前支持三国冰河时代游戏的自动化操作。

## 功能特点

✅ 已支持：
- 模拟鼠标点击和移动
- 可配置的自动化脚本
- 支持多任务工作流
- 支持自定义任务序列
- 支持区域截图和OCR文字识别
- 屏幕区域文字识别（OCR）
- 红点提示检测
- 自动执行任务
- 可配置的区域监控
- 状态管理和响应

🚧 开发中：
- 模拟键盘按键
- 支持定时执行
- 支持图像识别

## 系统要求

- Windows 操作系统
- AutoHotkey v2.0（⚠️ 不兼容 v1.x 版本）
- Tesseract OCR（用于文字识别）
- GDI+ 库（用于截图功能）

## 安装步骤

1. 安装 [AutoHotkey v2.0](https://www.autohotkey.com/)
   - 注意：必须安装 v2.0 版本，v1.x 版本不兼容
   - 如果已安装 v1.x，建议先卸载再安装 v2.0

2. 安装 [Tesseract OCR](https://github.com/UB-Mannheim/tesseract/wiki)
   - 下载并安装最新版本
   - 确保将安装目录添加到系统PATH环境变量
   - 安装中文语言包（chi_sim）

3. 克隆此仓库到本地

4. 创建必要的目录：
   ```bash
   mkdir images
   ```

5. 根据需要修改配置文件

## 使用方法

### 基本使用

1. 打开 `scripts` 文件夹
2. 选择要运行的脚本：
   - `sanguo_bandit.ahk`: 仅刷流寇
   - `sanguo_workflow.ahk`: 完整工作流（刷流寇+采集资源）
   - `screenshot_ocr.ahk`: 截图OCR功能

3. 运行脚本（双击 .ahk 文件）

4. 使用快捷键控制脚本：
   - F1: 开始/暂停脚本
   - F2: 停止脚本
   - F3: 显示帮助信息

### 截图OCR功能

`screenshot_ocr.ahk` 脚本提供了以下功能：

1. 自动截取指定区域的屏幕截图
2. 使用OCR识别截图中的文字
3. 显示识别结果

配置说明：
```ini
[Screenshot]
; 截图区域设置（像素坐标）
RegionX1=100
RegionY1=100
RegionX2=300
RegionY2=200

; 截图保存设置
SavePath=..\images
Format=png
Quality=100
```

使用步骤：
1. 在 `config/settings.ini` 中设置截图区域
2. 运行 `screenshot_ocr.ahk`
3. 按 F1 开始截图和OCR识别
4. 识别结果会显示在屏幕上

注意事项：
- 确保已正确安装Tesseract OCR
- 截图区域不要设置太大，以免影响性能
- OCR识别可能需要一定时间，请耐心等待

### 配置说明

所有配置都在 `config/settings.ini` 文件中进行。首次运行前，请确保该文件存在并正确配置。

#### 1. 基本设置

```ini
[General]
ClickInterval=2000        ; 点击间隔（毫秒）
AutoStart=false          ; 是否自动开始（true/false）
```

#### 2. 任务配置

每个任务都可以配置以下参数：
- 名称（Name）
- 点击坐标（Coords）
- 等待时间（Wait）
- 循环次数（Loops）

示例配置：
```ini
[Tasks]
; 刷流寇任务
BanditName=刷流寇
BanditCoords=890,533|1077,649|1078,348|1067,800
BanditWait=52000
BanditLoops=10

; 采集肉任务
CollectMeatName=采集肉
CollectMeatCoords=888,530|1070,740|1070,645|1070,340|1080,800
CollectMeatWait=2000
CollectMeatLoops=1

; 采集木任务
CollectWoodName=采集木
CollectWoodCoords=888,530|1130,740|1070,645|1070,340|1080,800
CollectWoodWait=2000
CollectWoodLoops=1

; 采集煤任务
CollectCoalName=采集煤
CollectCoalCoords=888,530|1200,740|1070,645|1070,340|1080,800
CollectCoalWait=2000
CollectCoalLoops=1

; 采集铁任务
CollectIronName=采集铁
CollectIronCoords=888,530|1270,740|1070,645|1070,340|1080,800
CollectIronWait=2000
CollectIronLoops=1
```

### 修改配置

1. 修改点击坐标：
   - 打开 `config/settings.ini`
   - 找到对应任务的 `Coords` 参数
   - 修改坐标值（格式：X,Y|X,Y|X,Y）
   - 坐标使用屏幕绝对坐标

2. 调整时间参数：
   - `ClickInterval`: 控制每次点击之间的间隔（毫秒）
   - 各任务的 `Wait` 参数：控制任务完成后的等待时间（毫秒）
   - 各任务的 `Loops` 参数：控制任务重复执行的次数

3. 自动启动：
   - 设置 `AutoStart=true` 可以让脚本启动后自动开始运行
   - 设置 `AutoStart=false` 需要手动按 F1 开始运行

### 注意事项

- 配置文件修改后，需要重启脚本才能生效
- 坐标值需要根据实际屏幕分辨率调整
- 时间参数可能需要根据网络延迟和游戏响应速度调整
- 建议先在测试环境中调整参数，确认无误后再用于实际游戏

## 工作流说明

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
AutoStart=false          ; 是否自动开始（true/false）
```

### 2. 区域配置

在 `config/settings.ini` 的 `[Regions]` 部分配置监控区域：

```ini
[Regions]
; 第一行
AvatarRegion=头像区域,870,95,920,145
TitleRegion=爵位区域,920,95,960,145
ResourceRegion=资源区域,960,95,1045,140
PopularityRegion=民心区域,1050,100,1100,140
WorkStatusRegion=工作状态区域,1100,95,1175,140

; 第二行
StaminaRegion=体力区域,870,150,990,160
CombatPowerRegion=战力区域,870,160,970,180
```

每个区域的格式为：`区域名称=显示名称,x1,y1,x2,y2`

### 3. 红点检测

- 每个区域的右上角 10x10 像素区域会被检测红点提示
- 红点检测参数可在脚本中调整：
  - 颜色容差范围（默认：30）
  - 红点判定阈值（默认：10个红色像素）

### 4. 任务配置

在 `config/settings.ini` 的 `[Tasks]` 部分配置自动化任务：

```ini
[Tasks]
; 刷流寇任务
BanditName=刷流寇
BanditCoords=890,533|1077,649|1078,348|1067,800
BanditWait=52000
BanditLoops=10
```

## 使用方法

1. 启动脚本
   - 双击运行 `scripts/screenshot_ocr.ahk`

2. 快捷键
   - F1: 开始/暂停脚本
   - F2: 停止脚本
   - F3: 显示帮助信息

3. 状态监控
   - 脚本会显示每个区域的状态
   - 包括文字识别结果和红点检测结果
   - 根据状态自动执行相应操作

## 功能说明

### 文字识别
- 使用 Tesseract OCR 识别屏幕区域文字
- 支持中文识别
- 可配置识别区域和更新间隔

### 红点检测
- 检测区域右上角的红点提示
- 自动响应红点状态
- 支持多个区域同时监控

### 自动操作
- 根据识别结果自动执行任务
- 支持多种任务类型
- 可配置任务参数和循环次数

## 注意事项

1. 确保游戏窗口不被遮挡
2. 保持游戏界面清晰可见
3. 定期检查识别效果
4. 根据需要调整区域坐标

## 常见问题

1. OCR 识别不准确
   - 检查 Tesseract 中文语言包是否正确安装
   - 调整区域坐标确保文字清晰可见
   - 考虑使用图像预处理提高识别率

2. 红点检测不准确
   - 调整颜色容差范围
   - 检查区域坐标是否正确
   - 确保游戏界面不被遮挡

## 更新日志

### 最新更新
- 添加红点检测功能
- 优化区域监控逻辑
- 增加体力区域监控
- 改进状态显示

## 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 许可证

MIT License