#!/bin/bash


Sky_Blue="\e[36m"
Blue="\033[34m"
Green="\033[32m"
Red="\033[31m"
Yellow='\033[33m'
Font="\033[0m"
INFO="[${Green}INFO${Font}]"
ERROR="[${Red}ERROR${Font}]"
WARN="[${Yellow}WARN${Font}]"
function INFO() {
    echo -e "${INFO} ${1}"
}
function ERROR() {
    echo -e "${ERROR} ${1}"
}
function WARN() {
    echo -e "${WARN} ${1}"
}

function root_need() {
    if [[ $EUID -ne 0 ]]; then
        ERROR '此脚本必须以 root 身份运行！'
        exit 1
    fi
}

function return_menu() {

    INFO "是否返回菜单继续配置 [Y/n]"
    answer=""
    t=60
    while [[ -z "$answer" && $t -gt 0 ]]; do
        printf "\r%2d 秒后将自动退出脚本：" $t
        read -r -t 1 -n 1 answer
        t=$((t - 1))
    done
    [[ -z "${answer}" ]] && answer="n"
    if [[ ${answer} == [Yy] ]]; then
        clear
        "${@}"
    else
        echo -e "\n"
        exit 0
    fi

}

function sbmmfzd() {
    # 设置期望的密码过期天数
    DESIRED_DAYS=90
    # 读取PASS_MAX_DAYS的值
    PASS_MAX_DAYS_VALUE=$(grep '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')

    # 打印变量的值以验证
    INFO "当前PASS_MAX_DAYS 的值为: $PASS_MAX_DAYS_VALUE"

    # 检查PASS_MAX_DAYS的值是否为期望的值
    if [[ "$PASS_MAX_DAYS_VALUE" != "$DESIRED_DAYS" ]]; then
        # 如果不是期望的值，则使用sed修改它
        sed -i "s/^\(PASS_MAX_DAYS\s*\).*/\1$DESIRED_DAYS/" /etc/login.defs

        # 再次读取并打印修改后的值以验证
        PASS_MAX_DAYS_VALUE=$(grep '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')
        INFO "修改后PASS_MAX_DAYS 的值为: $PASS_MAX_DAYS_VALUE"
    else
        INFO "PASS_MAX_DAYS 的值已经是 $DESIRED_DAYS，无需修改。"
    fi

    # 设置期望的密码最小长度
    DESIRED_MIN_LEN=8

    # 读取PASS_MIN_LEN的值
    PASS_MIN_LEN_VALUE=$(grep '^PASS_MIN_LEN' /etc/login.defs | awk '{print $2}')

    # 打印变量的值以验证
    INFO "当前PASS_MIN_LEN 的值为: $PASS_MIN_LEN_VALUE"

    # 检查PASS_MIN_LEN的值是否为期望的值
    if [[ "$PASS_MIN_LEN_VALUE" != "$DESIRED_MIN_LEN" ]]; then
        # 如果不是期望的值，则使用sed修改它
        sed -i "s/^\(PASS_MIN_LEN\s*\).*/\1$DESIRED_MIN_LEN/" /etc/login.defs

        # 再次读取并打印修改后的值以验证
        PASS_MIN_LEN_VALUE=$(grep '^PASS_MIN_LEN' /etc/login.defs | awk '{print $2}')
        INFO "修改后PASS_MIN_LEN 的值为: $PASS_MIN_LEN_VALUE"
    else
        INFO "PASS_MIN_LEN 的值已经是 $DESIRED_MIN_LEN，无需修改。"
    fi

    # 设置期望的密码质量参数
    DESIRED_ARGS="retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"
    # 读取当前pam_pwquality.so的参数值
    CURRENT_ARGS=$(grep '^password\s*requisite\s*pam_pwquality.so' /etc/pam.d/system-auth | awk '{for(i=4; i<=NF; i++) printf $i" "; print ""}')
    INFO "当前pam_pwquality.so的参数为: $CURRENT_ARGS"

    # 使用sed修改pam_pwquality.so的参数
    sed -i "/pam_pwquality.so/s/\(.*pam_pwquality.so\).*/\1 $DESIRED_ARGS/" /etc/pam.d/system-auth

    # 再次读取并打印修改后的参数值以验证
    NEW_ARGS=$(grep '^password\s*requisite\s*pam_pwquality.so' /etc/pam.d/system-auth | awk '{for(i=4; i<=NF; i++) printf $i" "; print ""}')
    INFO "修改后pam_pwquality.so的参数为: $NEW_ARGS"

}

