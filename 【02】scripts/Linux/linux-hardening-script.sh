#!/bin/bash
#
# Linux 安全加固脚本

# 描述: 此脚本执行多种安全加固措施，增强 Linux 系统的安全性。
# 支持：Ubuntu、Debian、CentOS、RHEL 等主流发行版
###
#--help                显示帮助信息
#--no-backup           不创建配置备份
#--disable-usb         禁用 USB 存储设备
#--ssh-port PORT       更改 SSH 端口为指定值
#--no-audit            不配置审计系统
#--interactive         交互模式，逐步确认每个更改
#--dry-run             仅显示将执行的操作，不实际更改系统
#--no-parallel         禁用并行处理，顺序执行所有任务
#--skip COMPONENT      跳过指定组件的加固（可用:ssh,firewall,kernel,network,dns,containers）
#--log-file FILE       指定自定义日志文件路径
#--backup-dir DIR      指定自定义备份目录
#--restore FILE        从指定的备份恢复系统配置
#--profile PROFILE     使用预定义的安全配置文件（可用:server,desktop,minimal）
#--no-root-login       禁止 root 用户通过 SSH 登录（默认允许）
###
# 使用方法: 以 root 用户身份运行 ./linux_security_hardening.sh

# 设置并行处理
PARALLEL_SUPPORT=1  # 设置为0禁用并行处理
MAX_PARALLEL_JOBS=4 # 最大并行任务数

# 使用函数实现并行处理
run_parallel() {
    local func="$1"
    local log_msg="$2"
    
    if [ "$PARALLEL_SUPPORT" -eq 1 ]; then
        log "并行执行: $log_msg"
        ($func) &
        
        # 控制并行任务数量 - 使用更兼容的方式
        local job_count=$(jobs -p | wc -l)
        if [ "$job_count" -ge "$MAX_PARALLEL_JOBS" ]; then
            # wait -n 在某些旧版bash中不支持，使用普通wait
            wait $(jobs -p | head -1)  # 等待第一个作业完成
        fi
    else
        log "顺序执行: $log_msg"
        $func
    fi
}

# 等待所有并行任务完成
wait_for_jobs() {
    log "等待所有并行任务完成..."
    wait
    log "所有任务已完成"
}

# 设置日志文件
LOG_FILE="/var/log/security_hardening_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/root/security_backup_$(date +%Y%m%d_%H%M%S)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 配置选项
USE_AUDIT=1
DISABLE_USB=0
CHANGE_SSH_PORT=0
SSH_PORT=22
BACKUP_ENABLED=1
DRY_RUN=0
INTERACTIVE_MODE=0
ALLOW_ROOT_LOGIN=1  # 默认允许root登录

# 错误处理函数
handle_error() {
    local error_code=$1
    local message=$2
    local function_name=$3
    
    log "${RED}错误[$error_code]: $message (在函数 $function_name 中)${NC}"
    
    if [ "$INTERACTIVE_MODE" -eq 1 ]; then
        read -p "是否继续执行脚本?(y/n): " choice
        if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
            log "用户选择中止脚本"
            exit $error_code
        fi
    fi
    
    # 只有在错误非常严重且无法恢复时才退出
    if [ $error_code -gt 20 ]; then
        log "${RED}严重错误，脚本执行中止${NC}"
        exit $error_code
    fi
    
    return $error_code
}

# 恢复函数 - 在错误发生时自动恢复特定操作
rollback_change() {
    local original_file=$1
    local backup_file="$BACKUP_DIR/$(basename "$original_file").bak"
    
    if [ -f "$backup_file" ]; then
        log "${YELLOW}正在恢复文件: $original_file${NC}"
        cp -f "$backup_file" "$original_file"
        return $?
    else
        log "${YELLOW}未找到备份文件，无法恢复: $original_file${NC}"
        return 1
    fi
}

# 安全地应用命令，带有错误处理和重试
safe_run() {
    local cmd="$1"
    local error_msg="$2"
    local function_name="$3"
    local retry_count=3
    local status=1
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] 将执行: $cmd"
        return 0
    fi
    
    # 支持重试
    for ((i=1; i<=retry_count; i++)); do
        # 执行命令并捕获输出和返回值
        local output
        output=$(eval "$cmd" 2>&1)
        status=$?
        
        if [ $status -eq 0 ]; then
            # 命令成功执行
            if [ $i -gt 1 ]; then
                log "在第$i次尝试后命令成功执行"
            fi
            return 0
        else
            # 命令失败
            log "${YELLOW}命令失败(尝试 $i/$retry_count): $cmd${NC}"
            log "${YELLOW}错误输出: $output${NC}"
            sleep 1  # 短暂等待后重试
        fi
    done
    
    # 所有尝试都失败
    log "${RED}命令失败: $cmd${NC}"
    log "${RED}错误输出: $output${NC}"
    handle_error $status "$error_msg" "$function_name"
    return $status
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --help              显示此帮助信息"
    echo "  --no-backup         不创建配置备份"
    echo "  --disable-usb       禁用USB存储"
    echo "  --ssh-port PORT     更改SSH端口为指定值"
    echo "  --no-audit          不配置审计系统"
    echo "  --interactive       交互模式，逐步确认每个更改"
    echo "  --dry-run           仅显示将执行的操作，不实际更改系统"
    echo "  --no-parallel       禁用并行处理，顺序执行所有任务"
    echo "  --skip DNS          不执行DNS安全加固"
    echo "  --skip COMPONENT    跳过指定组件的加固(可用: ssh,firewall,kernel,network,dns,containers)"
    echo "  --log-file FILE     指定自定义日志文件路径"
    echo "  --backup-dir DIR    指定自定义备份目录"
    echo "  --restore FILE      从指定的备份恢复系统配置"
    echo "  --profile PROFILE   使用预定义的安全配置文件(可用: server,desktop,minimal)"
    echo "  --no-root-login     禁止root用户通过SSH登录(默认允许)"
    echo ""
    echo "注意事项:"
    echo "1. 本脚本加固后会保留root本地登录功能，如无法本地登录，请使用恢复脚本"
    echo "2. 恢复脚本路径为: /root/security_backup_日期_时间/restore.sh"
    echo "3. 脚本默认允许root用户通过SSH登录，可用--no-root-login选项禁用"
    echo "4. 如遇登录问题，请尝试执行以下命令："
    echo "   - chmod u+s /bin/su /usr/bin/passwd  (恢复必要SUID权限)"
    echo "   - faillock --user root --reset       (解锁root账户)"
    echo "   - usermod -s /bin/bash root          (恢复root正确shell)"
}

