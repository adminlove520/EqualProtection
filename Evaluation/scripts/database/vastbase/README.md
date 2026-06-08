# 海量数据库等保测评查询脚本

## 文件说明
- `等保测评_海量数据库查询.sql` — 海量数据库（Vastbase）等保测评一键查询脚本

## 适用版本
海量数据库 Vastbase G100 / Vastbase G100V2

## 使用方法
1. 通过 vsql 命令行或 Navicat 连接数据库
2. 需要以管理员权限登录（如 postgres 超级用户）
3. 复制 SQL 语句逐条执行
4. 截图保存查询结果作为等保测评证据

## 覆盖测评项

| 序号 | 测评项 | 主要命令 |
|------|--------|----------|
| 1 | 身份鉴别 - 密码复杂度 | `SHOW password_policy` |
| 2 | 身份鉴别 - 密码长度 | `SHOW password_min_length` / `SHOW password_max_length` |
| 3 | 身份鉴别 - 密码字符要求 | `SHOW password_min_uppercase/lowercase/digital/special` |
| 4 | 身份鉴别 - 密码有效期 | `SHOW password_effect_time` |
| 5 | 身份鉴别 - 登录失败锁定 | `SHOW failed_login_attempts` / `SHOW password_lock_time` |
| 6 | 身份鉴别 - 超时自动退出 | `SHOW session_timeout` |
| 7 | 安全审计 - 审计策略 | `SHOW audit_enabled` / `SHOW audit_directory` |
| 8 | 安全审计 - 审计配置 | `SHOW audit_rotation_interval/size` |
| 9 | 安全审计 - 审计资源策略 | `SHOW audit_resource_policy` / `SHOW audit_space_limit` |
| 10 | 身份鉴别 - 三权分立 | `SHOW enable_Separation_Of_Duty` |
| 11 | 汇总查询 | `SELECT name, setting FROM pg_settings WHERE name IN (...)` |

## 来源文件
`Evaluation/等保-海量数据库.sql`
