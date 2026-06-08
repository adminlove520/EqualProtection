# SQL Server 数据库等保测评查询脚本

## 文件说明
- `等保测评_SQLServer查询.sql` — SQL Server 数据库等保测评一键查询脚本

## 适用版本
SQL Server 2016+ / 2019 / 2022

## 使用方法
1. 通过 SQL Server Management Studio (SSMS) 连接数据库
2. 需要以 sysadmin 或 sa 账户登录
3. 新建查询窗口，复制 SQL 语句逐条执行
4. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 版本信息 | `SELECT @@VERSION` |
| 2 | 身份鉴别 - 用户标识唯一 | `SELECT * FROM syslogins` |
| 3 | 身份鉴别 - 用户权限 | `sp_helplogins` |
| 4 | 身份鉴别 - 身份认证模式 | `SELECT * FROM sys.sql_logins` |
| 5 | 安全审计 - C2审计配置 | `sp_configure` |
| 6 | 通信完整性 - 连接加密 | `SELECT encrypt_option FROM sys.dm_exec_connections` |

## 来源文件
`Evaluation/SQL Server抓包命令.docx`