# 处理命令行参数
parse_arguments() {
    SKIP_COMPONENTS=()
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --no-backup)
                BACKUP_ENABLED=0
                ;;
            --disable-usb)
                DISABLE_USB=1
                ;;
            --ssh-port)
                CHANGE_SSH_PORT=1
                SSH_PORT="$2"
                shift
                ;;
            --no-audit)
                USE_AUDIT=0
                ;;
            --interactive)
                INTERACTIVE_MODE=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --no-parallel)
                PARALLEL_SUPPORT=0
                ;;
            --no-root-login)
                ALLOW_ROOT_LOGIN=0
                ;;
            --skip)
                SKIP_COMPONENTS+=("$2")
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift
                ;;
            --restore)
                RESTORE_FILE="$2"
                shift
                # 执行恢复模式
                if [ -f "$RESTORE_FILE" ]; then
                    echo "正在从备份恢复: $RESTORE_FILE"
                    bash "$RESTORE_FILE"
                    exit $?
                else
                    echo "错误: 恢复文件不存在: $RESTORE_FILE"
                    exit 1
                fi
                ;;
            --profile)
                SECURITY_PROFILE="$2"
                shift
                # 根据不同的配置文件设置选项
                case "$SECURITY_PROFILE" in
                    server)
                        USE_AUDIT=1
                        DISABLE_USB=1
                        ;;
                    desktop)
                        USE_AUDIT=0
                        DISABLE_USB=0
                        ;;
                    minimal)
                        USE_AUDIT=0
                        SKIP_COMPONENTS+=("audit" "containers" "dns")
                        ;;
                    *)
                        echo "未知的安全配置文件: $SECURITY_PROFILE"
                        show_help
                        exit 1
                        ;;
                esac
                ;;
            *)
                echo "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    # 处理跳过组件
    for component in "${SKIP_COMPONENTS[@]}"; do
        log "将跳过组件: $component"
        case "$component" in
            ssh)
                SKIP_SSH=1
                ;;
            firewall)
                SKIP_FIREWALL=1
                ;;
            kernel)
                SKIP_KERNEL=1
                ;;
            network)
                SKIP_NETWORK=1
                ;;
            dns)
                SKIP_DNS=1
                ;;
            containers)
                SKIP_CONTAINERS=1
                ;;
            audit)
                USE_AUDIT=0
                ;;
            *)
                log "${YELLOW}警告: 未知组件: $component${NC}"
                ;;
        esac
    done
}

# 检查 root 权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}错误: 此脚本必须以 root 用户身份运行${NC}"
        exit 1
    fi
}

# 创建备份目录
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    echo "创建备份目录: $BACKUP_DIR"
}

# 记录日志函数
log() {
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# 备份函数
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$BACKUP_DIR/$(basename "$1").bak"
        log "已备份: $1"
    else
        log "文件不存在，无法备份: $1"
    fi
}

# 检查Linux发行版和版本
check_os_version() {
    log "${BLUE}[初始化] 检查操作系统版本...${NC}"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        log "检测到操作系统: $OS_NAME $OS_VERSION"
    else
        log "${YELLOW}无法确定操作系统版本，将使用通用配置${NC}"
    fi
}

# 1. 更新系统
update_system() {
    log "${BLUE}[1/15] 开始系统更新...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get upgrade -y
    elif command -v yum &> /dev/null; then
        yum update -y
    elif command -v dnf &> /dev/null; then
        dnf update -y
    else
        log "${YELLOW}未检测到支持的包管理器，跳过系统更新${NC}"
        return 1
    fi
    log "${GREEN}系统更新完成${NC}"
}

# 2. 设置强密码策略
password_policies() {
    log "${BLUE}[2/15] 配置密码策略...${NC}"
    
    backup_file "/etc/login.defs"
    backup_file "/etc/pam.d/common-password"
    
    # 修改密码有效期
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
    
    # 安装并配置 libpam-pwquality
    if command -v apt-get &> /dev/null; then
        apt-get install -y libpam-pwquality
    elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
        if command -v dnf &> /dev/null; then
            dnf install -y libpwquality-devel
        else
            yum install -y libpwquality-devel
        fi
    fi
    
    # 检查 PAM 文件的位置和格式因发行版而异
    PASSWORD_PAM_FILE=""
    for file in "/etc/pam.d/common-password" "/etc/pam.d/system-auth" "/etc/pam.d/password-auth"; do
        if [ -f "$file" ]; then
            PASSWORD_PAM_FILE="$file"
            break
        fi
    done
    
    if [ -n "$PASSWORD_PAM_FILE" ]; then
        backup_file "$PASSWORD_PAM_FILE"
        
        # 检查是否已经包含 pam_pwquality.so
        if grep -q "pam_pwquality.so" "$PASSWORD_PAM_FILE"; then
            sed -i '/pam_pwquality.so/c\password    requisite    pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root' "$PASSWORD_PAM_FILE"
        else
            # 在第一个 password 行之前添加
            sed -i '0,/^password/s//password    requisite    pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root\n&/' "$PASSWORD_PAM_FILE"
        fi
        log "已配置密码复杂度策略"
    else
        log "${YELLOW}未找到有效的 PAM 密码配置文件，跳过密码策略配置${NC}"
    fi
    
    log "${GREEN}密码策略配置完成${NC}"
}

# 修改PAM安全配置函数
secure_pam() {
    log "${BLUE}[NEW] 加强PAM安全配置...${NC}"
    
    # 账户锁定策略 
    local PAM_FILE="/etc/pam.d/system-auth"
    if [ -f "$PAM_FILE" ]; then 
        backup_file "$PAM_FILE"
        # 移除旧版pam_tally2配置 
        sed -i '/pam_tally2.so/d'  "$PAM_FILE"
        
        # 添加faillock配置 
        sed -i '/auth.*pam_env.so/a  auth        required      pam_faillock.so  preauth silent audit deny=5 unlock_time=600 even_deny_root' "$PAM_FILE"
        sed -i '/auth.*pam_faillock.so  preauth/a auth        required      pam_faillock.so  authfail audit deny=5 unlock_time=600 even_deny_root' "$PAM_FILE"
        sed -i '/account.*pam_unix.so/i  account     required      pam_faillock.so'  "$PAM_FILE"
        
        # 兼容SELinux环境 
        restorecon -Rv /etc/pam.d/
    fi 
    
    # SU组限制优化 
    local PAM_SU="/etc/pam.d/su"
    if [ -f "$PAM_SU" ]; then 
        backup_file "$PAM_SU"
        # 清理旧配置 
        sed -i '/pam_wheel.so/d'  "$PAM_SU"
        # 添加增强配置 
        echo "auth sufficient pam_wheel.so  trust use_uid group=wheel" >> "$PAM_SU"
        # 防止权限扩散 
        chmod 644 "$PAM_SU"
    fi 
    
    log "${GREEN}PAM安全配置完成，已启用增强型账户锁定策略${NC}"
}

