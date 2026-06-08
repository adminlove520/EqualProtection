# Windows 操作系统等保测评检查脚本

## 文件说明
- `等保测评_Windows检查.ps1` — Windows 操作系统等保测评一键检查脚本（PowerShell），含自动截图取证功能

## 适用系统
Windows Server 2016+ / Windows Server 2019 / 2022 / Windows 10 / 11

## 使用方法
```powershell
# 1. 以管理员身份打开 PowerShell
# 2. 允许执行脚本（首次使用时）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 3. 运行脚本
.\等保测评_Windows检查.ps1
```

## 自动截图功能
脚本会在每个检查项执行后自动全屏截图，保存到 `screenshots/` 子目录。

### 截图命名规则
```
序号_命令名_检查项描述_时间戳.png
```

### 截图清单

| 序号 | 截图文件名（示例） | 对应检查项 | 执行命令 |
|------|-------------------|------------|----------|
| 00 | `00_systeminfo_系统基本信息_*.png` | 系统基本信息 | `systeminfo` |
| 01 | `01_Get-LocalUser_用户唯一标识_*.png` | 用户唯一标识 | `Get-LocalUser` |
| 02 | `02_net-accounts_密码策略_*.png` | 密码策略 | `net accounts` |
| 03 | `03_secpol-锁定策略_账户锁定策略_*.png` | 账户锁定策略 | GUI: secpol.msc |
| 04 | `04_屏幕保护_超时自动退出_*.png` | 超时自动退出 | GUI: 个性化设置 |
| 05 | `05_gpedit-会话时间_远程会话超时_*.png` | 远程会话超时 | GUI: gpedit.msc |
| 06 | `06_Get-LocalUser-Group_本地用户和组_*.png` | 本地用户和组 | `Get-LocalUser` / `Get-LocalGroup` |
| 07 | `07_secpol-用户权限_用户权限分配_*.png` | 用户权限分配 | GUI: secpol.msc |
| 08 | `08_secpol-审核策略_审核策略_*.png` | 审核策略 | GUI: secpol.msc |
| 09 | `09_wevtutil_事件日志_*.png` | 事件日志 | `wevtutil qe Security` |
| 10 | `10_Get-ItemProperty_已安装程序_*.png` | 已安装程序 | `Get-ItemProperty` |
| 11 | `11_netstat-ano_网络端口_*.png` | 网络端口 | `netstat -ano` |
| 12 | `12_Get-SmbShare_默认共享_*.png` | 默认共享 | `Get-SmbShare` |
| 13 | `13_Get-NetFirewallProfile_防火墙配置_*.png` | 防火墙配置 | `Get-NetFirewallProfile` |
| 14 | `14_gpedit-RDP加密_远程桌面加密_*.png` | 远程桌面加密 | GUI: gpedit.msc |
| 15 | `15_secpol-安全选项_剩余信息保护_*.png` | 剩余信息保护 | GUI: secpol.msc |

### 截图水印
每张截图右下角自动叠加水印信息：
- **时间戳**：截图精确时间（如 `2026-06-08 18:48:06`）
- **IP地址**：本机 IPv4 地址（自动获取）
- **检查项标签**：对应的命令和检查项名称

## 覆盖测评项

| 序号 | 测评项 | 检查方式 |
|------|--------|----------|
| 1 | 身份鉴别 - 用户标识唯一 | 命令行: `Get-LocalUser` |
| 2 | 身份鉴别 - 口令复杂度/长度/有效期 | 命令行: `net accounts` + GUI: secpol.msc |
| 3 | 身份鉴别 - 登录失败处理 | GUI: secpol.msc -> 账户锁定策略 |
| 4 | 身份鉴别 - 超时自动退出 | GUI: 屏幕保护 + gpedit.msc 会话时间 |
| 5 | 访问控制 - 用户管理 | 命令行: `Get-LocalUser/Group` + GUI: lusrmgr.msc |
| 6 | 访问控制 - 权限分配 | GUI: secpol.msc -> 用户权限分配 |
| 7 | 安全审计 - 审计策略 | GUI: secpol.msc -> 审核策略 |
| 8 | 安全审计 - 审计记录 | 命令行: `wevtutil` + GUI: eventvwr.msc |
| 9 | 入侵防范 - 软件管理 | 命令行: `Get-ItemProperty` |
| 10 | 入侵防范 - 端口与服务 | 命令行: `netstat -ano` |
| 11 | 入侵防范 - 共享安全 | 命令行: `Get-SmbShare` |
| 12 | 入侵防范 - 防火墙 | 命令行: `Get-NetFirewallProfile` + GUI: firewall.cpl |
| 13 | 通信完整性 - 传输加密 | GUI: gpedit.msc -> RDP安全层 |
| 14 | 剩余信息保护 | GUI: secpol.msc -> 安全选项 |

## 注意事项
- 需要以 **管理员权限** 运行 PowerShell
- 运行前建议将 PowerShell 窗口**最大化**，确保截图完整
- GUI 检查项（标注为 `[GUI检查]`）需要手动打开对应管理工具后，脚本会自动截取当前屏幕
- 截图自动保存到脚本同级的 `screenshots/` 目录

## 来源文件
`Evaluation/Windows操作系统抓包.docx`
