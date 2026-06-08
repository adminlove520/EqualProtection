# Oracle 数据库等保测评查询脚本

## 文件说明
- `等保测评_Oracle查询.sql` — Oracle 数据库等保测评一键查询脚本

## 适用版本
Oracle 11g / 12c / 19c / 21c

## 使用方法
1. 通过 SQL*Plus、Navicat、PL/SQL Developer 连接数据库
2. 需要以 DBA 权限（如 sysdba）登录
3. 复制 SQL 语句逐条执行
4. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 用户标识唯一 | `SELECT username, user_id FROM dba_users` |
| 2 | 身份鉴别 - 口令复杂度 | `SELECT * FROM dba_profiles WHERE resource_name='PASSWORD_VERIFY_FUNCTION'` |
| 3 | 身份鉴别 - 口令有效期 | `SELECT * FROM DBA_PROFILES WHERE resource_name='PASSWORD_LIFE_TIME'` |
| 4 | 身份鉴别 - 登录失败处理 | `SELECT * FROM DBA_PROFILES WHERE resource_name='FAILED_LOGIN_ATTEMPTS'` |
| 5 | 身份鉴别 - 超时自动退出 | `SELECT * FROM DBA_PROFILES WHERE resource_name='IDLE_TIME'` |
| 6 | 安全审计 - 审计功能 | `SHOW PARAMETER audit_trail` |
| 7 | 安全审计 - 审计记录 | `SELECT * FROM aud$` |
| 8 | 身份鉴别 - 默认账户 | `SELECT username FROM dba_users WHERE account_status='OPEN'` |

## 来源文件
`Evaluation/Oracle数据库抓包命令 V2.0.docx`