# 新增：确保root登录功能正常
ensure_root_login() {
    log "${BLUE}[NEW] 确保root本地登录功能正常...${NC}"
    
    # 确保关键命令保留SUID权限
    SUID_TO_PRESERVE=(
        "/bin/su"
        "/usr/bin/passwd"
        "/bin/mount"
        "/bin/umount"
        "/usr/bin/sudo"
    )
    
    for cmd in "${SUID_TO_PRESERVE[@]}"; do
        if [ -f "$cmd" ]; then
            chmod u+s "$cmd"
            log "确保${cmd}保留SUID权限"
        fi
    done
    
    # 解锁root账户(如果被锁定)
    if command -v faillock &> /dev/null; then
        faillock --user root --reset
        log "已重置root账户的登录失败计数"
    fi
    
    # 确保root的shell正确
    if grep -q "^root:.*:/sbin/nologin" /etc/passwd || grep -q "^root:.*:/bin/false" /etc/passwd; then
        usermod -s /bin/bash root || chsh -s /bin/bash root
        log "已将root的shell重置为/bin/bash"
    fi
    
    log "${GREEN}root本地登录功能已确保正常${NC}"
}

# 3. 强化 SSH 配置
secure_ssh() {
    log "${BLUE}[3/15] 加固 SSH 配置...${NC}"
    
    if [ ! -f "/etc/ssh/sshd_config" ]; then
        log "${YELLOW}未找到 SSH 配置文件，跳过 SSH 加固${NC}"
        return 1
    fi
    
    backup_file "/etc/ssh/sshd_config"
    backup_file "/etc/hosts.allow"
    backup_file "/etc/hosts.deny"
    
    # 禁用密码认证，启用密钥认证
    # sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    # sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # 设置 SSH 协议版本
    sed -i '/^#*Protocol/d' /etc/ssh/sshd_config
    echo "Protocol 2" >> /etc/ssh/sshd_config
    
    # 设置 SSH 空闲超时
    sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
    sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
    
    # 禁用 X11 转发
    sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
    
    # 设置最大认证尝试次数
    sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 4/' /etc/ssh/sshd_config
    
    # 禁用空密码
    sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    
    # 禁用 .rhosts 文件
    sed -i 's/^#*IgnoreRhosts.*/IgnoreRhosts yes/' /etc/ssh/sshd_config
    
    # 设置默认的 SSH 端口为非标准端口
    sed -i "s/^#*Port.*/Port $SSH_PORT/" /etc/ssh/sshd_config
    
    # 根据ALLOW_ROOT_LOGIN设置是否允许root登录
    if [ "$ALLOW_ROOT_LOGIN" -eq 1 ]; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        log "已允许root用户通过SSH登录"
    else
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        log "已禁止root用户通过SSH登录，请使用普通用户登录后使用su或sudo"
    fi
    
    # 重启 SSH 服务
    if systemctl is-active sshd &>/dev/null || systemctl is-active ssh &>/dev/null; then
        systemctl restart sshd &>/dev/null || systemctl restart ssh &>/dev/null
        log "已重启 SSH 服务"
    else
        service sshd restart &>/dev/null || service ssh restart &>/dev/null
        if [ $? -eq 0 ]; then
            log "已重启 SSH 服务"
        else
            log "${YELLOW}无法重启 SSH 服务${NC}"
        fi
    fi
    
    log "${GREEN}SSH 配置加固完成${NC}"
}

