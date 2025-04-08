#!/bin/bash
# 统信UOS等保2.0加固脚本 v2.1
# author:anonymous
# @date 2025.4.8

set -e # 遇到错误立即退出

# 初始化日志
LOG_FILE="/var/log/security_harden.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始执行UOS（统信）等保加固脚本"

# 函数定义 - 配置文件修改通用函数
safe_modify() {
    local file=$1
    local pattern=$2
    local line=$3
    cp -p "${file}" "${file}.bak-$(date +%Y%m%d)"
    if grep -q "^${pattern}" "${file}"; then
        sed -i "/^${pattern}/c\\${line}" "${file}"
    else
        echo "${line}" >> "${file}"
    fi
}

# 1. 关闭非必要服务（等保要求：安全配置）
echo "步骤1/6 关闭非必要服务..."
services=(cups nmbd smbd rpcbind telnet.socket)
for srv in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^${srv}.service"; then
        systemctl stop "$srv" || true
        systemctl disable "$srv"
        echo "已禁用服务：$srv"
    fi
done

# 2. 配置防火墙（等保要求：访问控制）
echo "步骤2/6 配置防火墙规则..."
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# 3. 密码策略强化（等保要求：身份鉴别）
echo "步骤3/6 配置密码策略..."
apt-get install -y libpam-pwquality

# PAM配置
safe_modify /etc/pam.d/common-password "password.*pam_pwquality.so" \
"password requisite pam_pwquality.so retry=3 minlen=10 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 enforce_for_root"

# 密码有效期
safe_modify /etc/login.defs "PASS_MAX_DAYS" "PASS_MAX_DAYS   90"
safe_modify /etc/login.defs "PASS_MIN_DAYS" "PASS_MIN_DAYS   7"
safe_modify /etc/login.defs "PASS_WARN_AGE" "PASS_WARN_AGE   14"

# 4. 登录安全设置（等保要求：安全审计）
echo "步骤4/6 配置登录安全..."
# SSH加固
sshd_config="/etc/ssh/sshd_config"
safe_modify "$sshd_config" "PermitRootLogin" "PermitRootLogin no"
safe_modify "$sshd_config" "ClientAliveInterval" "ClientAliveInterval 300"
safe_modify "$sshd_config" "ClientAliveCountMax" "ClientAliveCountMax 0"

# 登录失败锁定
pam_files=(login sshd su)
for file in "${pam_files[@]}"; do
    if ! grep -q "pam_tally2" "/etc/pam.d/${file}"; then
        sed -i "1i auth required pam_tally2.so deny=5 unlock_time=600 even_deny_root root_unlock_time=600" "/etc/pam.d/${file}"
    fi
done

# 5. 三权分立配置（等保要求：权限分离）
echo "步骤5/6 配置三权分立..."
roles=(
    "secadmin:1001:系统管理员"
    "secaudit:1002:审计管理员"
    "secoper:1003:安全管理员"
)
for role in "${roles[@]}"; do
    IFS=':' read -r user uid desc <<< "$role"
    if ! id "$user" &>/dev/null; then
        useradd -m -u "$uid" -s /bin/bash -c "$desc" "$user"
        echo "已创建角色：$user (UID:$uid)"
    fi
done

# 6. 审计配置（等保要求：安全审计）
echo "步骤6/6 配置审计策略..."
apt-get install -y auditd

# 审计规则
audit_rules=(
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/sudoers -p wa -k privilege"
    "-a always,exit -F arch=b64 -S execve -k process"
)
for rule in "${audit_rules[@]}"; do
    if ! auditctl -l | grep -q "$rule"; then
        echo "$rule" >> /etc/audit/rules.d/audit.rules
    fi
done

# 日志保留策略
safe_modify /etc/logrotate.conf "rotate" "rotate 26"
safe_modify /etc/logrotate.conf "weekly" "weekly"

systemctl restart auditd
service rsyslog restart

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 加固脚本执行完成"
echo "请执行以下命令验证配置："
echo "1. 检查剩余服务：systemctl list-unit-files | grep enabled"
echo "2. 验证密码策略：grep ^PASS /etc/login.defs"
echo "3. 查看审计规则：auditctl -l"