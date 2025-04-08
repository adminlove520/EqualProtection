#!/bin/bash
echo "Linux安全检查与应急响应工具"
echo "Version:1.3"
echo "Author:Daily"
echo "Date:2020-11-11"


dos2unix buying.sh
date=$(date +%Y%m%d-%H%M%S)

ipadd=$(ifconfig -a | grep -w inet | grep -v 127.0.0.1 | awk 'NR==1{print $2}')

check_file="/tmp/buying_${ipadd}_${date}/check_file/"
danger_file="/tmp/buying_${ipadd}_${date}/danger_file.txt"
log_file="/tmp/buying_${ipadd}_${date}/log/"
rm -rf $check_file
rm -rf $danger_file
rm -rf log_file
mkdir /tmp/buying_${ipadd}_${date}/
echo "检查发现危险项,请注意:" > ${danger_file}
mkdir $check_file
echo "" >> $danger_file
mkdir $log_file
cd $check_file

if [ $(whoami) != "root" ];then
	echo "安全检查必须使用root账号,否则某些项无法检查"
	exit 1
fi


saveresult="tee -a checkresult.txt"
echo "[0.1]正在检查IP地址....." && "$saveresult"

echo -------------0.IP及版本-------------------
echo -------------0.1 IP地址-------------------
echo "[0.1]正在检查IP地址....." | $saveresult
ip=$(ifconfig -a | grep -w inet | awk '{print $2}')
if [ -n "$ip" ];then
	(echo "[*]本机IP地址信息:" && echo "$ip")  | $saveresult
else
	echo "[!!!]本机未配置IP地址" | $saveresult
fi
printf "\n" | $saveresult

echo ------------0.2 网络连接---------------------
echo "[0.2]正在检查网络连接情况....." | $saveresult
netstat=$(netstat -anlp | grep ESTABLISHED)
netstatnum=$(netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}')
if [ -n "$netstat" ];then
	(echo "[*]网络连接情况:" && echo "$netstat") | $saveresult
	if [ -n "$netstatnum" ];then
		(echo "[*]各个状态的数量如下:" && echo "$netstatnum") | $saveresult
	fi
else
	echo "[*]未发现网络连接" | $saveresult
fi
printf "\n" | $saveresult

echo ------------1.用户信息------------------
echo ------------1.1 查看登录用户------------------
echo "[1.1]正在检查正在登录的用户....." | $saveresult
(echo "[*]系统登录用户:" && who ) | $saveresult
printf "\n" | $saveresult


echo ------------1.2 查看用户信息------------------
echo "[1.2]正在查看用户信息....." | $saveresult
echo "[*]用户名:口令:用户标识号:组标识号:注释性描述:主目录:登录Shell" | $saveresult
more /etc/passwd  | $saveresult
printf "\n" | $saveresult


echo ------------1.3 检查超级用户---------------------
#UID=0的为超级用户,系统默认root的UID为0
echo "[1.3]正在检查是否存在超级用户....." | $saveresult
Superuser=`more /etc/passwd | egrep -v '^root|^#|^(\+:\*)?:0:0:::' | awk -F: '{if($3==0) print $1}'`
if [ -n "$Superuser" ];then
	echo "[!!!]除root外发现超级用户:" | tee -a $danger_file | $saveresult
else
	echo "[*]未发现超级用户" | $saveresult
fi
printf "\n" | $saveresult



echo ------------2.历史命令--------------------------
echo "[2]正在检查操作系统历史命令....." | $saveresult
history=$(more /root/.bash_history)
if [ -n "$history" ];then
	(echo "[*]操作系统历史命令如下:" && echo "$history") | $saveresult
else
	echo "[!!!]未发现历史命令,请检查是否记录及已被清除" | $saveresult
fi
printf "\n" | $saveresult


echo ------------3.进程分析--------------------
echo "[3]正在检查进程....." | $saveresult
ps=$(ps -aux)
if [ -n "$ps" ];then
	(echo "[*]系统进程如下:" && echo "$ps") | $saveresult
else
	echo "[*]未发现系统进程" | $saveresult
fi
printf "\n" | $saveresult

echo "正在检查守护进程....." | $saveresult
if [ -e /etc/xinetd.d/rsync ];then
	(echo "[*]系统守护进程:" && more /etc/xinetd.d/rsync | grep -v "^#") | $saveresult
else
	echo "[*]未发现守护进程" | $saveresult
fi
printf "\n" | $saveresult


echo ------------4.运行服务----------------------
echo "[4]正在检查运行服务....." | $saveresult
services=$(systemctl | grep -E "\.service.*running" | awk -F. '{print $1}')
if [ -n "$services" ];then
	(echo "[*]以下服务正在运行：" && echo "$services") | $saveresult
