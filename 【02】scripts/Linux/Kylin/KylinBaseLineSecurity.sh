#!/bin/bash

# 该脚本适用于银河麒麟服务器操作系统 V10 SP2

# 确认是使用root用户执行脚本
#USER=$( env | grep '\<USER\>' | cut -d '=' -f 2 )
USER=$(whoami)
if [ "$USER" != 'root' ];then
    echo "Must Use Root User Run Script!!!"
    exit 0
fi

# 设置变量

# 日志系统配置文件
RSYSLOGCNF=/etc/rsyslog.conf
# 守护进程配置文件  暂时移除
# SNMPDCNF=/etc/snmp/snmpd.conf
# 用户账号相关配置文件
LOGIN=/etc/login.defs
SYSTEMAUTH=/etc/pam.d/system-auth
# 账户口令复杂度配置文件
PWQUALITY=/etc/security/pwquality.conf
# ssh配置文件
OPENSSH=/etc/ssh/sshd_config
# 系统环境配置文件
UMAKS_BASHRC=/etc/bashrc
UMAKS_PROFILE=/etc/profile
LIMIT=/etc/security/limits.conf
SU=/etc/pam.d/su
BANNER_ISSUE=/etc/issue
BANNER_ISSUENET=/etc/issue.net
SYSCTLCNF=/etc/sysctl.conf
AUDITRULE=/etc/audit/audit.rules
HOSTCNF=/etc/host.conf
ROOTBASHRC=/root/.bashrc
MESSAGES=/var/log/messages
# 备份文件存储地址
BACKUP=/root/config-bak
# 启动环境配置文件
GRUBCNF=/boot/grub2/grub.cfg
EFIGRUBCNF=/boot/efi/EFI/kylin/grub.cfg

# 备份各配置文件
kylin_backup()
{
    if [ -f $BACKUP/config_first_bak.tar.gz ];then
        echo "[ 已备份 ]: config_first_bak.tar.gz " 
    else
        echo "[ 备  份 ]: 现在开始备份相关配置文件"
        [ -d $BACKUP ] || mkdir $BACKUP &> /dev/null 
        cp --parents $LOGIN $BACKUP
        cp --parents $SYSTEMAUTH $BACKUP
        cp --parents $PWQUALITY $BACKUP
        cp --parents $LIMIT $BACKUP
        cp --parents $SU $BACKUP
        cp --parents $UMAKS_BASHRC $BACKUP
        cp --parents $UMAKS_PROFILE $BACKUP
        cp --parents $OPENSSH $BACKUP
        cp --parents $RSYSLOGCNF $BACKUP
        # cp --parents $SNMPDCNF $BACKUP
        cp --parents $SYSCTLCNF $BACKUP
        cp --parents $GRUBCNF $BACKUP
        cp --parents $EFIGRUBCNF $BACKUP
        cp --parents $AUDITRULE $BACKUP
        cp --parents $ROOTBASHRC $BACKUP
        cp --parents $MESSAGES $BACKUP
        cp --parents $HOSTCNF $BACKUP
        [ -f $BACKUP$LOGIN ] && echo "[ 已备份 ]: $LOGIN "
        [ -f $BACKUP$SYSTEMAUTH ] && echo "[ 已备份 ]: $SYSTEMAUTH "
        [ -f $BACKUP$PWQUALITY ] && echo "[ 已备份 ]: $PWQUALITY "
        [ -f $BACKUP$LIMIT ] && echo "[ 已备份 ]: $LIMIT "
        [ -f $BACKUP$SU ] && echo "[ 已备份 ]: $SU "
        [ -f $BACKUP$UMAKS_BASHRC ] && echo "[ 已备份 ]: $UMAKS_BASHRC "
        [ -f $BACKUP$UMAKS_PROFILE ] && echo "[ 已备份 ]: $UMAKS_PROFILE "
        [ -f $BACKUP$OPENSSH ] && echo "[ 已备份 ]: $OPENSSH "
        [ -f $BACKUP$RSYSLOGCNF ] && echo "[ 已备份 ]: $RSYSLOGCNF "
        # [ -f $BACKUP$SNMPDCNF ] && echo "[ 已备份 ]: $SNMPDCNF "
        [ -f $BACKUP$SYSCTLCNF ] && echo "[ 已备份 ]: $SYSCTLCNF "
        [ -f $BACKUP$GRUBCNF ] && echo "[ 已备份 ]: $GRUBCNF "
        [ -f $BACKUP$EFIGRUBCNF ] && echo "[ 已备份 ]: $EFIGRUBCNF "
        [ -f $BACKUP$AUDITRULE ] && echo "[ 已备份 ]: $AUDITRULE "
        [ -f $BACKUP$ROOTBASHRC ] && echo "[ 已备份 ]: $ROOTBASHRC "
        [ -f $BACKUP$MESSAGES ] && echo "[ 已备份 ]: $MESSAGES "
        [ -f $BACKUP$HOSTCNF ] && echo "[ 已备份 ]: $HOSTCNF "
        [ -f $BACKUP/config_first_bak.tar.gz ] || tar -zcvf $BACKUP/config_first_bak.tar.gz $BACKUP/etc/ &> /dev/null
        [ -f $BACKUP/config_first_bak.tar.gz ]  && echo "[ 已压缩 ]: config_first_bak.tar.gz "
    fi
}