# 4. 配置防火墙
configure_firewall() {
    log "${BLUE}[4/15] 配置防火墙...${NC}"
    
    # 首先尝试使用firewalld (CentOS/RHEL 7+默认)
    if command -v firewall-cmd &> /dev/null; then
        log "使用firewalld配置防火墙"
        
        # 检查firewalld状态
        if ! systemctl is-active firewalld &>/dev/null; then
            systemctl enable firewalld
            systemctl start firewalld
        fi
        
        # 配置防火墙规则
        firewall-cmd --permanent --add-service=ssh
        if [ "$CHANGE_SSH_PORT" -eq 1 ] && [ "$SSH_PORT" != "22" ]; then
            firewall-cmd --permanent --add-port=$SSH_PORT/tcp
        fi
        
        # 重新加载配置
        firewall-cmd --reload
        log "已配置firewalld防火墙"
        return 0
    fi
     
    # 如果都不可用，使用iptables
    if command -v iptables &> /dev/null; then
        log "使用iptables配置防火墙"
        
        # 保存当前规则
        if ! [ -d "/etc/iptables" ]; then
            mkdir -p /etc/iptables
        fi
        
        if command -v iptables-save &> /dev/null; then
            iptables-save > "$BACKUP_DIR/iptables.rules.bak"
        fi
        
        # 清除当前规则
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        
        # 设置默认策略
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        
        # 允许本地回环接口
        iptables -A INPUT -i lo -j ACCEPT
        
        # 允许已建立的连接
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        
        # 允许SSH
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT
        
        # 保存规则
        if command -v iptables-save &> /dev/null; then
            mkdir -p /etc/iptables/
            iptables-save > /etc/iptables/rules.v4
            
            # 创建启动时加载规则的服务
            if [ -d "/etc/systemd/system" ]; then
                cat > /etc/systemd/system/iptables-restore.service << 'EOF'
[Unit]
Description=Restore iptables firewall rules
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
ExecStartPre=/bin/mkdir -p /etc/iptables

[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable iptables-restore.service
            fi
        else
            log "${YELLOW}无法保存iptables规则，系统重启后将丢失防火墙配置${NC}"
        fi
        
        log "已配置基本的iptables规则"
        return 0
    fi
    
    log "${YELLOW}未找到支持的防火墙工具，跳过防火墙配置${NC}"
    return 1
}

# 5. 禁用不必要的服务：查一下再禁用
disable_services() {
    log "${BLUE}[5/15] 禁用不必要的服务...${NC}"
    
    # 可能的不必要服务列表
    SERVICES_TO_DISABLE=(
        "telnet"
        "rsh-server"
        "rlogin-server"
        "rcp-server"
        "tftp-server"
        "xinetd"
        "chargen-dgram"
        "chargen-stream"
        "daytime-dgram"
        "daytime-stream"
        "echo-dgram"
        "echo-stream"
        "tcpmux-server"
        "avahi-daemon"
        "cups"
        "dhcpd"
        "named"
        "nfs"
        "rpcbind"
        "ypserv"
        "vsftpd"
    )
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl list-unit-files | grep -q "$service"; then
            systemctl stop "$service" 2>/dev/null
            systemctl disable "$service" 2>/dev/null
            log "已禁用服务: $service"
        elif [ -f "/etc/init.d/$service" ]; then
            service "$service" stop 2>/dev/null
            update-rc.d "$service" disable 2>/dev/null || chkconfig "$service" off 2>/dev/null
            log "已禁用服务: $service"
        fi
    done
    
    log "${GREEN}不必要的服务禁用完成${NC}"
}

# 6. 限制 SUID 和 SGID 文件
control_suid_sgid() {
    log "${BLUE}[6/15] 限制 SUID 和 SGID 文件...${NC}"
    
    # 查找并记录所有 SUID 和 SGID 文件
    log "查找 SUID 和 SGID 文件并记录到 $BACKUP_DIR/suid_sgid_files.txt"
    find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -la {} \; 2>/dev/null > "$BACKUP_DIR/suid_sgid_files.txt"
    
    # 移除不必要的 SUID 权限 - 从列表中移除passwd，以免影响密码修改
    SUID_TO_REMOVE=(
        "/usr/bin/chage"
        "/usr/bin/gpasswd"
        "/usr/bin/wall"
        "/usr/bin/chfn"
        "/usr/bin/chsh"
        "/usr/bin/newgrp"
        "/usr/bin/write"
        # 已移除 "/usr/bin/passwd" 以保留正常的密码修改功能
    )
    
    for file in "${SUID_TO_REMOVE[@]}"; do
        if [ -f "$file" ]; then
            original_perm=$(stat -c "%a" "$file")
            log "原始权限 $file: $original_perm"
            chmod u-s "$file"
            new_perm=$(stat -c "%a" "$file")
            log "已移除 SUID 权限 $file，新权限: $new_perm"
        fi
    done
    
    log "${GREEN}SUID 和 SGID 限制完成${NC}"
}

secure_permissions() {
    log "${BLUE}[NEW] 配置权限管理...${NC}"
    
    # 设置 umask
    backup_file "/etc/profile"
    if ! grep -q "umask 022" /etc/profile; then
        echo "umask 022" >> /etc/profile
        log "已设置 umask 为 022"
    fi
    
    # 限制 su 用户
    backup_file "/etc/pam.d/su"
    if ! grep -q "pam_wheel.so" /etc/pam.d/su; then
        echo "auth required pam_wheel.so group=wheel" >> /etc/pam.d/su
        log "已限制只有 wheel 组用户可 su 到 root"
    fi
    
    # 控制 sudo 权限
    backup_file "/etc/sudoers"
    if ! grep -q "^root\s*ALL=(ALL:ALL)\s*ALL" /etc/sudoers; then
        echo "root    ALL=(ALL:ALL)   ALL" >> /etc/sudoers
        log "已确保 root 拥有所有 sudo 权限"
    fi
    
    log "${GREEN}权限管理配置完成${NC}"
}

# 7. 设置安全的日志记录
secure_logging() {
    log "${BLUE}[7/15] 配置安全日志记录...${NC}"
    
    backup_file "/etc/rsyslog.conf"
    
    # 确保关键日志已启用
    if [ -f "/etc/rsyslog.conf" ]; then
        # 检查是否已配置关键安全日志
        if ! grep -q "auth,authpriv.* /var/log/auth.log" /etc/rsyslog.conf; then
            echo "auth,authpriv.* /var/log/auth.log" >> /etc/rsyslog.conf
            log "已添加认证日志配置"
        fi
        
        # 重启 rsyslog 服务
        systemctl restart rsyslog &>/dev/null || service rsyslog restart &>/dev/null
    fi
    
    # 配置 logrotate
    if [ -d "/etc/logrotate.d" ]; then
        cat > /etc/logrotate.d/secure_logs << 'EOF'
/var/log/auth.log
/var/log/secure
/var/log/kern.log
/var/log/syslog
{
    rotate 14
    daily
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /bin/kill -HUP $(cat /var/run/syslogd.pid 2>/dev/null) 2>/dev/null || true
        systemctl restart rsyslog 2>/dev/null || service rsyslog restart 2>/dev/null || true
    endscript
}
EOF
        log "已配置 logrotate 策略"
    fi
    
    # 设置日志文件权限
    find /var/log -type f -exec chmod 640 {} \;
    log "已设置日志文件权限"
    
    log "${GREEN}日志安全配置完成${NC}"
}

# 配置命令历史记录
configure_history() {
    log "${BLUE}[NEW] 配置命令历史记录...${NC}"
    
    backup_file "/etc/profile"
    
    cat >> /etc/profile << 'EOF'
HISTSIZE=10000
User_IP=`who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g'`
if [ "$User_IP" = "" ]; then
    User_IP=`hostname`
fi
export HISTTIMEFORMAT="%F %T $User_IP `whoami` "
shopt -s histappend
export PROMPT_COMMAND="history -a"
EOF
    
    source /etc/profile
    log "${GREEN}命令历史记录配置完成${NC}"
}

# 8. 配置内核安全参数
secure_kernel() {
    log "${BLUE}[8/15] 配置内核安全参数...${NC}"
    
    backup_file "/etc/sysctl.conf"
    
    # 创建临时内核安全参数文件
    TMP_SYSCTL_FILE=$(mktemp)
    
    # 添加所有参数到临时文件
    cat > $TMP_SYSCTL_FILE << 'EOF'
# 禁用 IP 转发
net.ipv4.ip_forward = 0

# 禁用 IP 源路由
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# 启用 IP 欺骗保护
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 禁用 ICMP 重定向接受
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# 禁用发送重定向
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 记录异常包
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# 忽略广播请求
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 启用 TCP SYN Cookie 保护
net.ipv4.tcp_syncookies = 1

# 启用源路由验证
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# 禁用 Smurf 攻击保护
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 限制 IPv6
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# 启用地址空间布局随机化
kernel.randomize_va_space = 2

# 限制核心转储
fs.suid_dumpable = 0

# 禁用 Magic SysRq 键
kernel.sysrq = 0

# 限制用户可以查看的其他用户进程
kernel.yama.ptrace_scope = 1

# 设置 swapping 算法阈值，减少交换使用
vm.swappiness = 10

# 提高 TCP 连接安全性
net.ipv4.tcp_timestamps = 0

# 启用 TCP MSS 限制
net.ipv4.tcp_mtu_probing = 1
EOF

    # 最终内核参数文件
    FINAL_SYSCTL_FILE="/etc/sysctl.d/99-security.conf"
    
    # 检查每个参数是否存在，只保留存在的参数
    log "检查并应用系统支持的内核参数..."
    while IFS= read -r line; do
        # 跳过注释和空行
        if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $(echo $line | tr -d '[:space:]') ]]; then
            echo "$line" >> $FINAL_SYSCTL_FILE
            continue
        fi
        
        # 提取参数名
        param=$(echo $line | cut -d= -f1 | tr -d '[:space:]')
        
        # 检查参数是否存在
        if [ -e "/proc/sys/$(echo $param | tr '.' '/')" ]; then
            echo "$line" >> $FINAL_SYSCTL_FILE
        else
            log "${YELLOW}跳过不支持的内核参数: $param${NC}"
        fi
    done < $TMP_SYSCTL_FILE
    
    # 删除临时文件
    rm -f $TMP_SYSCTL_FILE
    
    # 应用内核参数
    sysctl -p $FINAL_SYSCTL_FILE
    
    log "${GREEN}内核安全参数配置完成${NC}"
}

