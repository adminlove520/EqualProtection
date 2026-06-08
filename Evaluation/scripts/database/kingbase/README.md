# 人大金仓数据库等保测评查询脚本

## 文件说明
- `等保测评_人大金仓查询.sql` — 人大金仓数据库（KingbaseES）等保测评一键查询脚本

## 适用版本
人大金仓 KingbaseES V8 / V8R6

## 使用方法
1. 通过 ksql 命令行或 Navicat 连接数据库
2. 需要以 SYSTEM 或具有 DBA 权限的账户登录
3. 复制 SQL 语句逐条执行
4. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 版本信息 | `SELECT version()` |
| 2 | 访问控制 - 用户权限 | `SELECT * FROM sys_user` |
| 3 | 访问控制 - 角色权限 | `SELECT * FROM sys_roles` |
| 4 | 访问控制 - 对象权限 | `SELECT * FROM information_schema.table_privileges` |
| 5 | 访问控制 - 自主访问控制 | `SELECT * FROM sys_default_acl` |
| 6 | 访问控制 - 完整性约束 | `SELECT * FROM information_schema.table_constraints` |
| 7 | 访问控制 - 外键约束 | `SELECT * FROM information_schema.referential_constraints` |
| 8 | 通信完整性 - SSL配置 | `SHOW ssl` / `SHOW ssl_ciphers` |
| 9 | 身份鉴别 - 连接数限制 | `SHOW max_connections` |
| 10 | 身份鉴别 - 超时设置 | `SHOW idle_in_transaction_session_timeout` |

## 来源文件
`Evaluation/人大金仓数据库查询命令.txt`