function dlsbcl() {
    PAM_FILE="/etc/pam.d/login"
    PAM_LINE_TO_ADD="auth required pam_tally2.so deny=5 unlock_time=600 even_deny_root root_unlock_time=600"
    PAM_HEADER_LINE="#%PAM-1.0"

    # 检查 #%PAM-1.0 是否存在
    grep -q "^$PAM_HEADER_LINE$" "$PAM_FILE"
    if [ $? -eq 0 ]; then
        # 检查 pam_tally2.so 是否已经存在
        grep -q "pam_tally2.so" "$PAM_FILE"
        if [ $? -eq 0 ]; then
            # 如果存在，您可能想要替换整行或进行其他修改（这里假设不修改）
            INFO "pam_tally2.so 配置已存在，不进行修改。"
        else
            # 如果不存在，在 #%PAM-1.0 下一行添加新的配置
            sed -i "/^$PAM_HEADER_LINE$/a\\
    $PAM_LINE_TO_ADD" "$PAM_FILE"
            INFO "已添加 pam_tally2.so 配置到 $PAM_FILE。"
        fi
    else
        INFO "Header line not found in $PAM_FILE. Not adding $PAM_LINE_TO_ADD."
    fi

    # 修改/etc/profile
    PROFILE_FILE="/etc/profile"
    PROFILE_LINE_TO_ADD="TMOUT=300"

    # 检查 TMOUT 是否已经设置
    grep -q "^TMOUT=" "$PROFILE_FILE"
    if [ $? -eq 0 ]; then
        # 如果存在，检查值是否为 300
        if ! grep -q "^TMOUT=300$" "$PROFILE_FILE"; then
            # 如果不是 300，替换它（这取决于您的具体需求，可能需要更复杂的逻辑）
            sed -i "s/^TMOUT=.*/$PROFILE_LINE_TO_ADD/" "$PROFILE_FILE"
            INFO "已更新 $PROFILE_FILE 中的 TMOUT 值为 300。"
        else
            INFO "TMOUT 已设置为 300 在 $PROFILE_FILE。"
        fi
    else
        # 如果不存在，添加到文件末尾
        INFO "$PROFILE_LINE_TO_ADD" >> "$PROFILE_FILE"
        INFO "已添加 TMOUT=300 到 $PROFILE_FILE。"
    fi

    INFO "修改完成。"
}
function disable_telnet() {
    # 定义Telnet配置文件路径
    TELNET_CONFIG="/etc/xinetd.d/telnet"

    # 检查配置文件是否存在
    if [ -f "$TELNET_CONFIG" ]; then
        # 禁用Telnet服务，将disable设置为yes
        sed -i "s/^\(disable\s*=\s*\).*$/\1yes/" "$TELNET_CONFIG"

        # 检查是否成功修改了文件
        grep "^disable = yes" "$TELNET_CONFIG"
        if [ $? -eq 0 ]; then
            INFO "已成功禁用Telnet服务。"
            # 重启xinetd服务（如果需要）
            systemctl restart xinetd || /etc/init.d/xinetd restart
        else
            INFO "修改Telnet配置文件失败。"
        fi
    else
        INFO "Telnet配置文件 $TELNET_CONFIG 不存在。"
    fi
}

# 定义一个函数来检查并启动服务，同时设置开机自启
check_and_start_service() {
    local service_name=$1
    # 检查服务状态
    if ! systemctl is-active --quiet "$service_name"; then
        echo "服务 $service_name 没有运行，正在启动..."
        # 启动服务
        systemctl start "$service_name"
        # 检查服务是否成功启动
        if ! systemctl is-active --quiet "$service_name"; then
            echo "启动 $service_name 失败!"
        else
            # 设置开机自启
            systemctl enable "$service_name"
            echo "服务 $service_name 已启动并设置为开机自启。"
        fi
    else
        echo "服务 $service_name 正在运行。"
    fi
}

