# ============================================================================
# 等保测评_Windows操作系统检查脚本.ps1
# 用途：Windows操作系统等保测评安全检查（含自动截图取证）
# 适用系统：Windows Server 2016/2019/2022 及 Windows 10/11
# 使用方法：以管理员身份运行 PowerShell，执行 .\等保测评_Windows检查.ps1
# 对应测评项：身份鉴别、访问控制、安全审计、入侵检测
# 截图说明：每个检查项执行后自动全屏截图，保存到 screenshots 子目录
# ============================================================================

# ---------------------- 截图功能模块 ----------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 截图保存目录（与脚本同级的 screenshots 文件夹）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ScreenshotDir = Join-Path $ScriptDir "screenshots"
if (-not (Test-Path $ScreenshotDir)) {
    New-Item -ItemType Directory -Path $ScreenshotDir -Force | Out-Null
}

# 截图编号计数器
$Global:ScreenshotIndex = 0

<#
.SYNOPSIS
    全屏截图并保存为PNG文件
.DESCRIPTION
    调用 .NET System.Drawing 捕获整个虚拟屏幕（支持多显示器），
    在截图右下角叠加时间水印和IP信息，保存到 screenshots 目录。
.PARAMETER Label
    截图标签，用于文件命名和图片水印
.EXAMPLE
    Take-Screenshot -Label "01_系统基本信息"
#>
function Take-Screenshot {
    param([string]$Label)

    $Global:ScreenshotIndex++
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "{0:D2}_{1}_{2}.png" -f $Global:ScreenshotIndex, $Label, $timestamp
    $filePath = Join-Path $ScreenshotDir $fileName

    try {
        # 捕获所有屏幕（支持多显示器）
        $bounds = [System.Drawing.Rectangle]::Empty
        foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
            $bounds = [System.Drawing.Rectangle]::Union($bounds, $screen.Bounds)
        }

        $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

        # ---- 叠加水印信息（右下角） ----
        $watermarkTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # 获取本机IP
        $ipAddr = "N/A"
        try {
            $ipAddr = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
                       Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.' } |
                       Select-Object -First 1 -ExpandProperty IPAddress)
        } catch { }

        $watermarkText = "[$watermarkTime]  IP: $ipAddr  |  $Label"
        $font = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Bold)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        # 半透明黑色背景条
        $textSize = $graphics.MeasureString($watermarkText, $font)
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
        $margin = 8
        $bgRect = New-Object System.Drawing.Rectangle(
            ($bounds.Width - $textSize.Width - $margin * 3),
            ($bounds.Height - $textSize.Height - $margin * 3),
            ($textSize.Width + $margin * 2),
            ($textSize.Height + $margin * 2)
        )
        $graphics.FillRectangle($bgBrush, $bgRect)
        $textPoint = New-Object System.Drawing.PointF(
            ($bgRect.X + $margin),
            ($bgRect.Y + $margin)
        )
        $graphics.DrawString($watermarkText, $font, $textBrush, $textPoint)

        # 保存
        $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)

        # 释放资源
        $graphics.Dispose()
        $bitmap.Dispose()
        $font.Dispose()
        $textBrush.Dispose()
        $bgBrush.Dispose()

        Write-Host "  [截图已保存] $fileName" -ForegroundColor DarkCyan
    }
    catch {
        Write-Host "  [截图失败] $($_.Exception.Message)" -ForegroundColor Red
    }
}
# ---------------------- 截图功能模块 END ----------------------


Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       等保测评 - Windows操作系统安全检查脚本" -ForegroundColor Cyan
Write-Host "       执行时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "       截图保存: $ScreenshotDir" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================================
# 0. 系统基本信息
# 对应测评项：系统基本信息收集
# 说明：收集操作系统版本、补丁级别等基本信息
# ============================================================================

Write-Host "[系统基本信息] 正在收集系统基本信息..." -ForegroundColor Yellow
Write-Host ""

Write-Host "--- systeminfo ---" -ForegroundColor DarkGray
systeminfo | Select-Object -First 20

Write-Host "--- 操作系统版本 ---" -ForegroundColor DarkGray
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, BuildNumber, Version

Write-Host ""
Take-Screenshot -Label "00_systeminfo_系统基本信息"


# ============================================================================
# 一、身份鉴别
# ============================================================================