# 9. 禁用 USB 存储 (可选)
disable_usb_storage() {
    log "${BLUE}[9/15] 禁用 USB 存储...${NC}"
    
    backup_file "/etc/modprobe.d/blacklist.conf"
    
    # 添加到 modprobe 黑名单
    echo "blacklist usb-storage" >> /etc/modprobe.d/blacklist.conf
    echo "install usb-storage /bin/true" >> /etc/modprobe.d/blacklist.conf
    
    # 卸载当前已加载的模块
    rmmod usb-storage 2>/dev/null
    
    log "${GREEN}USB 存储禁用完成${NC}"
}

# 10. 加固用户账户
secure_accounts() {
    log "${BLUE}[10/15] 加固用户账户...${NC}"
    
    # 锁定系统账户
    for user in $(awk -F: '($3 < 1000) {print $1 }' /etc/passwd); do
        if ! [[ "$user" =~ ^(root|sync|shutdown|halt)$ ]]; then
            if [ -z "$(grep "$user" /etc/passwd | grep -E "(/sbin/nologin|/usr/sbin/nologin|/bin/false)")" ]; then
                usermod -s /sbin/nologin "$user" 2>/dev/null
                log "锁定系统账户: $user"
            fi
        fi
    done
    
    # 确保 root 用户是唯一的 UID 为 0 的用户
    for user in $(awk -F: '($3 == 0) {print $1}' /etc/passwd); do 
        if [ "$user" != "root" ]; then 
            log "${RED}警告: 发现 UID 为 0 的非 root 用户: $user${NC}"
            # 强制删除用户及其关联文件 
            userdel -rf "$user" 2>/dev/null 
            log "已强制删除高危用户: $user"
        fi 
    done 
    
    # 检查空密码账户
    for user in $(cat /etc/shadow | awk -F: '($2 == "" ) {print $1}'); do
        if [ -n "$user" ]; then
            log "${RED}警告: 用户 $user 没有设置密码${NC}"
            # 锁定账户
            passwd -l "$user" 2>/dev/null
            log "已锁定无密码账户: $user"
        fi
    done
    
    log "${GREEN}用户账户加固完成${NC}"
}

# 11. 设置文件系统安全
secure_filesystem() {
    log "${BLUE}[11/15] 设置文件系统安全...${NC}"
    
    backup_file "/etc/fstab"
    
    # 检查 /tmp 分区
    if grep -q " /tmp " /etc/fstab; then
        # 添加安全选项
        sed -i '/\s\/tmp\s/ s/defaults/defaults,nodev,nosuid,noexec/' /etc/fstab
        log "已为 /tmp 添加安全挂载选项"
    else
        # 若 /tmp 不是单独分区，考虑使用 tmpfs
        if ! grep -q "tmpfs /tmp" /etc/fstab; then
            echo "tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab
            log "已配置 /tmp 为 tmpfs"
        fi
    fi
    
    # 检查 /var 分区
    if grep -q " /var " /etc/fstab; then
        sed -i '/\s\/var\s/ s/defaults/defaults,nosuid/' /etc/fstab
        log "已为 /var 添加安全挂载选项"
    fi
    
    # 检查 /var/tmp 分区
    if grep -q " /var/tmp " /etc/fstab; then
        sed -i '/\s\/var\/tmp\s/ s/defaults/defaults,nodev,nosuid,noexec/' /etc/fstab
        log "已为 /var/tmp 添加安全挂载选项"
    fi
    
    # 检查 /dev/shm 分区
    if ! grep -q " /dev/shm " /etc/fstab; then
        echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab
        log "已配置 /dev/shm 的安全挂载选项"
    else
        sed -i '/\s\/dev\/shm\s/ s/defaults/defaults,nodev,nosuid,noexec/' /etc/fstab
        log "已为 /dev/shm 添加安全挂载选项"
    fi
    
    # 重新挂载所有文件系统
    mount -a 2>/dev/null
    if [ $? -ne 0 ]; then
        log "${RED}警告: 重新挂载文件系统时出错，请查看 /etc/fstab 是否有问题${NC}"
    else
        log "已重新挂载文件系统"
    fi
    
    # 设置重要目录和文件的权限
    chmod 644 /etc/passwd
    chmod 644 /etc/group
    chmod 600 /etc/shadow
    chmod 600 /etc/gshadow
    chmod 644 /etc/fstab
    chmod 600 /boot/grub/grub.cfg 2>/dev/null || chmod 600 /boot/grub2/grub.cfg 2>/dev/null
    
    log "${GREEN}文件系统安全配置完成${NC}"
}