else
	echo "[!!!]未发现正在运行的服务！" | $saveresult
fi
printf "\n" | $saveresult


echo ------------5.CPU分析-----------------
echo "[5]正在检查CPU相关信息....." | $saveresult
(echo "CPU硬件信息如下:" && more /proc/cpuinfo ) | $saveresult
(echo "CPU使用情况如下:" && ps -aux | sort -nr -k 3 | awk  '{print $1,$2,$3,$NF}') | $saveresult
printf "\n" | $saveresult
echo ------------5.2占用CPU前5进程-----------------
echo "正在检查占用CPU前5资源的进程....." | $saveresult
(echo "占用CPU资源前5进程：" && ps -aux | sort -nr -k 3 | head -5)  | $saveresult
printf "\n" | $saveresult
echo ------------5.3占用CPU较大进程-----------------
echo "正在检查占用CPU较大的进程....." | $saveresult
pscpu=$(ps -aux | sort -nr -k 3 | head -5 | awk '{if($3>=20) print $0}')
if [ -n "$pscpu" ];then
	echo "[!!!]以下进程占用的CPU超过20%:" && echo "UID         PID   PPID  C STIME TTY          TIME CMD" 
	echo "$pscpu" | tee -a 20_pscpu.txt | tee -a $danger_file | $saveresult
else
	echo "[*]未发现进程占用资源超过20%" | $saveresult
fi
printf "\n" | $saveresult

echo ------------6.sshd配置文件--------------------
echo "[6]正在检查sshd配置....." | $saveresult
sshdconfig=$(more /etc/ssh/sshd_config | egrep -v "#|^$")
if [ -n "$sshdconfig" ];then
	(echo "[*]sshd配置文件如下:" && echo "$sshdconfig") | $saveresult
else
	echo "[！]未发现sshd配置文件" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7 日志分析------------------------------
echo ------------7.1 查看日志配置与打包-------------------
echo ------------7.1.1 查看日志配置----------------------
echo "[7.1.1]正在查看日志配置....." | $saveresult
logconf=$(more /etc/rsyslog.conf | egrep -v "#|^$")
if [ -n "$logconf" ];then
	(echo "[*]日志配置如下:" && echo "$logconf") | $saveresult
else
	echo "[!!!]未发现日志配置文件" | tee -a $danger_file | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.1.2日志是否存在---------------
echo "[7.1.2]正在分析日志文件是否存在....." | $saveresult
logs=$(ls -l /var/log/)
if [ -n "$logs" ];then
	echo "[*]日志文件存在" | $saveresult
else
	echo "[!!!]日志文件不存在,请分析是否被清除！" | tee -a $danger_file | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.1.3 日志审核是否开启---------------
echo "[7.1.3]正在分析日志审核是否开启....." | $saveresult
service auditd status | grep running
if [ $? -eq 0 ];then
	echo "[*]系统日志审核功能已开启,符合要求" | $saveresult
else
	echo "[!!!]系统日志审核功能已关闭,不符合要求,建议开启日志审核。可使用以下命令开启:service auditd start" | tee -a $danger_file | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.1.4 打包日志---------------
echo "[7.1.4]正在打包日志......" | $saveresult
zip -r ${log_file}system_log.zip /var/log/
if [ $? -eq 0 ];then
	echo "[*]日志打包成功" | $saveresult
else
	echo "[!!!]日志打包失败,请工人导出日志" | tee -a $danger_file | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.2secure日志分析---------------
echo ------------7.2.1成功登录--------------------
echo "[7.2.1]正在检查日志中成功登录的情况....." | $saveresult
loginsuccess=$(more /var/log/secure* | grep "Accepted password" | awk '{print $1,$2,$3,$9,$11}')
if [ -n "$loginsuccess" ];then
	(echo "[*]日志中分析到以下用户成功登录:" && echo "$loginsuccess")  | $saveresult
	(echo "[*]登录成功的IP及次数如下：" && grep "Accepted " /var/log/secure* | awk '{print $11}' | sort -nr | uniq -c )  | $saveresult
	(echo "[*]登录成功的用户及次数如下:" && grep "Accepted" /var/log/secure* | awk '{print $9}' | sort -nr | uniq -c )  | $saveresult
else
	echo "[*]日志中未发现成功登录的情况" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.2.2登录失败--------------------
echo "[7.2.2]存在检查日志中登录失败的情况....." | $saveresult
loginfailed=$(more /var/log/secure* | grep "Failed password" | awk '{print $1,$2,$3,$9,$11}')
if [ -n "$loginfailed" ];then
	(echo "[!!!]日志中发现以下登录失败的情况:" && echo "$loginfailed") |  tee -a $danger_file  | $saveresult
	(echo "[!!!]登录失败的IP及次数如下:" && grep "Failed password" /var/log/secure* | awk '{print $11}' | sort -nr | uniq -c)  | $saveresult
	(echo "[!!!]登录失败的用户及次数如下:" && grep "Failed password" /var/log/secure* | awk '{print $9}' | sort -nr | uniq -c)  | $saveresult