function set_histsize() {

    # 读取HISTSIZE的值（注意：HISTSIZE通常在用户的shell配置文件中，如.bashrc或.bash_profile，而不是/etc/profile。但为了这个例子，我们假设它在/etc/profile中。）
    HISTSIZE_VALUE=$(grep '^HISTSIZE=' /etc/profile | awk -F= '{print $2}')

    # 打印变量的值以验证
    echo "当前HISTSIZE 的值为: $HISTSIZE_VALUE"

    # 检查HISTSIZE的值是否为期望的值
    if [[ "$HISTSIZE_VALUE" != "0" ]]; then
        # 如果不是期望的值，则使用sed修改它
        sed -i '/^HISTSIZE=/s/=.*/=0/' /etc/profile
        # 再次读取并打印修改后的值以验证（注意：这里我们直接读取修改后的文件，而不是再次使用grep和awk，因为我们知道位置）
        HISTSIZE_VALUE=$(grep '^HISTSIZE=' /etc/profile | awk -F= '{print $2}')
        echo "修改后HISTSIZE 的值为: $HISTSIZE_VALUE"
    else
        echo "HISTSIZE 的值已经是 $DESIRED_HISTSIZE，无需修改。"
    fi

}

function sqfl() {
    ADMIN_USER="sysadmin"
    ADMIN_PASS="3UFrZE8Xue"
    AUDITOR_USER="shenjiadmin"
    AUDITOR_PASS="UY7Ze8Uydw"
    USER_USER="anquanadmin"
    USER_PASS="DVwUWP5Lty"

    if id "$ADMIN_USER" >/dev/null 2>&1; then
        ERROR "$ADMIN_USER用户存在"
    else
        useradd $ADMIN_USER
        echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
        echo "$ADMIN_USER ALL=(ALL:ALL) ALL" >> /etc/sudoers
    fi

    if id "$AUDITOR_USER" >/dev/null 2>&1; then
        ERROR "$AUDITOR_USER用户存在"
    else
        useradd $AUDITOR_USER
        echo "$AUDITOR_USER:$AUDITOR_PASS" | chpasswd
        setfacl -m u:$AUDITOR_USER:r /var/log/audit/
    fi

    if id "$USER_USER" >/dev/null 2>&1; then
        ERROR "$USER_USER用户存在"
    else
        useradd $USER_USER
        echo "$USER_USER:$USER_PASS" | chpasswd
    fi
    # 脚本结束提示
    echo "三权分立设置已完成。"
}

function main_return() {
      echo -e "1：设备具备密码复杂度校验功能，可配置如下：a）密码复杂度策略启用，设置密码长度最少8个字符，包含大小写字母、特殊符号和数字；b）密码更换周期最大为90天
2：Linux操作系统可设置用户的登录失败处理策略，配置如下：a）登录失败处理：尝试5次，锁定账户10分钟；b）登录连接超时退出：无操作超时时间5分钟自动退出登录界面。
3：Linux操作系统需采用ssh协议进行远程管理，能够防止鉴别信息在网络传输过程中被窃听。
6：Linux操作系统不应当有超级管理员权限，需对超级管理员进行三权分立。
7：Linux操作系统应具有安全审计功能模块，并启用安全审计功能，审计日志能够覆盖到每个用户
10：限制Linux操作系统的历史执行命令条数"
      read -erp "请输入数字:" num
    case "$num" in
    1)
        clear
        sbmmfzd
        ;;
    2)
        clear
        dlsbcl
        ;;
    3)
        clear
        disable_telnet
        ;;
    4)
        clear
        ;;
    5)
        clear
        ;;
    6)
        clear
        sqfl
        ;;
    7)
        clear
        # 检查并启动auditd服务
        check_and_start_service auditd
        # 检查并启动rsyslog服务
        check_and_start_service rsyslog
        ;;
    10)
        clear
        set_histsize
        ;;
    0)
        clear
        exit 0
        ;;
    *)
        clear
        ERROR '请输入正确数字 [0-9]'
        main_return
        ;;
    esac

}

function first_init() {
    root_need
}

function all() {
    root_need
    sbmmfzd
    dlsbcl
    disable_telnet
    sqfl
    # 检查并启动auditd服务
    check_and_start_service auditd
    # 检查并启动rsyslog服务
    check_and_start_service rsyslog
}


if [ ! "$*" ]; then
    first_init
    clear
    main_return
else
    first_init
    clear
    "$@"
fi