set_login()
{
    # 密码最长使用天数修改为90天
    sed -i '/^PASS_MAX_DAYS/c PASS_MAX_DAYS    90' $LOGIN
    [ $? -eq 0 ] && echo "[ 已加固 ]: PASS_MAX_DAYS    90"
    # 密码修改最小隔天数修改为7天
    sed -i '/^PASS_MIN_DAYS/c PASS_MIN_DAYS    7' $LOGIN
    [ $? -eq 0 ] && echo "[ 已加固 ]: PASS_MIN_DAYS    7"
    # 密码最小长度修改为8个字符
    sed -i '/^PASS_MIN_LEN/c PASS_MIN_LEN     8' $LOGIN
    [ $? -eq 0 ] && echo "[ 已加固 ]: PASS_MIN_LEN     8"
    # 密码到期前提示天数修改为7天
    sed -i '/^PASS_WARN_AGE/c PASS_WARN_AGE    7' $LOGIN
    [ $? -eq 0 ] && echo "[ 已加固 ]: PASS_WARN_AGE    7"
}

set_pwqulity()
{
    # 设置密码的复杂度
    sed -i '/^minlen/c minlen = 8' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码最小长度为8个字符"
    sed -i '/^dcredit/c dcredit = -1' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码应包含的数字至少为一个"
    sed -i '/^ucredit/c ucredit = -1' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码应包含的大写字母至少一个"
    sed -i '/^lcredit/c lcredit = -1' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码应包含的小写字母的至少一个"
    sed -i '/^ocredit/c ocredit = -1' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码应包含的其他符号的最小数量，例如@，＃、! $％等，至少要有一个"
    sed -i '/^# difok/c difok = 3' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置新密码时至少3个字符不同于旧密码"
    sed -i '/^# maxrepeat/c maxrepeat = 3' $PWQUALITY
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置密码连续相同的字符最多为3个"
}

set_systemauth()
{
    # 记住5次历史密码
    [ -f /etc/security/opasswd ] || touch /etc/security/opasswd
    chown root:root /etc/security/opasswd
    chmod 600 /etc/security/opasswd
    grep -w --silent "remember=5" $SYSTEMAUTH 
    if [ $? -ne 0 ];then
        sed -i '/^password/{/pam_unix/s/$/ remember=5/}' $SYSTEMAUTH
    fi
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置记住5次历史密码"
    # 设置3次密码错误后，用户锁定180秒
    grep -w --silent "preauth audit deny=3 even_deny_root unlock_time=180" $SYSTEMAUTH
    if [ $? -ne 0 ];then
        sed -i '/^auth        required      pam_faillock.so/c \
        auth        required      pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=180' $SYSTEMAUTH
    fi
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置3次密码错误后，用户锁定180秒"
}