# 12. 设置审计和监控
configure_audit() {
    log "${BLUE}[12/15] 配置审计和监控...${NC}"
    
    # 安装 auditd
    if ! command -v auditd &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            apt-get install -y auditd audispd-plugins
        elif command -v yum &> /dev/null; then
            yum install -y audit audit-libs
        elif command -v dnf &> /dev/null; then
            dnf install -y audit audit-libs
        else
            log "${YELLOW}未检测到支持的包管理器，跳过安装 auditd${NC}"
            return 1
        fi
    fi
    
    # 配置审计规则
    if [ -f "/etc/audit/rules.d/audit.rules" ]; then
        backup_file "/etc/audit/rules.d/audit.rules"
        
        cat > /etc/audit/rules.d/audit.rules << 'EOF'
# 删除当前所有规则
-D

# 设置缓冲区大小（单位：KB）
-b 8192

# 如果文件系统已满，则不进行审计
-f 1

# 监控失败的登录尝试
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins

# 监控成功的登录
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins

# 监控权限变更
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod

# 监控重要文件
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# 监控系统调用
-a always,exit -F arch=b64 -S unlink -S rmdir -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S rmdir -F auid>=1000 -F auid!=4294967295 -k delete

# 监控用户和组管理
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/userdel -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupdel -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification

# 监控网络配置更改
-w /etc/hosts -p wa -k network_modifications
-w /etc/network/ -p wa -k network
-w /etc/sysconfig/network -p wa -k network

# 确保执行审计
-e 2
EOF
        log "已配置审计规则"
        
        # 重启审计服务
        service auditd restart 2>/dev/null || systemctl restart auditd 2>/dev/null
        log "已重启审计服务"
    else
        log "${YELLOW}未找到审计规则文件，跳过配置审计规则${NC}"
    fi
}

# 网络检查函数
check_network() {
    log "${BLUE}检查网络连接...${NC}"
    # 尝试连接几个常用网站来确认网络连接
    for site in "www.baidu.com" "www.aliyun.com" "mirrors.cloud.aliyuncs.com"; do
        if ping -c 1 -W 2 $site >/dev/null 2>&1; then
            log "${GREEN}网络连接正常${NC}"
            return 0
        fi
    done
    
    log "${YELLOW}警告: 网络连接可能存在问题，部分功能可能受限${NC}"
    return 1
}

# 安装和配置fail2ban
secure_network() {
    log "${BLUE}[NEW] 加强网络安全...${NC}"

    # 检查网络连接
    check_network
    if [ $? -ne 0 ]; then
        log "${YELLOW}网络连接异常，跳过网络安全组件安装${NC}"
        return 1
    fi

    # 安装fail2ban防止暴力破解
    log "尝试安装fail2ban..."
    if ! command -v fail2ban-server &> /dev/null; then
        local install_cmd=""
        if command -v apt-get &> /dev/null; then
            install_cmd="apt-get update && apt-get install -y fail2ban"
        elif command -v yum &> /dev/null; then
            install_cmd="yum -y install epel-release && yum -y install fail2ban"
        elif command -v dnf &> /dev/null; then
            install_cmd="dnf -y install epel-release && dnf -y install fail2ban"
        else
            log "${YELLOW}未检测到支持的包管理器，跳过安装fail2ban${NC}"
            return 1
        fi
        
        # 尝试安装，但不要因安装失败而终止脚本
        if ! eval "$install_cmd"; then
            log "${YELLOW}fail2ban安装失败，但继续执行脚本${NC}"
            return 1
        fi
    fi

    if command -v fail2ban-server &> /dev/null; then
        # 如果存在配置文件，则备份并创建自定义配置
        if [ -f "/etc/fail2ban/jail.conf" ]; then
            backup_file "/etc/fail2ban/jail.conf"
            
            # 创建自定义配置
            mkdir -p /etc/fail2ban/jail.d/
            cat > /etc/fail2ban/jail.d/custom.conf << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 600
bantime = 3600
EOF
            
            # 如果使用CentOS/RHEL，可能需要调整日志文件路径
            if [ -f "/var/log/secure" ] && ! [ -f "/var/log/auth.log" ]; then
                sed -i 's|/var/log/auth.log|/var/log/secure|g' /etc/fail2ban/jail.d/custom.conf
            fi
            
            # 启动fail2ban服务
            systemctl enable fail2ban &>/dev/null || chkconfig fail2ban on &>/dev/null
            systemctl restart fail2ban &>/dev/null || service fail2ban restart &>/dev/null
            
            if systemctl is-active fail2ban &>/dev/null || service fail2ban status &>/dev/null; then
                log "已配置并启动fail2ban"
            else
                log "${YELLOW}fail2ban服务启动失败，请手动检查${NC}"
            fi
        fi
    fi
    
    log "${GREEN}网络安全加强完成${NC}"
}

# 修复DNS加固功能
secure_dns() {
    log "${BLUE}[NEW] 加固DNS配置...${NC}"
    
    # 检查网络连接
    check_network
    if [ $? -ne 0 ]; then
        log "${YELLOW}网络连接异常，跳过DNS安全组件安装${NC}"
        return 1
    fi
    
    # 备份resolv.conf
    backup_file "/etc/resolv.conf"
    
    # 查找可用的DNS解析器
    local dns_servers="8.8.8.8 8.8.4.4 1.1.1.1 114.114.114.114"
    local available_dns=""
    
    for dns in $dns_servers; do
        if ping -c 1 -W 2 $dns >/dev/null 2>&1; then
            available_dns="$dns"
            break
        fi
    done
    
    if [ -z "$available_dns" ]; then
        log "${YELLOW}无法找到可用的DNS服务器，保持DNS配置不变${NC}"
        return 1
    fi
    
    # 配置基本的DNS设置
    log "使用可靠的DNS服务器: $available_dns"
    echo "nameserver $available_dns" > /etc/resolv.conf
    echo "options edns0 single-request-reopen" >> /etc/resolv.conf
    
    # 检查系统是否使用systemd-resolved
    if command -v systemd-resolve &> /dev/null && systemctl is-active systemd-resolved &>/dev/null; then
        log "检测到systemd-resolved，配置安全DNS..."
        
        mkdir -p /etc/systemd/resolved.conf.d/
        cat > /etc/systemd/resolved.conf.d/dns_settings.conf << EOF
[Resolve]
DNS=$available_dns
FallbackDNS=1.1.1.1 8.8.8.8 114.114.114.114
DNSSEC=allow-downgrade
DNSOverTLS=opportunistic
EOF
        
        systemctl restart systemd-resolved
    fi
    
    log "${GREEN}DNS安全加固完成${NC}"
}

