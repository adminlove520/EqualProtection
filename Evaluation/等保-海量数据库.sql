-- =============================================
-- 一、密码策略查询
-- =============================================
-- 密码复杂度策略
show password_policy;
-- 密码最小长度
show password_min_length;
-- 密码最大长度
show password_max_length;
-- 密码加密类型
show password_encryption_type;
-- 密码重复使用时间限制
show password_reuse_time;
-- 密码重复使用次数限制
show password_reuse_max;
-- 密码错误最大尝试次数
show failed_login_attempts;
-- 密码错误锁定时间
show password_lock_time;
-- 密码有效期
show password_effect_time;
-- 密码到期提醒时间
show password_notify_time;
-- 密码至少包含大写字母数
show password_min_uppercase;
-- 密码至少包含小写字母数
show password_min_lowercase;
-- 密码至少包含数字数
show password_min_digital;
-- 密码至少包含特殊字符数
show password_min_special;
-- 密码脱敏开关
show enable_stat_mask_password;

-- =============================================
-- 二、登录与会话安全查询
-- =============================================
-- 会话超时自动退出时间（秒）
show session_timeout;

-- =============================================
-- 三、审计策略查询
-- =============================================
-- 审计总开关
show audit_enabled;
-- 审计文件存储目录
show audit_directory;
-- 审计备份目录
show audit_backup_directory;
-- 审计日志格式
show audit_data_format;
-- 审计文件切换时间间隔
show audit_rotation_interval;
-- 审计文件切换大小
show audit_rotation_size;
-- 审计资源策略
show audit_resource_policy;
-- 审计停止策略
show audit_stop_policy;
-- 审计文件保留时间
show audit_file_remain_time;
-- 审计空间限制
show audit_space_limit;
-- 审计文件保留阈值
show audit_file_remain_threshold;
-- 审计线程数
show audit_thread_num;
-- 审计操作结果记录
show audit_operation_result;

-- =============================================
-- 四、三权分立查询
-- =============================================
-- 三权分立开关状态
show enable_Separation_Of_Duty;

-- =============================================
-- 五、所有安全参数汇总查询（一条命令查看全部）
-- =============================================
select name as 参数名称,setting as 参数值 
from pg_settings 
where name in (
'password_policy','password_min_length','password_max_length','password_encryption_type',
'password_reuse_time','password_reuse_max','failed_login_attempts','password_lock_time',
'password_effect_time','password_notify_time','password_min_uppercase','password_min_lowercase',
'password_min_digital','password_min_special','enable_stat_mask_password','session_timeout',
'audit_enabled','audit_directory','audit_backup_directory','audit_data_format',
'audit_rotation_interval','audit_rotation_size','audit_resource_policy','audit_stop_policy',
'audit_file_remain_time','audit_space_limit','audit_file_remain_threshold','audit_thread_num',
'audit_operation_result','enable_Separation_Of_Duty'
) order by name;