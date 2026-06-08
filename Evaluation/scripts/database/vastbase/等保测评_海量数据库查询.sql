-- ============================================================================
-- 等保测评_海量数据库查询.sql
-- 用途：等保测评数据库安全检查查询脚本（海量数据库（Vastbase）专用）
-- 适用数据库类型：海量数据库（Vastbase）
-- 对应等保测评项概览：
--   - 身份鉴别（口令复杂度、登录失败处理、超时自动退出）
--   - 安全审计（审计策略与配置）
--   - 访问控制（三权分立/职责分离）
--   - 综合安全配置检查
-- 使用方法：
--   1. 使用 海量数据库（Vastbase） 客户端工具（如命令行、管理工具等）连接到目标数据库
--   2. 根据测评需要，逐条或批量执行本文件中的SQL命令
--   3. 每条命令前有中文注释说明用途和对应等保测评项，请结合实际环境判断结果
--   4. 部分命令可能需要管理员权限（DBA/SA/SYSDBA等）才能正常执行
-- 注意事项：
--   - 请在测试环境验证后再在生产环境执行
--   - 审计相关查询可能涉及敏感数据，请注意数据保护
-- ============================================================================

-- ############################################################################
--                          六、海量数据库
-- ############################################################################

-- ============================================================================
-- 6.1 密码复杂度策略
-- 对应测评项：身份鉴别 - 口令复杂度
-- 说明：检查密码策略各项参数配置
-- ============================================================================
show password_policy;
show password_min_length;
show password_max_length;
show password_encryption_type;
show password_reuse_time;
show password_reuse_max;
show password_effect_time;
show password_notify_time;
show password_min_uppercase;
show password_min_lowercase;
show password_min_digital;
show password_min_special;
show enable_stat_mask_password;

-- ============================================================================
-- 6.2 登录失败处理策略
-- 对应测评项：身份鉴别 - 登录失败处理
-- 说明：检查登录失败次数限制和锁定时间
-- ============================================================================
show failed_login_attempts;
show password_lock_time;

-- ============================================================================
-- 6.3 会话超时
-- 对应测评项：身份鉴别 - 超时自动退出
-- 说明：检查会话超时自动退出设置
-- ============================================================================
show session_timeout;

-- ============================================================================
-- 6.4 审计策略
-- 对应测评项：安全审计 - 审计功能与配置
-- 说明：检查审计功能各项参数配置
-- ============================================================================
show audit_enabled;
show audit_directory;
show audit_backup_directory;
show audit_data_format;
show audit_rotation_interval;
show audit_rotation_size;
show audit_resource_policy;
show audit_stop_policy;
show audit_file_remain_time;
show audit_space_limit;
show audit_file_remain_threshold;
show audit_thread_num;
show audit_operation_result;

-- ============================================================================
-- 6.5 三权分立
-- 对应测评项：访问控制 - 职责分离
-- 说明：检查是否启用三权分立（系统管理员、安全管理员、审计管理员分离）
-- ============================================================================
show enable_Separation_Of_Duty;

-- ============================================================================
-- 6.6 所有安全参数汇总查询
-- 对应测评项：综合安全配置检查
-- 说明：一次性查询所有安全相关参数，便于汇总评估
-- ============================================================================
select name as 参数名称,setting as 参数值 from pg_settings where name in ('password_policy','password_min_length','password_max_length','password_encryption_type','password_reuse_time','password_reuse_max','failed_login_attempts','password_lock_time','password_effect_time','password_notify_time','password_min_uppercase','password_min_lowercase','password_min_digital','password_min_special','enable_stat_mask_password','session_timeout','audit_enabled','audit_directory','audit_backup_directory','audit_data_format','audit_rotation_interval','audit_rotation_size','audit_resource_policy','audit_stop_policy','audit_file_remain_time','audit_space_limit','audit_file_remain_threshold','audit_thread_num','audit_operation_result','enable_Separation_Of_Duty') order by name;

-- ============================================================================
-- 脚本结束
-- ============================================================================