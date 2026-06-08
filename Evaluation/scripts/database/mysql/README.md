# MySQL 数据库等保测评查询脚本

## 文件说明
- `等保测评_Mysql查询.sql` — MySQL 数据库等保测评一键查询脚本

## 适用版本
MySQL 5.7+ / 8.0+

## 使用方法
1. 通过 Navicat、MySQL Workbench 或命令行连接数据库
2. 复制 SQL 语句逐条执行（或全选执行）
3. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 用户标识唯一 | `SELECT user, host FROM mysql.user` |
| 2 | 身份鉴别 - 口令复杂度 | `SHOW VARIABLES LIKE 'validate%'` |
| 3 | 身份鉴别 - 口令有效期 | `SHOW VARIABLES LIKE 'default_password_lifetime'` |
| 4 | 身份鉴别 - 登录失败处理 | `SHOW VARIABLES LIKE '%connection_control%'` |
| 5 | 身份鉴别 - 超时自动退出 | `SHOW VARIABLES LIKE '%timeout%'` |
| 6 | 身份鉴别 - 传输加密 | `SHOW VARIABLES LIKE '%have_ssl%'` |
| 7 | 访问控制 - 权限分配 | `SHOW GRANTS FOR 'root'@'localhost'` |
| 8 | 访问控制 - 权限管理 | `SELECT * FROM mysql.user/db/tables_priv` |
| 9 | 安全审计 - 审计记录 | `SHOW GLOBAL VARIABLES LIKE '%general%'` |
| 10 | 入侵防范 - 插件检查 | `SHOW PLUGINS` |

## 来源文件
`Evaluation/MySQL数据库抓包命令.docx`
