#!/bin/bash
#
########################## Anonymous #########################
# Function : ssh centos baseline                            #
# Platform : Centos7.x-8.x & Rocky8.x & openEuler 20.x-22.x #
# Version  : 1.6                                            #
# Date     : 2024-07-18                                     #
#############################################################
#
clear
export LANG="en_US.UTF-8"
date_date=$(date +%Y%m%d)
date_time=$(date +%Y%m%d-%H%M%S)
OLD_IFS=$IFS
IFS=$' '
 
#建议根据脚本上传的位置修改 <<==================================
shell_home="/opt/baseline"
#文件目录
bak_files="$shell_home/bak"
log_files="$shell_home/log"
 
#输出信息颜色
color_0="\033[0m"
color_R="\033[31m"
color_G="\033[32m"
color_Y="\033[33m" 
color_C="\033[36m"
 
#判断是否root用户
if [ $(id -u) != "0" ] ; then
	echo -e "\n"
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "当前用户为普通用户，必须使用root用户运行，脚本退出. . ."
	sleep 1
	echo -e "\n"
	exit
fi
 
echo -e "\n"
 
baseline_start()
{
	if [[ -e /etc/redhat-release ]] || [[ -e /etc/openEuler-release ]] || [[ -e /etc/hce-release ]] ; then
		if [ -e /etc/redhat-release ] ; then
			redhat_version=`cat /etc/redhat-release | sed -r 's/.* ([0-9]+)\..*/\1/'`
			if [[ $redhat_version -lt 6 || $redhat_version -gt 8 ]] ; then
				echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "当前操作系统版本可能不被支持，脚本退出. . ."
				sleep 0.25
				echo -e "\n"
				exit
			fi
		fi
		if [ -e /etc/openEuler-release ] ; then
			openeuler_version=`cat /etc/openEuler-release | sed -r 's/.* ([0-9]+)\..*/\1/'`
			if [[ $openeuler_version -lt 20 || $openeuler_version -gt 22 ]] ; then
				echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "当前操作系统版本可能不被支持，脚本退出. . ."
				sleep 0.25
				echo -e "\n"
				exit
			fi
		fi
		if [ -e /etc/hce-release ] ; then
			hce_version=`cat /etc/hce-release | sed -r 's/.* ([0-9]+)\..*/\1/'`
			if [[ $hce_version -lt 1 || $hce_version -gt 2 ]] ; then
				echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "当前操作系统版本可能不被支持，脚本退出. . ."
				sleep 0.25
				echo -e "\n"
				exit
			fi
		fi
	else
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "当前操作系统可能不被支持，脚本退出. . ."
		sleep 0.25
		echo -e "\n"
		exit
	fi
 
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"即将对系统进行基线配置，过程将对SSH等多个配置文件进行修改，可能会造成SSH重启失败。"$color_0
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"脚本运行过程中请保持活动的连接窗口，切勿中途中断！避免因配置不完整无法重连服务器。"$color_0
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"建议复制一个连接窗口以备不时之需，或自行配置Telnet服务预留另一个远程连接通道。"$color_0
	echo -en `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"基线脚本即将开始，如暂不运行请在倒计时结束前按Ctrl+C终止脚本，倒计时: "$color_0
	count=11
	tput sc
	while true
	do
		if [ $count -ge 1 ] ; then
			let count--
			sleep 1
			tput rc
			tput ed
			echo -en $color_R"$count "$color_0
		else
			break
		fi
	done
	echo -e ""
 
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在创建过程目录. . ."
	sleep 0.25
 
	#创建文件
	mkdir -p $shell_home
	mkdir -p $bak_files
	mkdir -p $log_files
 
	if [[ -f "$log_files/baseline_$date_date.log" ]]; then
		rm -rf $log_files/baseline_$date_date.log >/dev/null 2>&1
	fi
 
	systemusers=$(awk -F: '$3 >= 1000 && $3 <=65000 {print $1}' /etc/passwd | tr "\n" " " | sed -e 's/,$/\n/')
}
 
 
baseline_ssh()
{
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"开始执行配置SSH合规项. . ."$color_0
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在备份SSH目录及配置文件. . ."
	\cp -rfL /etc/ssh $bak_files/ssh.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/ssh/sshd_config $bak_files/sshd_config.$date_time.bak >/dev/null 2>&1
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制/etc/ssh/sshd_config的访问权限. . ."
	chown root:root /etc/ssh/sshd_config
	chmod og-rwx /etc/ssh/sshd_config
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制SSH服务使用的密钥文件权限. . ."
	chmod 400 /etc/ssh/*key
	chmod 400 /etc/ssh/*key.pub
	chown -R root:root /etc/ssh/*key
	chown -R root:root /etc/ssh/*key.pub
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "使用更加安全的Ciphers算法. . ."
	grep -E "^#Ciphers|^\s*Ciphers" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*Ciphers/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*Ciphers/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#Ciphers.*/s/^#Ciphers.*/Ciphers aes256-ctr,aes192-ctr,aes128-ctr/" /etc/ssh/sshd_config
	else
		echo -e "\nCiphers aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
	fi
	grep -E "^Ciphers.*aes256-ctr,aes192-ctr,aes128-ctr" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "使用更加安全的MAC算法. . ."
	grep -E "^#MACs|^\s*MACs" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*MACs/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*MACs/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#MACs.*/s/^#MACs.*/MACs hmac-sha2-512,hmac-sha2-256/" /etc/ssh/sshd_config
	else
		echo -e "\nMACs hmac-sha2-512,hmac-sha2-256" >> /etc/ssh/sshd_config
	fi
	grep -E "^MACs.*hmac-sha2-512,hmac-sha2-256" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中HostbasedAuthentication关闭. . ."
	grep -E "^#HostbasedAuthentication|^\s*HostbasedAuthentication" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*HostbasedAuthentication/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*HostbasedAuthentication/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#HostbasedAuthentication.*/s/^#HostbasedAuthentication.*/HostbasedAuthentication no/" /etc/ssh/sshd_config
	else
		echo -e "\nHostbasedAuthentication no" >> /etc/ssh/sshd_config
	fi
	grep -E "^HostbasedAuthentication.*no" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中PermitEmptyPasswords被禁用. . ."
	grep -E "^#PermitEmptyPasswords|^\s*PermitEmptyPasswords" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PermitEmptyPasswords/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*PermitEmptyPasswords/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#PermitEmptyPasswords.*/s/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/" /etc/ssh/sshd_config
	else
		echo -e "\nPermitEmptyPasswords no" >> /etc/ssh/sshd_config
	fi
	grep -E "^PermitEmptyPasswords.*no" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保配置了SSH空闲超时间隔_配置1. . ."
	grep -E "^#ClientAliveInterval|^\s*ClientAliveInterval" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ClientAliveInterval/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*ClientAliveInterval/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#ClientAliveInterval.*/s/^#ClientAliveInterval.*/ClientAliveInterval 300/" /etc/ssh/sshd_config
	else
		echo -e "\nClientAliveInterval 300" >> /etc/ssh/sshd_config
	fi
	grep -E "^ClientAliveInterval.*300" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保配置了SSH空闲超时间隔_配置2. . ."
	grep -E "^#ClientAliveCountMax|^\s*ClientAliveCountMax" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ClientAliveCountMax/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*ClientAliveCountMax/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#ClientAliveCountMax.*/s/^#ClientAliveCountMax.*/ClientAliveCountMax 0/" /etc/ssh/sshd_config
	else
		echo -e "\nClientAliveCountMax 0" >> /etc/ssh/sshd_config
	fi
	grep -E "^ClientAliveCountMax.*0" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保设置了SSH警告提示信息. . ."
	grep "^\s*Banner" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sleep 0.25
		echo -e $color_G "[PASS]"$color_0
	else
		grep "^#Banner" /etc/ssh/sshd_config >/dev/null 2>&1
		if [ $? -eq 0 ] ; then
			sed -i "/^#Banner/ s/^\(.*\)$/Banner \/etc\/ssh\/issue\.Banner/" /etc/ssh/sshd_config
		else
			echo -e "\nBanner /etc/ssh/issue.Banner/" >> /etc/ssh/sshd_config
		fi
		echo -e "\nAuthorized users only. All activity may be monitored and reported.\n" > /etc/ssh/issue.Banner
		sleep 0.25
		echo -e $color_G "[PASS]"$color_0
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中X11转发被禁用. . ."
	grep -E "^#X11Forwarding|^\s*X11Forwarding" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*X11Forwarding/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#X11Forwarding.*/s/^#X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
	else
		echo -e "\nX11Forwarding no" >> /etc/ssh/sshd_config
	fi
	grep -E "^X11Forwarding.*no" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中MaxAuthTries设置小于等于4. . ."
	grep -E "^#MaxAuthTries|^\s*MaxAuthTries" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*MaxAuthTries/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*MaxAuthTries/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#MaxAuthTries.*/s/^#MaxAuthTries.*/MaxAuthTries 4/" /etc/ssh/sshd_config
	else
		echo -e "\nMaxAuthTries 4" >> /etc/ssh/sshd_config
	fi
	grep -E "^MaxAuthTries.*4" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中IgnoreRhosts被允许. . ."
	grep -E "^#IgnoreRhosts|^\s*IgnoreRhosts" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*IgnoreRhosts/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*IgnoreRhosts/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#IgnoreRhosts.*/s/^#IgnoreRhosts.*/IgnoreRhosts yes/" /etc/ssh/sshd_config
	else
		echo -e "\nIgnoreRhosts yes" >> /etc/ssh/sshd_config
	fi
	grep -E "^IgnoreRhosts.*yes" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中PermitUserEnvironment被禁用. . ."
	grep -E "^#PermitUserEnvironment|^\s*PermitUserEnvironment" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PermitUserEnvironment/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*PermitUserEnvironment/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#PermitUserEnvironment.*/s/^#PermitUserEnvironment.*/PermitUserEnvironment no/" /etc/ssh/sshd_config
	else
		echo -e "\nPermitUserEnvironment no" >> /etc/ssh/sshd_config
	fi
	grep -E "^PermitUserEnvironment.*no" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中LoginGraceTime设置为一分钟或更短. . ."
	grep -E "^#LoginGraceTime|^\s*LoginGraceTime" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*LoginGraceTime/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*LoginGraceTime/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#LoginGraceTime.*/s/^#LoginGraceTime.*/LoginGraceTime 60/" /etc/ssh/sshd_config
	else
		echo -e "\nLoginGraceTime 60" >> /etc/ssh/sshd_config
	fi
	grep -E "^LoginGraceTime.*60" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制root用户SSH远程登录. . ."
	grep -E "^#PermitRootLogin|^\s*PermitRootLogin" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PermitRootLogin/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*PermitRootLogin/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#PermitRootLogin.*/s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
	else
		echo -e "\nPermitRootLogin no" >> /etc/ssh/sshd_config
	fi
	grep -E "^PermitRootLogin.*no" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制仅允许SSH协议2版本连接. . ."
	grep -E "^#Protocol|^\s*Protocol" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*Protocol/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*Protocol/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#Protocol.*/s/^#Protocol.*/Protocol 2/" /etc/ssh/sshd_config
	else
		echo -e "\nProtocol 2" >> /etc/ssh/sshd_config
	fi
	grep -E "^Protocol.*2" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保SSH中LogLevel设置为INFO. . ."
	grep -E "^#LogLevel|^\s*LogLevel" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*LogLevel/ s/^\s*//" /etc/ssh/sshd_config
		sed -i "/^\s*LogLevel/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
		sed -i "0,/^#LogLevel.*/s/^#LogLevel.*/LogLevel INFO/" /etc/ssh/sshd_config
	else
		echo -e "\nLogLevel INFO" >> /etc/ssh/sshd_config
	fi
	grep -E "^LogLevel.*INFO" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查SSH访问是否受限制. . ."
	grep -E "^\s*#\s*AllowUsers" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i 's/^\s*#\s*AllowUsers/AllowUsers/' /etc/ssh/sshd_config
	fi
	grep -E "^\s*AllowUsers" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*AllowUsers/ s/^\s*//" /etc/ssh/sshd_config
		allowusers1=$(grep -E "^\s*AllowUsers" /etc/ssh/sshd_config)
		allowusers2="AllowUsers root $systemusers"
		if [[ "$allowusers1" == "$allowusers2" ]] ; then
			echo -e $color_G "[PASS]"$color_0
		else
			sed -i "/^\s*AllowUsers/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
			echo -e $color_R "[FAIL]"$color_0
			echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查SSH访问是否受限制 --> 正在配置"$color_C "root $systemusers"$color_0"用户允许SSH访问，请根据需要修改配置，. . ."
			sed -i "0,/^#AllowUsers.*/s/^#AllowUsers.*/AllowUsers root $systemusers/" /etc/ssh/sshd_config
		fi
	else
		echo -e $color_R "[FAIL]"$color_0
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查SSH访问是否受限制 --> 正在配置"$color_C "root $systemusers"$color_0"用户允许SSH访问，请根据需要修改配置，. . ."
		echo -e "AllowUsers root $systemusers" >> /etc/ssh/sshd_config
	fi
	grep -E "^AllowUsers.*root" /etc/ssh/sshd_config >/dev/null 2>&1
	sleep 0.25
	if [ $? -ne 0 ] ; then
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制SFTP用户访问目录. . ."
	grep -E "sftpgroup" /etc/group >/dev/null 2>&1 
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
	    groupadd sftpgroup
	    echo -e $color_G "[PASS]"$color_0
	fi
 
	if ! id -u sftpuser >/dev/null 2>&1 ; then
	    useradd -m -p pawjdbSgI7v8. sftpuser
	    usermod -s /sbin/nologin sftpuser
	    usermod -a -G sftpgroup sftpuser
	    chown root:root /home/sftpuser
	    chage --inactive 30 sftpuser
	    chage -M 90 -m 10 -W 7 sftpuser
	fi
 
	grep "^\s*Match" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*Match/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
	fi
	echo -e "\nMatch Group sftpgroup" >> /etc/ssh/sshd_config
 
	grep -E "^\tX11Forwarding" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\tX11Forwarding/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
	fi
	echo -e "\tX11Forwarding no" >> /etc/ssh/sshd_config
 
	grep -E "^\s*AllowTcpForwarding" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*AllowTcpForwarding/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
	fi
	echo -e "\tAllowTcpForwarding no" >> /etc/ssh/sshd_config
 
	grep -E "^\s*ForceCommand" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ForceCommand/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
	fi
	echo -e "\tForceCommand internal-sftp" >> /etc/ssh/sshd_config
 
	grep -E "^\s*ChrootDirectory" /etc/ssh/sshd_config >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ChrootDirectory/ s/^\(.*\)$/#\1/g" /etc/ssh/sshd_config
	fi
	echo -e "\tChrootDirectory /home/sftpuser" >> /etc/ssh/sshd_config
	sleep 0.25
}
 
baseline_system()
{
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 $color_C"开始执行配置CENTOS合规项. . ."$color_0
	sleep 0.25
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在备份相关配置文件. . ."
	\cp -rfL /etc/logrotate.conf $bak_files/logrotate.conf.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/login.defs $bak_files/login.defs.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/pam.d/password-auth $bak_files/password-auth.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/pam.d/system-auth $bak_files/system-auth.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/security/pwquality.conf $bak_files/pwquality.conf.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/profile $bak_files/profile.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/bashrc $bak_files/bashrc.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/pam.d/su $bak_files/su.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/rsyslog.conf $bak_files/rsyslog.conf.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/security/limits.conf $bak_files/limits.conf.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/sysctl.conf $bak_files/sysctl.conf.$date_time.bak >/dev/null 2>&1
	\cp -rfL /etc/audit/auditd.conf $bak_files/auditd.conf.$date_time.bak >/dev/null 2>&1
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置操作系统的审计记录保存180天. . ."
	grep -E "^#rotate|^\s*rotate" /etc/logrotate.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*rotate/ s/^\s*//" /etc/logrotate.conf
		sed -i "/^\s*rotate/ s/^\(.*\)$/#\1/g" /etc/logrotate.conf
		sed -i "0,/^#rotate.*/s/^#rotate.*/rotate 28/" /etc/logrotate.conf
	else
		echo -e "\nrotate 28" >> /etc/logrotate.conf
	fi
	grep -E "^rotate.*28" /etc/logrotate.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令生存期 --> PASS_MAX_DAYS. . ."
	grep -E "^#PASS_MAX_DAYS|^\s*PASS_MAX_DAYS" /etc/login.defs >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PASS_MAX_DAYS/ s/^\s*//" /etc/login.defs
		sed -i "/^\s*PASS_MAX_DAYS/ s/^\(.*\)$/#\1/g" /etc/login.defs
		sed -i "0,/^#PASS_MAX_DAYS.*/s/^#PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/" /etc/login.defs
	else
		echo -e "\nPASS_MAX_DAYS\t90" >> /etc/login.defs
	fi
	grep -E "^PASS_MAX_DAYS.*90" /etc/login.defs >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令生存期 --> PASS_MIN_DAYS. . ."
	grep -E "^#PASS_MIN_DAYS|^\s*PASS_MIN_DAYS" /etc/login.defs >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PASS_MIN_DAYS/ s/^\s*//" /etc/login.defs
		sed -i "/^\s*PASS_MIN_DAYS/ s/^\(.*\)$/#\1/g" /etc/login.defs
		sed -i "0,/^#PASS_MIN_DAYS.*/s/^#PASS_MIN_DAYS.*/PASS_MIN_DAYS\t10/" /etc/login.defs
	else
		echo -e "\nPASS_MIN_DAYS\t10" >> /etc/login.defs
	fi
	grep -E "^PASS_MIN_DAYS.*10" /etc/login.defs >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令生存期 --> PASS_MIN_LEN. . ."
	grep -E "^#PASS_MIN_LEN|^\s*PASS_MIN_LEN" /etc/login.defs >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PASS_MIN_LEN/ s/^\s*//" /etc/login.defs
		sed -i "/^\s*PASS_MIN_LEN/ s/^\(.*\)$/#\1/g" /etc/login.defs
		sed -i "0,/^#PASS_MIN_LEN.*/s/^#PASS_MIN_LEN.*/PASS_MIN_LEN\t8/" /etc/login.defs
	else
		echo -e "\nPASS_MIN_LEN\t8" >> /etc/login.defs
	fi
	grep -E "^PASS_MIN_LEN.*8" /etc/login.defs >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令生存期 --> PASS_WARN_AGE. . ."
	grep -E "^#PASS_WARN_AGE|^\s*PASS_WARN_AGE" /etc/login.defs >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*PASS_WARN_AGE/ s/^\s*//" /etc/login.defs
		sed -i "/^\s*PASS_WARN_AGE/ s/^\(.*\)$/#\1/g" /etc/login.defs
		sed -i "0,/^#PASS_WARN_AGE.*/s/^#PASS_WARN_AGE.*/PASS_WARN_AGE\t7/" /etc/login.defs
	else
		echo -e "\nPASS_WARN_AGE\t7" >> /etc/login.defs
	fi
	grep -E "^PASS_WARN_AGE.*7" /etc/login.defs >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	
	for systemusers_i in $systemusers ; do
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令生存期 --> 正在配置用户"$color_C"$systemusers_i"$color_0". . ."
		chage -M 90 -m 10 -W 7 $systemusers_i
		sleep 0.25
	done
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置1. . ."
	grep -E "^#password.*requisite.*pam_pwquality.so|^\s*password.*requisite.*pam_pwquality.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*password.*requisite.*pam_pwquality.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*password.*requisite.*pam_pwquality.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#password.*requisite.*pam_pwquality.so.*/s/^#password.*requisite.*pam_pwquality.so.*/password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/password-auth
	else
		echo -e "\npassword    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/password-auth
	fi
	grep -E "^password.*requisite.*pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置2. . ."
	grep -E "^#password.*requisite.*pam_pwquality.so|^\s*password.*requisite.*pam_pwquality.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*password.*requisite.*pam_pwquality.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*password.*requisite.*pam_pwquality.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#password.*requisite.*pam_pwquality.so.*/s/^#password.*requisite.*pam_pwquality.so.*/password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/" /etc/pam.d/system-auth
	else
		echo -e "\npassword    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/system-auth
	fi
	grep -E "^password.*requisite.*pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置3. . ."
	grep -E "^#minlen|^\s*minlen" /etc/security/pwquality.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*minlen/ s/^\s*//" /etc/security/pwquality.conf
		sed -i "/^\s*minlen/ s/^\(.*\)$/#\1/g" /etc/security/pwquality.conf
		sed -i "0,/^#minlen.*/s/^#minlen.*/minlen = 8/" /etc/security/pwquality.conf
	else
		echo -e "\nminlen = 8" >> /etc/security/pwquality.conf
	fi
	grep -E "^minlen.*=.*8" /etc/security/pwquality.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置4. . ."
	grep -E "^#dcredit|^\s*dcredit" /etc/security/pwquality.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*dcredit/ s/^\s*//" /etc/security/pwquality.conf
		sed -i "/^\s*dcredit/ s/^\(.*\)$/#\1/g" /etc/security/pwquality.conf
		sed -i "0,/^#dcredit.*/s/^#dcredit.*/dcredit = -1/" /etc/security/pwquality.conf
	else
		echo -e "\ndcredit = -1" >> /etc/security/pwquality.conf
	fi
	grep -E "^dcredit.*=.*-1" /etc/security/pwquality.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置5. . ."
	grep -E "^#ucredit|^\s*ucredit" /etc/security/pwquality.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ucredit/ s/^\s*//" /etc/security/pwquality.conf
		sed -i "/^\s*ucredit/ s/^\(.*\)$/#\1/g" /etc/security/pwquality.conf
		sed -i "0,/^#ucredit.*/s/^#ucredit.*/ucredit = -1/" /etc/security/pwquality.conf
	else
		echo -e "\nucredit = -1" >> /etc/security/pwquality.conf
	fi
	grep -E "^ucredit.*=.*-1" /etc/security/pwquality.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置6. . ."
	grep -E "^#lcredit|^\s*lcredit" /etc/security/pwquality.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*lcredit/ s/^\s*//" /etc/security/pwquality.conf
		sed -i "/^\s*lcredit/ s/^\(.*\)$/#\1/g" /etc/security/pwquality.conf
		sed -i "0,/^#lcredit.*/s/^#lcredit.*/lcredit = -1/" /etc/security/pwquality.conf
	else
		echo -e "\nlcredit = -1" >> /etc/security/pwquality.conf
	fi
	grep -E "^lcredit.*=.*-1" /etc/security/pwquality.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令复杂度_配置7. . ."
	grep -E "^#ocredit|^\s*ocredit" /etc/security/pwquality.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*ocredit/ s/^\s*//" /etc/security/pwquality.conf
		sed -i "/^\s*ocredit/ s/^\(.*\)$/#\1/g" /etc/security/pwquality.conf
		sed -i "0,/^#ocredit.*/s/^#ocredit.*/ocredit = -1/" /etc/security/pwquality.conf
	else
		echo -e "\nocredit = -1" >> /etc/security/pwquality.conf
	fi
	grep -E "^ocredit.*=.*-1" /etc/security/pwquality.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查文件与目录缺省权限控制_配置1. . ."
	grep -E "^#umask|^umask" /etc/profile >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^umask/ s/^\(.*\)$/#\1/g" /etc/profile
		sed -i "0,/^#umask.*/s/^#umask.*/umask 0027/" /etc/profile
	else
		echo -e "\numask 0027" >> /etc/profile
	fi
	grep -E "^umask.*0027" /etc/profile >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查文件与目录缺省权限控制_配置2. . ."
	grep -E "^#umask|^umask" /etc/bashrc >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^umask/ s/^\(.*\)$/#\1/g" /etc/bashrc
		sed -i "0,/^#umask.*/s/^#umask.*/umask 0027/" /etc/bashrc
	else
		echo -e "\numask 0027" >> /etc/bashrc
	fi
	grep -E "^umask.*0027" /etc/bashrc >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查登陆超时时间设置. . ."
	grep -E "^#export TMOUT|^\s*export TMOUT" /etc/profile >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*export TMOUT/ s/^\s*//" /etc/profile
		sed -i "/^\s*export TMOUT/ s/^\(.*\)$/#\1/g" /etc/profile
		sed -i "0,/^#export TMOUT.*/s/^#export TMOUT.*/export TMOUT=300/" /etc/profile
	else
		echo -e "\nexport TMOUT=300" >> /etc/profile
	fi
	grep -E "^export TMOUT.*=.*300" /etc/profile >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止wheel组以外的用户使用su命令_配置1. . ."
	grep -E "^#auth.*sufficient.*pam_rootok.so|^\s*auth.*sufficient.*pam_rootok.so" /etc/pam.d/su >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*sufficient.*pam_rootok.so/ s/^\s*//" /etc/pam.d/su
		sed -i "/^\s*auth.*sufficient.*pam_rootok.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/su
		sed -i "0,/^#auth.*sufficient.*pam_rootok.so.*/s/^#auth.*sufficient.*pam_rootok.so.*/auth\t\tsufficient\tpam_rootok.so/" /etc/pam.d/su
	else
		echo -e "\nauth\t\tsufficient\tpam_rootok.so" >> /etc/pam.d/su
	fi
	grep -E "^auth.*sufficient.*pam_rootok.so" /etc/pam.d/su >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止wheel组以外的用户使用su命令_配置2. . ."
	grep -E "^#auth.*required.*pam_wheel.so|^\s*auth.*required.*pam_wheel.so" /etc/pam.d/su >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*required.*pam_wheel.so/ s/^\s*//" /etc/pam.d/su
		sed -i "/^\s*auth.*required.*pam_wheel.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/su
		sed -i "0,/^#auth.*required.*pam_wheel.so.*/s/^#auth.*required.*pam_wheel.so.*/auth\t\trequired\tpam_wheel.so\tgroup=wheel/" /etc/pam.d/su
	else
		echo -e "\nauth\t\trequired\tpam_wheel.so\tgroup=wheel" >> /etc/pam.d/su
	fi
	grep -E "^auth.*required.*pam_wheel.so.*group=wheel" /etc/pam.d/su >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止wheel组以外的用户使用su命令_配置3. . ."
	grep -E "^#SU_WHEEL_ONLY|^\s*SU_WHEEL_ONLY" /etc/login.defs >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*SU_WHEEL_ONLY/ s/^\s*//" /etc/login.defs
		sed -i "/^\s*SU_WHEEL_ONLY/ s/^\(.*\)$/#\1/g" /etc/login.defs
		sed -i "0,/^#SU_WHEEL_ONLY.*/s/^#SU_WHEEL_ONLY.*/SU_WHEEL_ONLY yes/" /etc/login.defs
	else
		echo -e "\nSU_WHEEL_ONLY yes" >> /etc/login.defs
	fi
	grep -E "^SU_WHEEL_ONLY.*yes" /etc/login.defs >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "把现有登陆权限的用户加入wheel组. . ."
	for systemusers_i in $systemusers ; do
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "把现有登陆权限的用户加入wheel组 --> 正在配置用户"$color_C"$systemusers_i"$color_0"，请根据需要修改配置. . ."
		groups $systemusers_i | grep -E "wheel" >/dev/null 2>&1
		if [ $? -ne 0 ] ; then
			usermod -a -G wheel $systemusers_i >/dev/null 2>&1
		fi
		sleep 0.25
	done
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "口令重复次数限制_配置1. . ."
	grep -E "^#password.*sufficient.*pam_unix.so|^\s*password.*sufficient.*pam_unix.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*password.*sufficient.*pam_unix.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*password.*sufficient.*pam_unix.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#password.*sufficient.*pam_unix.so.*/s/^#password.*sufficient.*pam_unix.so.*/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/" /etc/pam.d/password-auth
	else
		echo -e "\npassword    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5" >> /etc/pam.d/password-auth
	fi
	grep -E "^password.*sufficient.*pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "口令重复次数限制_配置2. . ."
	grep -E "^#password.*sufficient.*pam_unix.so|^\s*password.*sufficient.*pam_unix.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*password.*sufficient.*pam_unix.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*password.*sufficient.*pam_unix.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#password.*sufficient.*pam_unix.so.*/s/^#password.*sufficient.*pam_unix.so.*/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/" /etc/pam.d/system-auth
	else
		echo -e "\npassword    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5" >> /etc/pam.d/system-auth
	fi
	grep -E "^password.*sufficient.*pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置用户最小授权. . ."
	chmod 700 /etc/security >/dev/null 2>&1
	chmod 644 /etc/passwd >/dev/null 2>&1
	chmod 644 /etc/group >/dev/null 2>&1
	chmod 644 /etc/services >/dev/null 2>&1
	#chmod 600 /etc/xinetd.conf >/dev/null 2>&1
	chmod 400 /etc/shadow >/dev/null 2>&1
	chmod 400 /etc/gshadow >/dev/null 2>&1
 
	chown root:root /etc/security >/dev/null 2>&1
	chown root:root /etc/passwd >/dev/null 2>&1
	chown root:root /etc/group >/dev/null 2>&1
	chown root:root /etc/services >/dev/null 2>&1
	chown root:root /etc/shadow >/dev/null 2>&1
	chown root:root /etc/gshadow >/dev/null 2>&1
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "设置关键文件的属性. . ."
	chattr +a /var/log/messages >/dev/null 2>&1
	usermod -s /sbin/nologin sync >/dev/null 2>&1
	usermod -s /sbin/nologin halt >/dev/null 2>&1
	usermod -s /sbin/nologin shutdown >/dev/null 2>&1
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
#	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "锁定系统中重要文件. . ."
#	chattr +i /etc/passwd >/dev/null 2>&1
#	chattr +i /etc/shadow >/dev/null 2>&1
#	chattr +i /etc/group >/dev/null 2>&1
#	chattr +i /etc/gshadow >/dev/null 2>&1
#	echo -e $color_G "[PASS]"$color_0
#	sleep 0.25
 
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查不活跃的密码锁定是否小于等于30天. . ."
	for systemusers_i in $systemusers ; do
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查不活跃的密码锁定是否小于等于30天 --> 正在配置用户"$color_C"$systemusers_i"$color_0". . ."
		chage --inactive 30 $systemusers_i
		sleep 0.25
	done
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "记录守护进程产生的DEBUG日志. . ."
	grep -E "^#daemon.debug|^\s*daemon.debug" /etc/rsyslog.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*daemon.debug/ s/^\s*//" /etc/rsyslog.conf
		sed -i "/^\s*daemon.debug/ s/^\(.*\)$/#\1/g" /etc/rsyslog.conf
		sed -i "0,/^#daemon.debug.*/s/^#daemon.debug.*/daemon.debug/" /etc/rsyslog.conf
	else
		echo -e "\ndaemon.debug" >> /etc/rsyslog.conf
	fi
	grep -E "^daemon.debug" /etc/rsyslog.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查系统core dump状态_配置1. . ."
	grep -E "^\*.*soft.*core" /etc/security/limits.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\*.*soft.*core/d" /etc/security/limits.conf
	fi
	grep -E "^\*.*hard.*core" /etc/security/limits.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\*.*hard.*core/d" /etc/security/limits.conf
	fi
	sed -i "/^# End of file/d" /etc/security/limits.conf
	echo -e "\n*\tsoft\tcore\t0\n*\thard\tcore\t0" >> /etc/security/limits.conf
	echo -e "\n# End of file" >> /etc/security/limits.conf
	grep -E "^\*.*soft.*core.*0" /etc/security/limits.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查系统core dump状态_配置2. . ."
	grep -E "^\*.*hard.*core.*0" /etc/security/limits.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^ulimit.*-S" /etc/profile >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^ulimit.*-S/ s/^\(.*\)$/#\1/g" /etc/profile
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止组合键关机. . ."
	if [[ -f "/usr/lib/systemd/system/ctrl-alt-del.target" ]]; then
		rm -rf  /usr/lib/systemd/system/ctrl-alt-del.target
	fi
	sleep 0.25
	echo -e $color_G "[PASS]"$color_0
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制历史命令设置_配置1. . ."
	grep -E "^#HISTFILESIZE|^\s*HISTFILESIZE" /etc/profile >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*HISTFILESIZE/ s/^\s*//" /etc/profile
		sed -i "/^\s*HISTFILESIZE/ s/^\(.*\)$/#\1/g" /etc/profile
		sed -i "0,/^#HISTFILESIZE.*/s/^#HISTFILESIZE.*/HISTFILESIZE=5/" /etc/profile
	else
		echo -e "\nHISTFILESIZE=5" >> /etc/profile
	fi
	grep -E "^HISTFILESIZE.*=.*5" /etc/profile >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "限制历史命令设置_配置1. . ."
	grep -E "^#HISTSIZE|^\s*HISTSIZE" /etc/profile >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*HISTSIZE/ s/^\s*//" /etc/profile
		sed -i "/^\s*HISTSIZE/ s/^\(.*\)$/#\1/g" /etc/profile
		sed -i "0,/^#HISTSIZE.*/s/^#HISTSIZE.*/HISTSIZE=5/" /etc/profile
	else
		echo -e "\nHISTSIZE=5" >> /etc/profile
	fi
	grep -E "^HISTSIZE.*=.*5" /etc/profile >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止ICMP重定向. . ."
	grep -E "^#net.ipv4.conf.all.accept_redirects|^\s*net.ipv4.conf.all.accept_redirects" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.accept_redirects/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.conf.all.accept_redirects/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.conf.all.accept_redirects.*/s/^#net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects=0/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.conf.all.accept_redirects.*=.*0" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.conf.all.accept_redirects|^\s*net.ipv4.conf.all.accept_redirects" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.accept_redirects/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止IP源路由_配置1. . ."
	grep -E "^#net.ipv4.conf.all.accept_source_route|^\s*net.ipv4.conf.all.accept_source_route" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.accept_source_route/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.conf.all.accept_source_route/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.conf.all.accept_source_route.*/s/^#net.ipv4.conf.all.accept_source_route.*/net.ipv4.conf.all.accept_source_route=0/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.conf.all.accept_source_route.*=.*0" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.conf.all.accept_source_route|^\s*net.ipv4.conf.all.accept_source_route" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.accept_source_route/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "禁止IP源路由_配置2. . ."
	grep -E "^#net.ipv4.conf.default.accept_source_route|^\s*net.ipv4.conf.default.accept_source_route" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.default.accept_source_route/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.conf.default.accept_source_route/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.conf.default.accept_source_route.*/s/^#net.ipv4.conf.default.accept_source_route.*/net.ipv4.conf.default.accept_source_route=0/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.conf.default.accept_source_route=0" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.conf.default.accept_source_route.*=.*0" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.conf.default.accept_source_route|^\s*net.ipv4.conf.default.accept_source_route" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.default.accept_source_route/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "确保忽略广播的ICMP请求. . ."
	grep -E "^#net.ipv4.icmp_echo_ignore_broadcasts|^\s*net.ipv4.icmp_echo_ignore_broadcasts" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.icmp_echo_ignore_broadcasts/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.icmp_echo_ignore_broadcasts/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.ic^\s*mp_echo_ignore_broadcasts.*/s/^#net.ipv4.icmp_echo_ignore_broadcasts.*/net.ipv4.icmp_echo_ignore_broadcasts=1/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.icmp_echo_ignore_broadcasts.*=.*1" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.icmp_echo_ignore_broadcasts|^\s*net.ipv4.icmp_echo_ignore_broadcasts" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.icmp_echo_ignore_broadcasts/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查可疑数据包是否被记录_配置1. . ."
	grep -E "^#net.ipv4.conf.all.log_martians|^\s*net.ipv4.conf.all.log_martians" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.log_martians/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.conf.all.log_martians/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.conf.all.log_martians.*/s/^#net.ipv4.conf.all.log_martians.*/net.ipv4.conf.all.log_martians=1/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.conf.all.log_martians.*=.*1" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.conf.all.log_martians|^\s*net.ipv4.conf.all.log_martians" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.all.log_martians/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查可疑数据包是否被记录_配置2. . ."
	grep -E "^#net.ipv4.conf.default.log_martians|^\s*net.ipv4.conf.default.log_martians" /etc/sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.default.log_martians/ s/^\s*//" /etc/sysctl.conf
		sed -i "/^\s*net.ipv4.conf.default.log_martians/ s/^\(.*\)$/#\1/g" /etc/sysctl.conf
		sed -i "0,/^#net.ipv4.conf.default.log_martians.*/s/^#net.ipv4.conf.default.log_martians.*/net.ipv4.conf.default.log_martians=1/" /etc/sysctl.conf
	else
		echo -e "\nnet.ipv4.conf.default.log_martians=1" >> /etc/sysctl.conf
	fi
	grep -E "^net.ipv4.conf.default.log_martians.*=.*1" /etc/sysctl.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	grep -E "^#net.ipv4.conf.default.log_martians|^\s*net.ipv4.conf.default.log_martians" /etc/sysctl.d/99-sysctl.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*net.ipv4.conf.default.log_martians/ s/^\(.*\)$/#\1/g" /etc/sysctl.d/99-sysctl.conf
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置1. . ."
	grep -E "^#auth.*required.*pam_faillock.so|^\s*auth.*required.*pam_faillock.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*required.*pam_faillock.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*auth.*required.*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#auth.*required.*pam_faillock.so.*/s/^#auth.*required.*pam_faillock.so.*/auth        required      pam_faillock.so preauth audit silent deny=5 unlock_time=180/" /etc/pam.d/password-auth
	else
		echo -e "\nauth        required      pam_faillock.so preauth audit silent deny=5 unlock_time=180" >> /etc/pam.d/password-auth
	fi
	grep -E "^auth.*required.*pam_faillock.so preauth audit silent deny=5 unlock_time=180" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置2. . ."
	grep -E "^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so|^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so.*/s/^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so.*/auth        [success=1 default=bad]        pam_unix.so/" /etc/pam.d/password-auth
	else
		echo -e "\nauth        [success=1 default=bad]        pam_unix.so" >> /etc/pam.d/password-auth
	fi
	grep -E "^auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置3. . ."
	grep -E "^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so|^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so.*/s/^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so.*/auth        [default=die]        pam_faillock.so authfail audit deny=5 unlock_time=180/" /etc/pam.d/password-auth
	else
		echo -e "\nauth        [default=die]        pam_faillock.so authfail audit deny=5 unlock_time=180" >> /etc/pam.d/password-auth
	fi
	grep -E "^auth.*\[.*default.*=.*die.*\].*pam_faillock.so authfail audit deny=5 unlock_time=180" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置4. . ."
	grep -E "^#auth.*sufficient.*pam_faillock.so|^\s*auth.*sufficient.*pam_faillock.so" /etc/pam.d/password-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*sufficient.*pam_faillock.so/ s/^\s*//" /etc/pam.d/password-auth
		sed -i "/^\s*auth.*sufficient.*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/password-auth
		sed -i "0,/^#auth.*sufficient.*pam_faillock.so.*/s/^#auth.*sufficient.*pam_faillock.so.*/auth        sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=180/" /etc/pam.d/password-auth
	else
		echo -e "\nauth        sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=180" >> /etc/pam.d/password-auth
	fi
	grep -E "^auth.*sufficient.*pam_faillock.so authsucc audit deny=5 unlock_time=180" /etc/pam.d/password-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置5. . ."
	grep -E "^#auth.*required.*pam_faillock.so|^\s*auth.*required.*pam_faillock.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*required.*pam_faillock.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*auth.*required.*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#auth.*required.*pam_faillock.so.*/s/^#auth.*required.*pam_faillock.so.*/auth        required      pam_faillock.so preauth audit silent deny=5 unlock_time=180/" /etc/pam.d/system-auth
	else
		echo -e "\nauth        required      pam_faillock.so preauth audit silent deny=5 unlock_time=180" >> /etc/pam.d/system-auth
	fi
	grep -E "^auth.*required.*pam_faillock.so preauth audit silent deny=5 unlock_time=180" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置6. . ."
	grep -E "^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so|^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so.*/s/^#auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so.*/auth        [success=1 default=bad]        pam_unix.so/" /etc/pam.d/system-auth
	else
		echo -e "\nauth        [success=1 default=bad]        pam_unix.so" >> /etc/pam.d/system-auth
	fi
	grep -E "^auth.*\[.*success.*=.*1.*default.*=.*bad.*\].*pam_unix.so" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置7. . ."
	grep -E "^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so|^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*auth.*\[.*default.*=.*die.*\].*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so.*/s/^#auth.*\[.*default.*=.*die.*\].*pam_faillock.so.*/auth        [default=die]        pam_faillock.so authfail audit deny=5 unlock_time=180/" /etc/pam.d/system-auth
	else
		echo -e "\nauth        [default=die]        pam_faillock.so authfail audit deny=5 unlock_time=180" >> /etc/pam.d/system-auth
	fi
	grep -E "^auth.*\[.*default.*=.*die.*\].*pam_faillock.so authfail audit deny=5 unlock_time=180" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "配置口令锁定策略_配置8. . ."
	grep -E "^#auth.*sufficient.*pam_faillock.so|^\s*auth.*sufficient.*pam_faillock.so" /etc/pam.d/system-auth >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*auth.*sufficient.*pam_faillock.so/ s/^\s*//" /etc/pam.d/system-auth
		sed -i "/^\s*auth.*sufficient.*pam_faillock.so/ s/^\(.*\)$/#\1/g" /etc/pam.d/system-auth
		sed -i "0,/^#auth.*sufficient.*pam_faillock.so.*/s/^#auth.*sufficient.*pam_faillock.so.*/auth        sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=180/" /etc/pam.d/system-auth
	else
		echo -e "\nauth        sufficient    pam_faillock.so authsucc audit deny=5 unlock_time=180" >> /etc/pam.d/system-auth
	fi
	grep -E "^auth.*sufficient.*pam_faillock.so authsucc audit deny=5 unlock_time=180" /etc/pam.d/system-auth >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
}
 
baseline_yuminstall()
{
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在重建yum源缓存. . ."
	yum clean all >/dev/null 2>&1
	yum makecache >> $log_files/baseline_$date_date.log 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "重建yum源缓存失败，基于yum安装的脚本不执行. . ."
		sleep 1
		return
	fi
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查AIDE是否安装. . ."
	rpm -qa | grep -E "^aide-" >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查AIDE是否安装 --> 正在安装aide服务. . ."
		yum -y install aide >> $log_files/baseline_$date_date.log 2>&1
		if [ $? -eq 0 ] ; then
			echo -e $color_G "[PASS]"$color_0
		else
			echo -e $color_R "[FAIL]"$color_0
			errorline=$[$LINENO-2]
			baseline_error
		fi
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查audit是否安装. . ."
	rpm -qa | grep -E "^audit-" >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查audit是否安装 --> 正在安装audit服务. . ."
		yum -y install audit >> $log_files/baseline_$date_date.log 2>&1
		if [ $? -eq 0 ] ; then
			echo -e $color_G "[PASS]"$color_0
		else
			echo -e $color_R "[FAIL]"$color_0
			errorline=$[$LINENO-2]
			baseline_error
		fi
	fi
	sleep 0.25
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查audit服务是否已启动. . ."
	service auditd status 2>/dev/null | grep -E "is.*running|active.*running" >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在启动audit服务. . ."
		sleep 0.25
		chkconfig auditd on >/dev/null 2>&1
		service auditd start >/dev/null 2>&1
		service auditd status 2>/dev/null | grep -E "is.*running|active.*running" >/dev/null 2>&1
		if [ $? -eq 0 ] ; then
			sleep 0.25
			echo -e $color_G "[PASS]"$color_0
		else
			sleep 0.25
			echo -e $color_R "[FAIL]"$color_0
			errorline=$[$LINENO-2]
			baseline_error
		fi
	fi
 
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查audit日志是否不会自动删除. . ."
	grep -E "^#max_log_file_action|^\s*max_log_file_action" /etc/audit/auditd.conf >/dev/null 2>&1
	if [ $? -eq 0 ] ; then
		sed -i "/^\s*max_log_file_action/ s/^\s*//" /etc/audit/auditd.conf
		sed -i "/^\s*max_log_file_action/ s/^\(.*\)$/#\1/g" /etc/audit/auditd.conf
		sed -i "0,/^#max_log_file_action.*/s/^#max_log_file_action.*/max_log_file_action = keep_logs/" /etc/audit/auditd.conf
	else
		echo -e "\nmax_log_file_action = keep_logs" >> /etc/audit/auditd.conf
	fi
	grep -E "^max_log_file_action.*=.*keep_logs" /etc/audit/auditd.conf >/dev/null 2>&1
	sleep 0.25
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0
	else
		echo -e $color_R "[FAIL]"$color_0
		errorline=$[$LINENO-2]
		baseline_error
	fi
}
 
baseline_userscheck()
{
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "检查系统用户状态. . ." | tee -a $log_files/baseline_$date_date.log
	sleep 0.25
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "系统中有登录权限的用户有："$color_C`awk -F: '($7=="/bin/bash"){print $1}' /etc/passwd | tr '\n' ' ' | sed -e 's/,$/\n/'`$color_0 ". . ." | tee -a $log_files/baseline_$date_date.log
	sleep 0.25
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "系统中UID=0的用户有："$color_C`awk -F: '($3=="0"){print $1}' /etc/passwd | tr '\n' ' ' | sed -e 's/,$/\n/'`$color_0 ". . ." | tee -a $log_files/baseline_$date_date.log
	sleep 0.25
	N=`awk -F: '($2==""){print $1}' /etc/shadow | wc -l` >/dev/null 2>&1
	if [ $N -eq 0 ] ; then
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "系统中无空密码用户. . ." | tee -a $log_files/baseline_$date_date.log
	else
		echo -e `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "系统中空密码用户有："$color_R"`awk -F: 'length($2)==0 {print $1}' /etc/shadow | tr '\n' ' ' | sed -e 's/,$/\n/'`请及时配置密码或删除用户"$color_0 ". . ." | tee -a $log_files/baseline_$date_date.log		
	fi
	sleep 0.25
}
 