Write-Host "[身份鉴别] 正在检查身份鉴别相关配置..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# 1.1 用户唯一标识检查
# 对应测评项：身份鉴别 - 用户标识唯一
# ----------------------------------------------------------------------------
Write-Host "  -- 用户唯一标识 --" -ForegroundColor Green
Get-LocalUser | Select-Object Name, SID, Enabled, PasswordLastSet
Write-Host ""
Take-Screenshot -Label "01_Get-LocalUser_用户唯一标识"

# ----------------------------------------------------------------------------
# 1.2 密码策略检查
# 对应测评项：身份鉴别 - 口令复杂度 / 口令长度 / 口令有效期
# ----------------------------------------------------------------------------
Write-Host "  -- 密码策略 --" -ForegroundColor Green
net accounts
Write-Host ""
Write-Host "  [GUI补充检查] 运行 secpol.msc -> 本地安全策略 -> 账户策略 -> 密码策略" -ForegroundColor Magenta
Write-Host "  检查项：密码必须符合复杂性要求、密码最小长度、密码最短/最长使用期限" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "02_net-accounts_密码策略"

# ----------------------------------------------------------------------------
# 1.3 账户锁定策略检查
# 对应测评项：身份鉴别 - 登录失败处理
# ----------------------------------------------------------------------------
Write-Host "  -- 账户锁定策略 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 secpol.msc -> 本地安全策略 -> 账户策略 -> 账户锁定策略" -ForegroundColor Magenta
Write-Host "  检查项：账户锁定持续时间、账户锁定阈值、重置账户锁定计数器的时间间隔" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "03_secpol-锁定策略_账户锁定策略"

# ----------------------------------------------------------------------------
# 1.4 屏幕保护（超时自动退出）检查
# 对应测评项：身份鉴别 - 超时自动退出
# ----------------------------------------------------------------------------
Write-Host "  -- 屏幕保护/超时退出 --" -ForegroundColor Green
Write-Host "  [GUI检查] 个性化 -> 屏幕保护程序" -ForegroundColor Magenta
Write-Host "  检查项：启用屏幕保护、设置等待时间、勾选在恢复时显示登录屏幕" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "04_屏幕保护_超时自动退出"

# ----------------------------------------------------------------------------
# 1.5 远程会话超时检查
# 对应测评项：身份鉴别 - 超时自动退出
# ----------------------------------------------------------------------------
Write-Host "  -- 远程会话超时 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 gpedit.msc -> 计算机配置 -> 管理模板 -> Windows组件 -> 远程桌面服务 -> 会话时间限制" -ForegroundColor Magenta
Write-Host "  检查项：设置已断开会话的时间限制、活动但空闲的会话的时间限制" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "05_gpedit-会话时间_远程会话超时"


# ============================================================================
# 二、访问控制
# ============================================================================

Write-Host "[访问控制] 正在检查访问控制相关配置..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# 2.1 本地用户和组管理检查
# 对应测评项：访问控制 - 用户管理
# ----------------------------------------------------------------------------
Write-Host "  -- 本地用户和组 --" -ForegroundColor Green
Get-LocalUser | Select-Object Name, Enabled, PasswordLastSet, PasswordExpires
Get-LocalGroup | Select-Object Name
Write-Host ""
Write-Host "  [GUI补充检查] 运行 lusrmgr.msc -> 本地用户和组" -ForegroundColor Magenta
Write-Host "  检查项：是否存在多余账户、Guest账户状态、用户组成员" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "06_Get-LocalUser-Group_本地用户和组"

# ----------------------------------------------------------------------------
# 2.2 用户权限分配检查
# 对应测评项：访问控制 - 权限分配 / 最小权限原则
# ----------------------------------------------------------------------------
Write-Host "  -- 用户权限分配 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 secpol.msc -> 本地安全策略 -> 本地策略 -> 用户权限分配" -ForegroundColor Magenta
Write-Host "  检查项：从网络访问此计算机、本地登录、关闭系统等权限分配" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "07_secpol-用户权限_用户权限分配"


# ============================================================================
# 三、安全审计
# ============================================================================

