#!/bin/bash
# 该脚本适用于银河麒麟服务器操作系统 V10 SP2

# 确认是使用root用户执行脚本
#USER=$( env | grep '\<USER\>' | cut -d '=' -f 2 )
USER=$(whoami)
if [ "$USER" != 'root' ];then
    echo "Must Use Root User Run Script!!!"
    exit 0
fi
echo "已对密码进行加固，如果输入错误密码超过3次，则锁定账户！！"
echo "备份文件!"
cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
n=`cat /etc/pam.d/sshd | grep "auth required pam_tally2.so "|wc -l`
if [ $n -eq 0 ];then
sed -i '/%PAM-1.0/a\auth required pam_tally2.so deny=3 unlock_time=60 even_deny_root root_unlock_time=60' /etc/pam.d/sshd
fi
echo "输入密码必须包含数字，大小写字母"
echo "备份文件!"
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.bak
sed -e "14 i\password    requisite     pam_cracklib.so minlen=10 difok=3 lcredit=-1 ucredit=-1 dcredit=-1 try_first_pass retry=3" -i /etc/pam.d/system-auth
sed -e '15d'  -i /etc/pam.d/system-auth
# echo "不允许root进行ssh"
# echo "备份文件!"
# cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
# sed -i  "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
# service sshd restart
echo "备份文件!"
cp /etc/shadow  /etc/shadow.bak
cp /etc/passwd  /etc/passwd.bak
echo "锁定用户"
for i in adm  lp sync nobody halt news uucp operator games gopher ftp 123
do
passwd -l $i
done
echo "备份文件!"
echo "设置用户登录超时"
cp /etc/profile /etc/profile.bak
echo "export TMOUT=300 readonly TMOUT  " >> /etc/profile
echo "备份文件!" 
cp /etc/login.defs   /etc/login.defs.bak
read -p  "设置密码失效前多少天通知用户：" a
sed -i '/^PASS_WARN_AGE/c\PASS_WARN_AGE    '$a'' /etc/login.defs
read -p  "设置密码修改之间最小的天数：" b
sed -i '/^PASS_MIN_DAYS/c\PASS_MIN_DAYS   '$b'' /etc/login.defs
read -p  "设置密码最多可多少天不修改：" c
sed -i '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS   '$c'' /etc/login.defs
read -p  "设置密码最短的长度：" d
sed -i '/^PASS_MIN_LEN/c\PASS_MIN_LEN     '$d'' /etc/login.defs
echo "备份文件!"
echo "设置用户权限配置文件的权限"
cp /etc/passwd /etc/passwd.bak
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
chmod 0644 /etc/group
chmod 0644 /etc/passwd
chmod 0400 /etc/shadow
chmod 0400 /etc/gshadow
echo "确保三权分立账户存在"
useradd audit
usermod -G audit audit
useradd op 
usermod -G op op
useradd security 
usermod -G security security
echo "备份文件!"
echo "确保root是唯一超级帐户"
check_root_uniqueness(){
cat /etc/passwd | awk -F: '($3 == 0) { print $1 }'|grep -v '^root$'
}    
echo "确保root是唯一超级帐户"
check_root_uniqueness(){
cat /etc/passwd | awk -F: '($3 == 0) { print $1 }'|grep -v '^root$'
}    
echo "SSHD强制使用V2安全协议"
echo "Protocol 2" >> /etc/ssh/sshd_config
sed -i 's/#LogLevel INFO/LogLevel INFO/' /etc/ssh/sshd_config
echo "禁止SSH空密码用户登录"
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
yum -y install audit
systemctl start auditd

echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope" >> /etc/audit/rules.d/audit.rules

echo "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope" >> /etc/audit/audit.rules
service auditd restart
systemctl status auditd 
echo "启用安全审计功能!!"
