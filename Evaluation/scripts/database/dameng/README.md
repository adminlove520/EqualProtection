# 达梦数据库等保测评查询脚本

## 文件说明
- `等保测评_达梦查询.sql` — 达梦数据库（DM）等保测评一键查询脚本

## 适用版本
达梦数据库 DM7 / DM8

## 使用方法
1. 通过达梦管理工具（DM Manager）或 disql 命令行连接数据库
2. 需要以 DBA 权限登录（如 SYSDBA）
3. 复制 SQL 语句逐条执行
4. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 版本信息 | `SELECT * FROM V$version` |
| 2 | 身份鉴别 - 用户标识唯一 | `SELECT USERNAME FROM DBA_USERS` |
| 3 | 身份鉴别 - 口令策略 | `SELECT * FROM V$PARAMETER WHERE NAME='PWD_POLICY'` |
| 4 | 身份鉴别 - 登录失败锁定 | `SELECT ... FROM sysusers a RIGHT JOIN all_users b` |
| 5 | 身份鉴别 - 超时自动退出 | `SELECT * FROM DBA_PROFILES WHERE RESOURCE_NAME IN ('CONNECT_TIME', 'CONNECT_IDLE_TIME')` |
| 6 | 访问控制 - 系统权限 | `SELECT * FROM DBA_SYS_PRIVS` |
| 7 | 安全审计 - 审计开关 | `SELECT * FROM V$DM_INI WHERE PARA_NAME='ENABLE_AUDIT'` |
| 8 | 安全审计 - 审计记录 | `SELECT * FROM V$AUDITRECORDS` |
| 9 | 通信完整性 - SSL加密 | `SELECT * FROM V$PARAMETER WHERE NAME='ENABLE_ENCRYPT'` |

## 来源文件
`Evaluation/达梦数据库抓包命令.txt`