else
	echo "[*]日志中未发现登录失败的情况" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.2.3本机登录情况-----------------
echo "[7.2.3]正在检查图本机登录情况....." | $saveresult
systemlogin=$(more /var/log/secure* | grep -E "sshd:session.*session opened" | awk '{print $1,$2,$3,$11}')
if [ -n "$systemlogin" ];then
	(echo "[*]本机登录情况:" && echo "$systemlogin") | $saveresult
	(echo "[*]本机登录账号及次数如下:" && more /var/log/secure* | grep -E "sshd:session.*session opened" | awk '{print $11}' | sort -nr | uniq -c) | $saveresult
else
	echo "[!!!]未发现在本机登录退出情况,请注意！！！" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.2.4新增用户-------------------
echo "[7.2.4]正在检查新增用户....." | $saveresult
newusers=$(more /var/log/secure* | grep "new user"  | awk -F '[=,]' '{print $1,$2}' | awk '{print $1,$2,$3,$9}')
if [ -n "$newusers" ];then
	(echo "[!!!]日志中发现新增用户:" && echo "$newusers") | tee -a $danger_file | $saveresult
	(echo "[*]新增用户账号及次数如下:" && more /var/log/secure* | grep "new user" | awk '{print $8}' | awk -F '[=,]' '{print $2}' | sort | uniq -c) | $saveresult
else
	echo "[*]日志中未发现新增加用户" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.2.5新增用户组-----------------
echo "[7.2.5]正在检查新增用户组....." | $saveresult
newgoup=$(more /var/log/secure* | grep "new group"  | awk -F '[=,]' '{print $1,$2}' | awk '{print $1,$2,$3,$9}')
if [ -n "$newgoup" ];then
	(echo "[!!!]日志中发现新增用户组:" && echo "$newgoup") | tee -a $danger_file | $saveresult
	(echo "[*]新增用户组及次数如下:" && more /var/log/secure* | grep "new group" | awk '{print $8}' | awk -F '[=,]' '{print $2}' | sort | uniq -c) | $saveresult
else
	echo "[*]日志中未发现新增加用户组" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.3message日志分析---------------
echo ------------7.3 传输文件--------------------
#下面命令仅显示传输的文件名,并会将相同文件名的去重
#more /var/log/message* | grep "ZMODEM:.*BPS" | awk -F '[]/]' '{print $0}' | sort | uniq
echo "[7.3]正在检查传输文件....." | $saveresult
zmodem=$(more /var/log/message* | grep "ZMODEM:.*BPS")
if [ -n "$zmodem" ];then
	(echo "[!!!]传输文件情况:" && echo "$zmodem") | tee -a $danger_file | $saveresult
else
	echo "[*]日志中未发现传输文件" | $saveresult
fi
printf "\n" | $saveresult

echo -----------7.4cron日志分析---------------
echo ------------7.4.1定时下载-----------------
echo "[7.4.1]正在分析定时下载....." | $saveresult
cron_download=$(more /var/log/cron* | grep "wget|curl")
if [ -n "$cron_download" ];then
	(echo "[!!!]定时下载情况:" && echo "$cron_download") | tee -a $danger_file | $saveresult
else
	echo "[*]未发现定时下载情况" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.4.2定时执行脚本-----------------
echo "[7.4.2]正在分析定时执行脚本....." | $saveresult
cron_shell=$(more /var/log/cron* | grep -E "\.py$|\.sh$|\.pl$") 
if [ -n "$cron_shell" ];then
	(echo "[!!!]发现定时执行脚本:" && echo "$cron_download") | tee -a $danger_file | $saveresult
else
	echo "[*]未发现定时下载脚本" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.5 btmp日志分析----------------------
echo ------------7.5 错误登录日志分析-----------------
echo "[7.5]正在分析错误登录日志....." | $saveresult
lastb=$(lastb)
if [ -n "$lastb" ];then
	(echo "[*]错误登录日志如下:" && echo "$lastb") | $saveresult
else
	echo "[*]未发现错误登录日志" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.6 lastlog日志分析----------------------
echo ------------7.6 所有用户最后一次登录日志分析-----------------
echo "[7.6]正在分析所有用户最后一次登录日志....." | $saveresult
lastlog=$(lastlog)
if [ -n "$lastlog" ];then
	(echo "[*]所有用户最后一次登录日志如下:" && echo "$lastlog") | $saveresult
else
	echo "[*]未发现所有用户最后一次登录日志" | $saveresult