# set_sshd()
# {
#     # 指定每个连接最大允许的认证次数。默认值是 6 。
#     # 如果失败认证的次数超过这个数值的一半，连接将被强制断开，且会生成额外的失败日志消息。
#     sed -i '/^#MaxAuthTries/c MaxAuthTries 5' $OPENSSH
#     [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH MaxAuthTries 5"
#     # 在每一次交互式登录时打印最后一位用户的登录时间。默认值是"yes"
#     sed -i '/^#PrintLastLog/c PrintLastLog yes' $OPENSSH
#     [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH PrintLastLog yes"
#     # 是否允许 root 登录。设置为禁止root通过ssh登录
#     # sed -i '/^PermitRootLogin/ s/yes/no/' $OPENSSH
#     # [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH PermitRootLogin no"
#     # 是否允许使用公钥方式登录。设置为禁止使用公钥方式登录
#     # sed -i '/^PubkeyAuthentication/ s/yes/no/' $OPENSSH
#     # [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH PubkeyAuthentication no"
#     # 设置600秒没有收到客户端任何数据时，断开连接
#     sed -i '/^#ClientAliveInterval/c ClientAliveInterval 600' $OPENSSH
#     [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH ClientAliveInterval 600"
#     sed -i '/^#ClientAliveCountMax/c ClientAliveCountMax 0' $OPENSSH
#     [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH ClientAliveCountMax 0"
#     # 拒绝对主机名进行反向解析
#     # sed -i '/^#UseDNS/c UseDNS no' $OPENSSH
#     # [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH UseDNS no"
#     # 重启sshd服务
#     systemctl daemon-reload
#     systemctl restart sshd
#     [ $? -eq 0 ] && echo "[ 已加固 ]: $OPENSSH "
# }

set_umask()
{
    # 设置权限掩码(umask)为027
    sed -i 's/022/027/' $UMAKS_BASHRC
    sed -i 's/002/027/' $UMAKS_BASHRC
    sed -i 's/077/027/' $LOGIN
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置权限掩码(umask)为027 "
}

set_history()
{
    # 设置仅保存5条历史命令
    sed -i "/^HISTSIZE/ c HISTSIZE=5" $UMAKS_PROFILE
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置history命令仅输出5条历史命令 "
    grep -w --silent "HISTFILESIZE=5" $UMAKS_PROFILE
    if [ $? -ne 0 ];then
        sed -i "/^HISTSIZE/ a HISTFILESIZE=5" $UMAKS_PROFILE
    fi
    [ $? -eq 0 ] && echo "[ 已加固 ]: 设置仅保存5条历史命令 "
}

# set_su()
# {
#     # 限制用户使用su命令变更为其他用户，防止不当的角色切换
#     sed -i "/pam_wheel/{/required/ s/#//}" $SU
#     sed -i "/pam_wheel/{/required/ s/$/ group=wheel/}" $SU
#     [ $? -eq 0 ] && echo "[ 已加固 ]: 限制用户使用su命令变更为其他用户 "
# }

set_autologout()
{
    # 非活动用户在600秒后自动登出
    if [ -x /etc/profile.d/autologout.sh ];then
        echo "[ 已加固 ]: 非活动用户在600秒后自动登出 "
    else
        echo  -e "TMOUT=600\nreadonly TMOUT\nexport TMOUT" > /etc/profile.d/autologout.sh
        chmod +x /etc/profile.d/autologout.sh
        [ $? -eq 0 ] && echo "[ 已加固 ]: 非活动用户在600秒后自动登出 "
    fi
}

unset_autologout()
{
    # 取消关于非活动用户自动登出的设置
    if [ -f /etc/profile.d/autologout.sh ];then
        rm -rf /etc/profile.d/autologout.sh
    fi
}

set_kysec()
{
    # kysec 可以有效地保护系统，提供了放篡改、软件源安全认证、内核保护等安全管控机制，启动kysec可以有效保护系统安全。
    # 设置开启kysec,启用执行控制
    security-switch --set default &> /dev/null
    # kysec 设置成strict 模式会同时启用执行控制，SELinux和三权分立
    # security-switch --set strict &> /dev/null
    [ $? -eq 0 ] && echo "[ 已加固 ]: 开启kysec成功 "
    [ $? -eq 0 ] && echo "[ 已加固 ]: 系统安全级别切换成功，请立即重启系统生效!!! "
}

unset_kysec()
{
    # 设置关闭kysec
    [ -f $BACKUP$GRUBCNF ] && cp -v -f $BACKUP$GRUBCNF $GRUBCNF
    [ -f $BACKUP$EFIGRUBCNF ] && cp -v -f $BACKUP$EFIGRUBCNF $EFIGRUBCNF
}