baseline_reload()
{
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在重启SSH服务. . ." | tee -a $log_files/baseline_$date_date.log
	service sshd restart >> $log_files/baseline_$date_date.log 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0 | tee -a $log_files/baseline_$date_date.log
	else
		echo -e $color_R "[FAIL]"$color_0 | tee -a $log_files/baseline_$date_date.log
	fi
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在重新加载profile用户参数. . ." | tee -a $log_files/baseline_$date_date.log
	source /etc/profile >> $log_files/baseline_$date_date.log 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0 | tee -a $log_files/baseline_$date_date.log
	else
		echo -e $color_R "[FAIL]"$color_0 | tee -a $log_files/baseline_$date_date.log
	fi
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在重新加载bashrc用户参数. . ." | tee -a $log_files/baseline_$date_date.log
	source /etc/bashrc >> $log_files/baseline_$date_date.log 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0 | tee -a $log_files/baseline_$date_date.log
	else
		echo -e $color_R "[FAIL]"$color_0 | tee -a $log_files/baseline_$date_date.log
	fi
	sleep 0.25
	echo -ne `date +%Y-%m-%d_%H:%M:%S` $color_Y"INFO"$color_0 "正在加载用户内核参数. . ." | tee -a $log_files/baseline_$date_date.log
	sysctl -p >> $log_files/baseline_$date_date.log 2>&1
	if [ $? -eq 0 ] ; then
		echo -e $color_G "[PASS]"$color_0 | tee -a $log_files/baseline_$date_date.log
	else
		echo -e $color_R "[FAIL]"$color_0 | tee -a $log_files/baseline_$date_date.log
	fi
	sleep 0.25
}
 
 
baseline_end()
{
	chown `logname`.`logname` $shell_home -R > /dev/null 2>&1
	find $shell_home -type f -exec chmod 644 {} \; > /dev/null 2>&1
	find $shell_home -type d -exec chmod 755 {} \; > /dev/null 2>&1
	echo -e "\n"
	echo -e $color_G"======================== install file ========================"$color_0
	echo -e ""
	echo -e "备份目录: " 
	cd  $bak_files && pwd
	cd ~
	echo -e ""
	echo -e "日志目录: "
	cd  $log_files && pwd
	cd ~
	echo -e ""
	echo -e $color_G"=============================================================="$color_0
	echo -e "\n"
	IFS=$OLD_IFS
	sleep 1
}
 
baseline_error()
{
	echo -e `date +%Y-%m-%d_%H:%M:%S` $color_R"ERROR"$color_0 "脚本在"$color_C"第$errorline行"$color_0"执行失败，请查阅脚本定位失败位置. . ."| tee -a $log_files/baseline_$date_date.log
	sleep 1
	echo -e "\n"
	baseline_end
	exit
}
 
baseline_start
baseline_ssh
baseline_system
baseline_yuminstall
baseline_userscheck
baseline_reload
baseline_end