fi
printf "\n" | $saveresult

echo ------------7.7 wtmp日志分析---------------
echo ------------7.7 所有登录用户分析-------
echo "[7.7]正在检查历史上登录到本机的用户:" | $saveresult
lasts=$(last | grep pts | grep -vw :0)
if [ -n "$lasts" ];then
	(echo "[*]历史上登录到本机的用户如下:" && echo "$lasts") | $saveresult
else
	echo "[*]未发现历史上登录到本机的用户信息" | $saveresult
fi
printf "\n" | $saveresult

echo -------------8.启动项-----------------------
echo -------------8.1 用户自定义启动项-----------------------
echo "[8.1]正在检查用户自定义启动项....." | $saveresult
chkconfig=$(chkconfig --list | grep -E ":on|启用" | awk '{print $1}')
if [ -n "$chkconfig" ];then
	(echo "[*]用户自定义启动项:" && echo "$chkconfig") | $saveresult
else
	echo "[!!!]未发现用户自定义启动项" | $saveresult
fi
printf "\n" | $saveresult

echo -------------8.2 系统自启动项-----------------------
echo "[8.2]正在检查系统自启动项....." | $saveresult
systemchkconfig=$(systemctl list-unit-files | grep enabled | awk '{print $1}')
if [ -n "$systemchkconfig" ];then
	(echo "[*]系统自启动项如下:" && echo "$systemchkconfig")  | $saveresult
else
	echo "[*]未发现系统自启动项" | $saveresult
fi
printf "\n" | $saveresult

echo -------------8.3 危险启动项-----------------------
echo "[8.3]正在检查危险启动项....." | $saveresult
dangerstarup=$(chkconfig --list | grep -E ":on|启用" | awk '{print $1}' | grep -E "\.(sh|per|py)$")
if [ -n "$dangerstarup" ];then
	(echo "[!!!]发现危险启动项:" && echo "$dangerstarup") | tee -a $danger_file | $saveresult
else
	echo "[*]未发现危险启动项" | $saveresult
fi
printf "\n" | $saveresult

echo ------------9.查看定时任务-------------------
echo ------------9.1系统定时任务分析-------------------
echo "[9.1]正在分析系统定时任务....." | $saveresult
syscrontab=$(more /etc/crontab | grep -v "# run-parts" | grep run-parts)
if [ -n "$syscrontab" ];then
	(echo "[!!!]发现存在系统定时任务:" && more /etc/crontab ) | tee -a $danger_file | $saveresult
else
	echo "[*]未发现系统定时任务" | $saveresult
fi
printf "\n" | $saveresult

# if [ $? -eq 0 ]表示上面命令执行成功;执行成功输出的是0；失败非0
#ifconfig  echo $? 返回0，表示执行成功
# if [ $? != 0 ]表示上面命令执行失败

echo ------------9.2分析系统可疑定时任务-------------------
echo "[9.2]正在分析系统可疑任务....." | $saveresult
dangersyscron=$(egrep "((chmod|useradd|groupadd|chattr)|((wget|curl)*\.(sh|pl|py)$))"  /etc/cron*/* /var/spool/cron/*)
if [ $? -eq 0 ];then
	(echo "[!!!]发现下面的定时任务可疑,请注意！！！" && echo "$dangersyscron") | tee -a $danger_file | $saveresult
else
	echo "[*]未发现可疑系统定时任务" | $saveresult
fi
printf "\n" | $saveresult

echo ------------9.3分析用户定时任务-------------------
echo ------------9.3.1查看用户定时任务-------------------
echo "[9.3.1]正在查看用户定时任务....." | $saveresult
crontab=$(crontab -l)
if [ $? -eq 0 ];then
	(echo "[!!!]发现用户定时任务如下:" && echo "$crontab") | $saveresult
else
	echo "[*]未发现用户定时任务"  | $saveresult
fi
printf "\n" | $saveresult

echo ------------9.3.2查看可疑用户定时任务-------------------
echo "[9.3.2]正在分析可疑用户定时任务....." | $saveresult
danger_crontab=$(crontab -l | egrep "((chmod|useradd|groupadd|chattr)|((wget|curl).*\.(sh|pl|py)))")
if [ $? -eq 0 ];then
	(echo "[!!!]发现可疑定时任务,请注意！！！" && echo "$danger_crontab") | tee -a $danger_file | $saveresult
else
	echo "[*]未发现可疑定时任务" | $saveresult
fi
printf "\n" | $saveresult

echo ------------10 最近24小时内变动的文件---------------------
#查看最近24小时内有改变的文件
(find / -mtime 0 | grep -E "\.(py|sh|per|pl|php|asp|jsp)$") | tee -a $danger_file | $saveresult
printf "\n" | $saveresult

echo "检查结束！！！"