# 修改为兼容更多系统版本的内核安全加固功能
secure_kernel_extended() {
    log "${BLUE}[NEW] 加强内核安全配置...${NC}"
    
    # 创建临时内核安全参数文件
    TMP_SYSCTL_FILE=$(mktemp)
    
    # 添加所有参数到临时文件
    cat > $TMP_SYSCTL_FILE << 'EOF'
# 防止针对共享内存的攻击
kernel.shm_rmid_forced = 1

# 限制对内核内存的访问
kernel.kptr_restrict = 2

# 启用进程地址空间布局随机化
kernel.randomize_va_space = 2

# 限制打开core dump
fs.suid_dumpable = 0

# 防止未授权访问内核消息缓冲区
kernel.dmesg_restrict = 1

# 防止通过内核崩溃利用漏洞
kernel.panic_on_oops = 1
kernel.panic = 30

# 禁用未使用的文件系统 (慎用，可能导致问题)
# kernel.modules_disabled = 0

# 限制用户空间访问/dev/mem
# dev.tty.ldisc_autoload = 0

# 启用BPF JIT强化
net.core.bpf_jit_harden = 2

# 启用TCP SYN Cookie保护(SYN flood防护)
net.ipv4.tcp_syncookies = 1

# 启用源地址验证(防止IP欺骗)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 禁用ICMP重定向
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# 限制IPv6
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.autoconf = 0
net.ipv6.conf.default.autoconf = 0

# 防止时间等待刺客攻击
net.ipv4.tcp_rfc1337 = 1

# 增强网络流量控制
net.ipv4.tcp_congestion_control = cubic
net.core.default_qdisc = fq
EOF

    # 最终内核参数文件
    FINAL_SYSCTL_FILE="/etc/sysctl.d/99-security-hardening.conf"
    
    # 检查每个参数是否存在，只保留存在的参数
    log "检查并应用系统支持的扩展内核参数..."
    while IFS= read -r line; do
        # 跳过注释和空行
        if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $(echo $line | tr -d '[:space:]') ]]; then
            echo "$line" >> $FINAL_SYSCTL_FILE
            continue
        fi
        
        # 提取参数名
        param=$(echo $line | cut -d= -f1 | tr -d '[:space:]')
        
        # 检查参数是否存在
        if [ -e "/proc/sys/$(echo $param | tr '.' '/')" ]; then
            echo "$line" >> $FINAL_SYSCTL_FILE
        else
            log "${YELLOW}跳过不支持的内核参数: $param${NC}"
        fi
    done < $TMP_SYSCTL_FILE
    
    # 删除临时文件
    rm -f $TMP_SYSCTL_FILE
    
    # 尝试应用内核参数，但不因失败而终止脚本
    sysctl -p $FINAL_SYSCTL_FILE || log "${YELLOW}应用部分内核参数失败，但继续执行脚本${NC}"
    
    # 添加系统启动时加载额外的安全模块
    backup_file "/etc/modules-load.d/security.conf"
    
    # 检查哪些模块可用
    if modprobe -n br_netfilter &>/dev/null; then
        echo "# 安全相关内核模块" > /etc/modules-load.d/security.conf
        echo "br_netfilter" >> /etc/modules-load.d/security.conf
        log "已配置安全相关内核模块自动加载"
    fi
    
    log "${GREEN}内核安全配置加强完成${NC}"
}

# 安全基线检查
security_baseline_check() {
    log "${BLUE}[NEW] 执行安全基线检查...${NC}"
    
    REPORT_FILE="$BACKUP_DIR/security_baseline_report.txt"
    
    echo "=== Linux安全基线检查报告 - $(date) ===" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查密码策略
    echo "## 密码策略检查" >> "$REPORT_FILE"
    grep "^PASS_" /etc/login.defs >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查SSH配置
    echo "## SSH配置检查" >> "$REPORT_FILE"
    grep "PermitRootLogin\|PasswordAuthentication\|Protocol" /etc/ssh/sshd_config >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查防火墙状态
    echo "## 防火墙状态" >> "$REPORT_FILE"
    if command -v ufw &> /dev/null; then
        ufw status >> "$REPORT_FILE"
    elif command -v iptables &> /dev/null; then
        iptables -L >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # 检查未授权的SUID/SGID文件
    echo "## 未授权的SUID/SGID文件" >> "$REPORT_FILE"
    find / -type f \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null | grep -v -f "$BACKUP_DIR/suid_sgid_files.txt" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # 检查开放端口
    echo "## 开放端口" >> "$REPORT_FILE"
    netstat -tulpn 2>/dev/null | grep "LISTEN" >> "$REPORT_FILE" || ss -tulpn 2>/dev/null | grep "LISTEN" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    log "安全基线检查完成，报告保存在: $REPORT_FILE"
}

# 创建恢复脚本
create_restore_script() {
    log "${BLUE}创建恢复脚本...${NC}"
    
    RESTORE_SCRIPT="$BACKUP_DIR/restore.sh"
    
    echo '#!/bin/bash' > "$RESTORE_SCRIPT"
    echo "# 恢复脚本 - 由安全加固脚本生成于 $(date)" >> "$RESTORE_SCRIPT"
    echo "BACKUP_DIR=\"$BACKUP_DIR\"" >> "$RESTORE_SCRIPT"
    
    echo 'echo "开始从备份恢复系统配置..."' >> "$RESTORE_SCRIPT"
    
    # 遍历备份文件并添加恢复命令
    find "$BACKUP_DIR" -name "*.bak" | while read file; do
        original_file=$(basename "$file" .bak)
        echo "cp -f \"$file\" \"/$original_file\" && echo \"已恢复: /$original_file\"" >> "$RESTORE_SCRIPT"
    done
    
    # 添加服务重启命令
    echo 'systemctl restart sshd || service sshd restart' >> "$RESTORE_SCRIPT"
    echo 'systemctl restart rsyslog || service rsyslog restart' >> "$RESTORE_SCRIPT"
    
    # 添加恢复密码和登录相关命令的SUID权限
    echo 'if [ -f "/usr/bin/passwd" ]; then chmod u+s /usr/bin/passwd && echo "已恢复passwd的SUID权限"; fi' >> "$RESTORE_SCRIPT"
    echo 'if [ -f "/bin/su" ]; then chmod u+s /bin/su && echo "已恢复su的SUID权限"; fi' >> "$RESTORE_SCRIPT"
    echo 'if [ -f "/usr/bin/sudo" ]; then chmod u+s /usr/bin/sudo && echo "已恢复sudo的SUID权限"; fi' >> "$RESTORE_SCRIPT"
    echo 'if [ -f "/bin/mount" ]; then chmod u+s /bin/mount && echo "已恢复mount的SUID权限"; fi' >> "$RESTORE_SCRIPT"
    echo 'if [ -f "/bin/umount" ]; then chmod u+s /bin/umount && echo "已恢复umount的SUID权限"; fi' >> "$RESTORE_SCRIPT"
    
    # 添加解锁root账户命令
    echo 'if command -v faillock &> /dev/null; then faillock --user root --reset && echo "已重置root账户的登录失败计数"; fi' >> "$RESTORE_SCRIPT"
    
    # 添加恢复root shell命令
    echo 'if grep -q "^root:.*:/sbin/nologin" /etc/passwd || grep -q "^root:.*:/bin/false" /etc/passwd; then usermod -s /bin/bash root || chsh -s /bin/bash root && echo "已将root的shell重置为/bin/bash"; fi' >> "$RESTORE_SCRIPT"
    
    chmod +x "$RESTORE_SCRIPT"
    log "已创建恢复脚本: $RESTORE_SCRIPT"
}