# set_firewalld()
# {
#     # 设置服务器防火墙开启
#     systemctl is-active firewalld.service &> /dev/null
#     [ $? -eq 0 ] || systemctl start firewalld.service
#     systemctl is-enabled firewalld.service &> /dev/null
#     [ $? -eq 0 ] || systemctl enable firewalld.service
#     [ $? -eq 0 ] && echo "[ 已加固 ]: 开启firewalld并设置为开机启动 "
# }

# unset_firewalld()
# {
#     systemctl stop firewalld.service
#     systemctl disable firewalld.service
# }

set_rsyslog()
{
    systemctl is-active rsyslog.service &> /dev/null
    [ $? -eq 0 ] || systemctl enable --now rsyslog.service
    [ $? -eq 0 ] && echo "[ 已加固 ]: 开启rsyslog并设置为开机启动 "
}

kylin_secplus()
{
    # 安全加固代码汇总
    echo "[ 加  固 ]: 对当前服务器进行安全加固 "
    set_login
    set_pwqulity
    set_systemauth
    # set_sshd
    set_umask
    set_history
    # set_su
    set_autologout
    set_rsyslog
    # set_firewalld
    set_kysec
}

recovery()
{
    # 还原
    unset_kysec
    unset_autologout
    [ -f $BACKUP$LOGIN ] && cp -v -f $BACKUP$LOGIN $LOGIN
    [ -f $BACKUP$SYSTEMAUTH ] && cp -v -f $BACKUP$SYSTEMAUTH $SYSTEMAUTH
    [ -f $BACKUP$LIMIT ] && cp -v -f $BACKUP$LIMIT $LIMIT
    # [ -f $BACKUP$SU ] && cp -v -f $BACKUP$SU $SU
    [ -f $BACKUP$UMAKS_BASHRC ] && cp -v -f $BACKUP$UMAKS_BASHRC $UMAKS_BASHRC
    [ -f $BACKUP$UMAKS_PROFILE ] && cp -v -f $BACKUP$UMAKS_PROFILE $UMAKS_PROFILE
    [ -f $BACKUP$OPENSSH ] && cp -v -f $BACKUP$OPENSSH $OPENSSH
    [ -f $BACKUP$RSYSLOGCNF ] && cp -v -f $BACKUP$RSYSLOGCNF $RSYSLOGCNF
    # [ -f $BACKUP$SNMPDCNF ] && cp -v -f $BACKUP$SNMPDCNF $SNMPDCNF
    [ -f $BACKUP$SYSCTLCNF ] && cp -v -f $BACKUP$SYSCTLCNF $SYSCTLCNF
    [ -f $BACKUP$ROOTBASHRC ] && cp -v -f $BACKUP$ROOTBASHRC $ROOTBASHRC
    [ -f $BACKUP$AUDITRULE ] && cp -v -f $BACKUP$AUDITRULE $AUDITRULE
    [ -f $BACKUP$MESSAGES ] && cp -v -f $BACKUP$MESSAGES $MESSAGES
    [ -f $BACKUP$HOSTCNF ] && cp -v -f $BACKUP$HOSTCNF $HOSTCNF
    echo "[ 还  原 ]: 还原系统到初次配置状态,请立即重启系统生效 "
    exit 0
}


ext_jiagu()
{
    # 额外的加固
    
    # set audit
    echo -e "-D\n" >> /etc/audit/audit.rules
    echo -e "-b 8192\n" >> /etc/audit/audit.rules
    echo -e "-f 1\n" >> /etc/audit/audit.rules

    # set /host.conf
    sed -i '1 i order  hosts,bind' /etc/host.conf

    # set cammnd alias
    echo "alias ls='ls -aol'" >> /root/.bashrc

    # set only-read messages
    chattr +a /var/log/messages

    # set run-level
    systemctl set-default multi-user

    # off control+alt+delete
    rm -f /lib/systemd/system/ctrl-alt-del.target

    # config sysctl
    cat >> /etc/sysctl.conf <<EOF
#-------------------------------------------------------------------
vm.swappiness = 15
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 10
vm.dirty_background_ratio = 5
vm.dirty_ratio = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.lo.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.lo.accept_source_route = 0
EOF


}


help(){
    echo $"Usage: $0 Script Please Input Option { backup | jiagu | recovery }"
}

case "$1" in
    backup)
        kylin_backup
    ;;
    jiagu)
        kylin_backup
        kylin_secplus
    ;;
    recovery)
        recovery
    ;;
    help)
        help
    ;;
    debug)
        ext_jiagu
    ;;
    *)
        help
esac