Write-Host "[安全审计] 正在检查安全审计相关配置..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# 3.1 审核策略检查
# 对应测评项：安全审计 - 审计策略
# ----------------------------------------------------------------------------
Write-Host "  -- 审核策略 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 secpol.msc -> 本地安全策略 -> 本地策略 -> 审核策略" -ForegroundColor Magenta
Write-Host "  检查项：审核登录事件、审核对象访问、审核策略更改、审核账户管理等" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "08_secpol-审核策略_审核策略"

# ----------------------------------------------------------------------------
# 3.2 事件日志查看
# 对应测评项：安全审计 - 审计记录
# ----------------------------------------------------------------------------
Write-Host "  -- 事件日志 --" -ForegroundColor Green
Write-Host "  [命令行] 列出所有日志:" -ForegroundColor DarkGray
wevtutil el | Select-Object -First 10
Write-Host "  [命令行] 最近5条安全日志:" -ForegroundColor DarkGray
wevtutil qe Security /c:5 /rd:true /f:text | Select-Object -First 20
Write-Host ""
Write-Host "  [GUI补充检查] 运行 eventvwr.msc -> 事件查看器" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "09_wevtutil_事件日志"


# ============================================================================
# 四、入侵检测
# ============================================================================

Write-Host "[入侵检测] 正在检查入侵防范相关配置..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# 4.1 已安装程序检查
# 对应测评项：入侵防范 - 软件管理
# ----------------------------------------------------------------------------
Write-Host "  -- 已安装程序 --" -ForegroundColor Green
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion |
    Where-Object { $_.DisplayName } |
    Select-Object -First 20
Write-Host ""
Take-Screenshot -Label "10_Get-ItemProperty_已安装程序"

# ----------------------------------------------------------------------------
# 4.2 网络端口检查
# 对应测评项：入侵防范 - 端口与服务管理
# ----------------------------------------------------------------------------
Write-Host "  -- 网络端口 --" -ForegroundColor Green
netstat -ano | Select-Object -First 20
Write-Host ""
Take-Screenshot -Label "11_netstat-ano_网络端口"

# ----------------------------------------------------------------------------
# 4.3 默认共享检查
# 对应测评项：入侵防范 - 共享安全
# ----------------------------------------------------------------------------
Write-Host "  -- 默认共享 --" -ForegroundColor Green
Get-SmbShare | Select-Object Name, Path, Description
Write-Host ""
Write-Host "  注：除默认共享IPC不能关闭，其它均需关闭。" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "12_Get-SmbShare_默认共享"

# ----------------------------------------------------------------------------
# 4.4 防火墙配置检查
# 对应测评项：入侵防范 - 网络边界防护
# ----------------------------------------------------------------------------
Write-Host "  -- 防火墙配置 --" -ForegroundColor Green
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Write-Host ""
Write-Host "  [GUI补充检查] 运行 firewall.cpl -> Windows防火墙" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "13_Get-NetFirewallProfile_防火墙配置"

# ----------------------------------------------------------------------------
# 4.5 远程桌面加密检查
# 对应测评项：通信完整性 - 传输加密
# ----------------------------------------------------------------------------
Write-Host "  -- 远程桌面加密 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 gpedit.msc -> 计算机配置 -> 管理模板 -> Windows组件 -> 远程桌面服务 -> 远程桌面会话主机 -> 安全 -> 远程连接要求使用指定的安全层" -ForegroundColor Magenta
Write-Host "  检查项：是否开启了RDP安全层或SSL加密" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "14_gpedit-RDP加密_远程桌面加密"

# ----------------------------------------------------------------------------
# 4.6 剩余信息保护检查
# 对应测评项：剩余信息保护
# ----------------------------------------------------------------------------
Write-Host "  -- 剩余信息保护 --" -ForegroundColor Green
Write-Host "  [GUI检查] 运行 secpol.msc -> 本地安全策略 -> 本地策略 -> 安全选项" -ForegroundColor Magenta
Write-Host "  检查项：交互式登录：不显示最后的用户名、关机：清除虚拟内存页面文件" -ForegroundColor Magenta
Write-Host ""
Take-Screenshot -Label "15_secpol-安全选项_剩余信息保护"


# ============================================================================
# 完成
# ============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ">>> Windows 操作系统安全检查完成。" -ForegroundColor Cyan
Write-Host ">>> 共截图 $($Global:ScreenshotIndex) 张，保存在: $ScreenshotDir" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Read-Host "按 Enter 键退出"
