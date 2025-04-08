#! /bin/bash 

######################################
# Linux主机安全基线检查
# Date:2020-12-23
# 使用前请给文件执行权限:chmod u+x check.sh
# 如提示找不到文件 在vi编辑模式下 set ff=uninx
# by Gamma安全实验室
######################################
scanner_time=`date '+%Y-%m-%d_%H:%M:%S'`
mkdir Check_log
scanner_log="./Check_log/checkResult_${scanner_time}.log"
uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
#调用函数库
[ -f /etc/init.d/functions ] && source /etc/init.d/functions
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile
#Require root to run this script.
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
#报错日志记录
[ -f ${scanner_log} ] || touch ${scanner_log}
function getSystemStatus(){
    echo ""
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo "     系统：$OS"
    echo " 发行版本：$Release"
    echo "     内核：$Kernel"
    echo "   主机名：$Hostname"
    echo "  SELinux：$SELinux"
    echo "语言/编码：$default_LANG"
    echo " 扫描时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
    export LANG="$default_LANG"
}
bk_safe(){
  echo ""
  echo -e "\033[33m********************************Linux主机安全基线检查***********************************\033[0m"
  echo "" >> ${scanner_log}
  echo "***********************`hostname -s` 主机安全检查结果********************************"  >> ${scanner_log}
  getSystemStatus >> ${scanner_log}
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`账号策略检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[1] 账号策略检查中..." /bin/true
  passmax=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v ^# | awk '{print $2}'`
  passmin=`cat /etc/login.defs | grep PASS_MIN_DAYS | grep -v ^# | awk '{print $2}'`
  passlen=`cat /etc/login.defs | grep PASS_MIN_LEN | grep -v ^# | awk '{print $2}'`
  passage=`cat /etc/login.defs | grep PASS_WARN_AGE | grep -v ^# | awk '{print $2}'`
  if [ $passmax -le 90 -a $passmax -gt 0 ];then
    echo "[Y] 口令生存周期为${passmax}天，符合要求" >> ${scanner_log}
  else
    echo "[N] 口令生存周期为${passmax}天，不符合要求,建议设置不大于90天" >> ${scanner_log}
  fi
  if [ $passmin -ge 6 ];then
    echo "[Y] 口令更改最小时间间隔为${passmin}天，符合要求" >> ${scanner_log}
  else
    echo "[N] 口令更改最小时间间隔为${passmin}天，不符合要求，建议设置大于等于6天" >> ${scanner_log}
  fi
  if [ $passlen -ge 8 ];then
    echo "[Y] 口令最小长度为${passlen},符合要求" >> ${scanner_log}
  else
    echo "[N] 口令最小长度为${passlen},不符合要求，建议设置最小长度大于等于8" >> ${scanner_log}
  fi
  if [ $passage -ge 30 -a $passage -lt $passmax ];then
    echo "[Y] 口令过期警告时间天数为${passage},符合要求" >> ${scanner_log}
  else
    echo "[N] 口令过期警告时间天数为${passage},不符合要求，建议设置大于等于30并小于口令生存周期" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`登录超时检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[2] 登录超时检查中..." /bin/true
  checkTimeout=$(cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}')
  if [ $? -eq 0 ];then
    TMOUT=`cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}'`
    if [ $TMOUT -le 600 -a $TMOUT -ge 10 ];then
      echo "[Y] 账号超时的时间是${TMOUT}秒,符合要求" >> ${scanner_log}
    else
      echo "[N] 账号超时的时间是${TMOUT}秒,不符合要求，建议设置小于600秒">> ${scanner_log}
    fi
  else
    echo "[N] 账号超时不存在自动注销,不符合要求，建议设置小于600秒" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`特权用户检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[3] 特权用户检查中..." /bin/true
  UIDS=`awk -F[:] 'NR!=1{print $3}' /etc/passwd`
  flag=0
  for i in $UIDS
  do
    if [ $i = 0 ];then
       flag=1
    fi
  done
  if [ $flag != 1 ];then
    echo "[Y] 不存在root账号外的UID为0的异常用户" >> ${scanner_log}
  else
    echo "[N] 存在非root但UID为0的异常用户，请立刻进行排查" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`空登录口令用户检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[4] 空登录口令用户检查中..." /bin/true
  userlist=`awk -F: 'length($2)==0 {print $1}' /etc/shadow`
  [ ! $userlist ] && echo "[Y] 不存在空登录口令用户"  >> ${scanner_log}
  for i in $userlist
  do
    echo "[N] $i登录密码为空，不符合要求，建议为该用户设置密码！"  >> ${scanner_log}
  done
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`具有sudo权限用户检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[5] sudo权限用户检查中..." /bin/true
  sudolist=`cat /etc/sudoers |grep -v '^#' |grep -v Defaults| grep -v '^$'`
  echo "$sudolist"  >> ${scanner_log}
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`用户缺省权限检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[6] 用户缺省权限检查中..." /bin/true
  umask1=`cat /etc/profile | grep umask | grep -v ^# | awk '{print $2}'`
  umask2=`cat /etc/csh.cshrc | grep umask | grep -v ^# | awk '{print $2}'`
  umask3=`cat /etc/bashrc | grep umask | grep -v ^# | awk 'NR!=1{print $2}'`
  flags=0
  for i in $umask1
  do
    if [ $i != "027" ];then
      echo "[N] /etc/profile文件中所所设置的umask为${i},不符合要求，建议设置为027" >> ${scanner_log}
      flags=1
      break
    fi
  done
  if [ $flags == 0 ];then
    echo "[Y] /etc/profile文件中所设置的umask为${i},符合要求" >> ${scanner_log}
  fi 
  flags=0
  for i in $umask2
  do
    if [ $i != "027" ];then
      echo "[N] /etc/csh.cshrc文件中所所设置的umask为${i},不符合要求，建议设置为027" >> ${scanner_log}
      flags=1
      break
    fi
  done  
  if [ $flags == 0 ];then
    echo "[Y] /etc/csh.cshrc文件中所设置的umask为${i},符合要求" >> ${scanner_log}
  fi
  flags=0
  for i in $umask3
  do
    if [ $i != "027" ];then
      echo "[N] /etc/bashrc文件中所设置的umask为${i},不符合要求，建议设置为027" >> ${scanner_log}
      flags=1
      break
    fi
  done
  if [ $flags == 0 ];then
    echo "[Y] /etc/bashrc文件中所设置的umask为${i},符合要求" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`系统关键目录权限检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[7] 系统关键目录权限检查中..." /bin/true
  file1=`ls -l /etc/passwd | awk '{print $1}'`
  file2=`ls -l /etc/shadow | awk '{print $1}'`
  file3=`ls -l /etc/group | awk '{print $1}'`
  file4=`ls -l /etc/securetty | awk '{print $1}'`
  file5=`ls -l /etc/services | awk '{print $1}'`
  #检测文件权限为400的文件
  if [ $file2 = "-r--------" ];then
    echo "[Y] /etc/shadow文件权限为400，符合要求" >> ${scanner_log}
  else
    echo "[N] /etc/shadow文件权限不为400，不符合要求，建议设置权限为400" >> ${scanner_log}
  fi
  #检测文件权限为600的文件
  if [ $file4 = "-rw-------" ];then
    echo "[Y] /etc/security文件权限为600，符合要求" >> ${scanner_log}
  else
    echo "[N] /etc/security文件权限不为600，不符合要求，建议设置权限为600" >> ${scanner_log}
  fi
  #检测文件权限为644的文件
  if [ $file1 = "-rw-r--r--" ];then
    echo "[Y] /etc/passwd文件权限为644，符合要求" >> ${scanner_log}
  else
    echo "[N] /etc/passwd文件权限不为644，不符合要求，建议设置权限为644" >> ${scanner_log}
  fi
  if [ $file5 = "-rw-r--r--" ];then
    echo "[Y] /etc/services文件权限为644，符合要求" >> ${scanner_log}
  else
    echo "[N] /etc/services文件权限不为644，不符合要求，建议设置权限为644" >> ${scanner_log}
  fi
  if [ $file3 = "-rw-r--r--" ];then
    echo "[Y] /etc/group文件权限为644，符合要求" >> ${scanner_log}
  else
    echo "[N] /etc/group文件权限不为644，不符合要求，建议设置权限为644" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`SSH配置检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[8] ssh配置检查中..." /bin/true
  remoteLogin=$(cat /etc/ssh/sshd_config | grep -v ^# |grep "PermitRootLogin no")
  if [ $? -eq 0 ];then
    echo "[Y] 已经设置root不能远程登陆，符合要求" >> ${scanner_log}
  else
    echo "[N] 已经设置root能远程登陆，不符合要求，建议/etc/ssh/sshd_config添加PermitRootLogin no参数" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`ping服务检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[9] 系统ping服务检查中..." /bin/true
  pingd=`cat /proc/sys/net/ipv4/icmp_echo_ignore_all`
  if [ "$pingd" = "1" ]; then
    echo "[Y] 服务器已禁ping" >> ${scanner_log}
  else
    echo "[N] 服务器未禁ping" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`telnet服务检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[10] 系统telnet服务检查中..." /bin/true
  telnetd=`rpm -qa|grep telnet | wc -l`
  if [ $telnetd = "0" ]; then
    echo "[Y] 系统未安装telnet服务 " >> ${scanner_log}
  else
  echo "[N] 检测到安装了telnet服务，不符合要求，建议禁用telnet服务" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`远程连接的安全性配置检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[11] 远程连接的安全性配置检查中..." /bin/true
  fileNetrc=`find / -xdev -mount -name .netrc -print 2> /dev/null`
  if [  -z "${fileNetrc}" ];then
    echo "[Y] 不存在.netrc文件，符合要求" >> ${scanner_log}
  else
    echo "[N] 存在.netrc文件，不符合要求" >> ${scanner_log}
  fi
  fileRhosts=`find / -xdev -mount -name .rhosts -print 2> /dev/null`
  if [ -z "$fileRhosts" ];then
    echo "[Y] 不存在.rhosts文件，符合要求" >> ${scanner_log}
  else
    echo "[N] 存在.rhosts文件，不符合要求" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`异常隐含文件检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[12] 异常隐含文件检查中..." /bin/true
  hideFile=$(find / -xdev -mount \( -name "..*" -o -name "...*" \) 2> /dev/null)
  if [  -z "${hideFile}" ];then
    echo "[Y] 不存在隐藏文件，符合要求" >> ${scanner_log}
  else
    echo "[N] 存在隐藏文件，建议仔细检查：" >> ${scanner_log}
  for i in ${hideFile}
  do
   echo $i >> ${scanner_log}
  done
  fi  
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`syslog登录事件检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[13] syslog登录事件检查中..." /bin/true
  if [  -f "/etc/syslog.conf" ];then
    logFile=$(cat /etc/syslog.conf | grep -V ^# | grep authpriv.*)
    if [ ! -z "${logFile}" ];then
      echo "[Y] 存在保存authpirv的日志文件" >> ${scanner_log}
    else
      echo "[N] 不存在保存authpirv的日志文件" >> ${scanner_log}
    fi
  else
    echo "[N] 不存在／etc/syslog.conf文件，建议对所有登录事件都记录" >> ${scanner_log}
  fi  
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`日志审核功能检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[14] 日志审核功能检查中..." /bin/true
  auditdStatus=$(service auditd status 2> /dev/null)
  if [ $? = 0 ];then
    echo "[Y] 系统日志审核功能已开启，符合要求" >> ${scanner_log}
  fi
  if [ $? = 3 ];then
    echo "[N] 系统日志审核功能已关闭，不符合要求，建议service auditd start开启" >> ${scanner_log}
  fi
  echo "" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  echo "`hostname -s`系统core dump状态检查结果" >> ${scanner_log}
  echo "****************************************************" >> ${scanner_log}
  action "[15] 系统core dump状态检查中..." /bin/true
  limitsFile=$(cat /etc/security/limits.conf | grep -V ^# | grep core)
  if [ $? -eq 0 ];then
    soft=`cat /etc/security/limits.conf | grep -V ^# | grep core | awk {print $2}`
    for i in $soft
    do
      if [ "$i"x = "soft"x ];then
        echo "[Y] * soft core 0 已经设置" >> ${scanner_log}
      fi
      if [ "$i"x = "hard"x ];then
        echo "[Y] * hard core 0 已经设置" >> ${scanner_log}
      fi
    done
  else 
    echo "[N] 没有设置core，建议在/etc/security/limits.conf中添加* soft core 0和* hard core 0" >> ${scanner_log}
  fi
  echo ""
  cat  ${scanner_log}
  echo ""
  echo ""
  echo -e "\033[36m输出结果"$scanner_log" \033[0m"
  echo ""
}
bk_safe