# 主函数
main() {
    # 初始化配置选项
    SKIP_SSH=0
    SKIP_FIREWALL=0
    SKIP_KERNEL=0
    SKIP_NETWORK=0
    SKIP_DNS=0
    SKIP_CONTAINERS=0
    
    # 显示脚本标题
    echo -e "\n${GREEN}===== Linux安全加固脚本 v1.3 =====${NC}\n"
    
    # 检查root权限
    check_root
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 记录开始时间
    START_TIME=$(date +%s)
    log "开始执行安全加固脚本"
    
    # 检查操作系统
    check_os_version
    
    # 网络连接检查
    check_network
    
    # 创建备份目录（如果启用）
    if [ "$BACKUP_ENABLED" -eq 1 ]; then
        create_backup_dir
    else
        log "${YELLOW}备份功能已禁用，不会创建配置备份${NC}"
    fi
    
    # 执行安全加固步骤 - 使用并行处理
    log "${BLUE}[信息] 开始执行安全加固步骤${NC}"
    
    # 先顺序执行关键步骤
    update_system
    
    # 使用并行处理执行独立的加固措施
    run_parallel password_policies "配置密码策略"
    
    # 根据跳过选项执行SSH加固
    if [ "$SKIP_SSH" -eq 0 ]; then
        run_parallel secure_ssh "加固SSH配置"
    else
        log "${YELLOW}已跳过: SSH加固${NC}"
    fi
    
    # 根据跳过选项执行防火墙配置
    if [ "$SKIP_FIREWALL" -eq 0 ]; then
        run_parallel configure_firewall "配置防火墙"
    else
        log "${YELLOW}已跳过: 防火墙配置${NC}"
    fi
    
    run_parallel disable_services "禁用不必要的服务"
    run_parallel control_suid_sgid "限制SUID和SGID文件"
    run_parallel secure_logging "配置安全日志记录"
    
    # 根据跳过选项执行内核安全加固
    if [ "$SKIP_KERNEL" -eq 0 ]; then
        run_parallel secure_kernel "配置内核安全参数"
    else
        log "${YELLOW}已跳过: 内核安全加固${NC}"
    fi
    
    run_parallel secure_pam "加强PAM安全配置"
    run_parallel secure_permissions "配置权限管理"
    run_parallel configure_history "配置命令历史记录"
    run_parallel ensure_root_login "确保root本地登录功能正常"
    
    # 根据配置选项执行USB禁用
    if [ "$DISABLE_USB" -eq 1 ]; then
        run_parallel disable_usb_storage "禁用USB存储"
    fi
    
    run_parallel secure_accounts "加固用户账户"
    run_parallel secure_filesystem "设置文件系统安全"
    
    # 根据配置选项执行审计配置
    if [ "$USE_AUDIT" -eq 1 ]; then
        run_parallel configure_audit "配置审计和监控"
    fi
    
    # 根据跳过选项执行网络安全加固
    if [ "$SKIP_NETWORK" -eq 0 ]; then
        run_parallel secure_network "加强网络安全"
    else
        log "${YELLOW}已跳过: 网络安全加固${NC}"
    fi
    
    # 根据跳过选项执行容器安全加固
    if [ "$SKIP_CONTAINERS" -eq 0 ]; then
        run_parallel secure_containers "配置容器安全"
    else
        log "${YELLOW}已跳过: 容器安全加固${NC}"
    fi
    
    # 根据跳过选项执行DNS安全加固
    if [ "$SKIP_DNS" -eq 0 ]; then
        run_parallel secure_dns "加固DNS配置"
    else
        log "${YELLOW}已跳过: DNS安全加固${NC}"
    fi
    
    # 根据跳过选项执行扩展内核安全加固
    if [ "$SKIP_KERNEL" -eq 0 ]; then
        run_parallel secure_kernel_extended "加强内核安全配置"
    else
        log "${YELLOW}已跳过: 扩展内核安全加固${NC}"
    fi
    
    # 等待所有并行任务完成
    wait
    log "所有任务已完成"
    
    # 执行安全基线检查（必须在所有加固步骤完成后进行）
    security_baseline_check
    
    # 创建恢复脚本（如果启用备份）
    if [ "$BACKUP_ENABLED" -eq 1 ]; then
        create_restore_script
    fi
    
    # 计算执行时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log "安全加固完成！执行时间: $DURATION 秒"
    echo -e "\n${GREEN}===== 安全加固完成 =====${NC}"
    echo -e "日志文件: $LOG_FILE"
    
    if [ "$BACKUP_ENABLED" -eq 1 ]; then
        echo -e "备份目录: $BACKUP_DIR"
        echo -e "恢复脚本: $BACKUP_DIR/restore.sh（如需恢复配置）"
    fi
    
    echo -e "安全基线报告: $BACKUP_DIR/security_baseline_report.txt"
    echo -e "\n${YELLOW}建议：加固完成后请重启系统以应用所有更改${NC}\n"
    
    # 提示是否需要立即重启
    if [ "$INTERACTIVE_MODE" -eq 1 ]; then
        read -p "是否要立即重启系统以应用所有更改？(y/n): " reboot_choice
        if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
            log "用户选择立即重启系统"
            shutdown -r now
        fi
    fi
}

# 执行主函数
main "$@"
    