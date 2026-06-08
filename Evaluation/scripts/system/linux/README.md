# Linux 服务器等保测评检查脚本

## 文件说明
- `等保测评_Linux检查.sh` — Linux 操作系统等保测评一键检查脚本（Bash）

## 适用系统
CentOS 7+ / RHEL 7+ / Ubuntu 18+ / Debian 10+ / 龙蜥 Anolis OS

## 使用方法
```bash
# 1. 上传脚本到目标服务器
scp 等保测评_Linux检查.sh root@目标IP:/tmp/

# 2. SSH 登录目标服务器
ssh root@目标IP

# 3. 赋予执行权限并运行
chmod +x /tmp/等保测评_Linux检查.sh
bash /tmp/等保测评_Linux检查.sh

# 4. 将输出重定向到文件保存
bash /tmp/等保测评_Linux检查.sh 2>&1 | tee /tmp/等保检查结果_$(date +%Y%m%d).log
```

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 系统基本信息 | `cat /etc/*release*` / `ifconfig` / `date` |
| 2 | 身份鉴别 - 用户标识唯一 | `cat /etc/passwd` / `cat /etc/shadow` |
| 3 | 身份鉴别 - 口令复杂度 | `cat /etc/pam.d/system-auth` / `cat /etc/security/pwquality.conf` |
| 4 | 身份鉴别 - 口令有效期 | `cat /etc/login.defs` / `chage -l root` |
| 5 | 身份鉴别 - SSH安全 | `cat /etc/ssh/sshd_config` / `grep PermitRootLogin` |
| 6 | 身份鉴别 - 超时自动退出 | `cat /etc/profile` / `grep TMOUT` |
| 7 | 身份鉴别 - 登录失败处理 | `grep -r "pam_faillock" /etc/pam.d/` |
| 8 | 访问控制 - 权限分配 | `cat /etc/sudoers` |
| 9 | 安全审计 - SELinux | `sestatus` |
| 10 | 安全审计 - 日志服务 | `service rsyslog status` / `service auditd status` |
| 11 | 入侵防范 - 服务端口 | `netstat -ntlp` / `systemctl list-unit-files` |
| 12 | 入侵防范 - 防火墙 | `iptables -L` / `firewall-cmd --list-all` |

## 注意事项
- 需要以 **root 权限** 执行
- 部分命令（如 `cat /etc/shadow`）需要 root 权限才能读取
- 建议将输出重定向到日志文件，方便截图取证
- 龙蜥系统特有的 faillock 检查已包含在内

## 来源文件
- `Evaluation/新版Linux服务器查询命令.txt`
- `Evaluation/龙蜥登录失败策略.txt`
