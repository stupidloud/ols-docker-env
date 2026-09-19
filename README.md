# OpenLiteSpeed + MySQL WordPress Docker 环境

基于 [litespeedtech/ols-docker-env](https://github.com/litespeedtech/ols-docker-env) 的 fork，用 **MySQL（带 MeCab 全文分词）** 替换官方的 MariaDB，并预置了 APCu、PHP / MySQL 调优配置。`mysql` 分支会定期合并上游更新。

## 与官方主线的区别

| 项目 | 官方主线 | 本分支（`mysql`） |
| :--- | :--- | :--- |
| 数据库 | `mariadb:11.8` | [`kl3x/mysql-mecab`](https://hub.docker.com/r/kl3x/mysql-mecab)（MySQL + MeCab 全文分词插件） |
| 数据库配置 | 镜像默认 | 挂载 `custom/my.cnf`（InnoDB 缓冲池、全文索引最小词元等调优） |
| 数据库端口 | 不对外暴露 | 绑定到宿主机 `127.0.0.1:3306`，方便本机工具直连 |
| Web 镜像 | 直接拉取官方镜像 | 通过 `custom/Dockerfile` 在官方镜像基础上安装 `lsphpXX-apcu` |
| PHP 配置 | 镜像默认 | 挂载 `custom/php.ini`（`memory_limit` / `apc.shm_size` = 256M） |
| `bin/database.sh` | 使用 `mariadb` 客户端 | 使用 `mysql` 客户端；`CREATE USER` 与 `GRANT` 分开写（MySQL 8 不支持 `GRANT ... IDENTIFIED BY`） |
| phpMyAdmin | `restart: always` | `restart: unless-stopped`，关闭容器日志 |
| 时区 | `America/New_York` | `UTC` |
| CI | 监听 `master` 分支 | 监听 `mysql` 分支，支持手动触发 |

## 前置条件

1. [安装 Docker](https://www.docker.com/)
2. [安装 Docker Compose](https://docs.docker.com/compose/)（v2，命令为 `docker compose`）

## 配置

编辑 `.env`：

| 变量 | 说明 |
| :--- | :--- |
| `TimeZone` | 容器时区，默认 `UTC` |
| `OLS_VERSION` | OpenLiteSpeed 版本，可在 [Docker Hub Tags](https://hub.docker.com/r/litespeedtech/openlitespeed/tags) 查看 |
| `PHP_VERSION` | lsphp 包名，如 `lsphp85` |
| `PHP_TAG` | PHP 点分版本号，如 `8.5`。**必须与 `PHP_VERSION` 对应**，用于定位容器内 `php.ini` 挂载路径 `/usr/local/lsws/${PHP_VERSION}/etc/php/${PHP_TAG}/mods-available/` |
| `PHPMYADMIN_VERSION` | phpMyAdmin 镜像版本 |
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码 |
| `MYSQL_DATABASE` / `MYSQL_USER` / `MYSQL_PASSWORD` | 初始化时创建的默认库和用户 |
| `DOMAIN` | 演示站点域名，默认 `localhost` |

修改 `custom/my.cnf` 前请留意 `innodb_buffer_pool_size`（默认 16G）和 `innodb_log_file_size`（默认 4G），按服务器内存调整。

## 安装

```bash
git clone -b mysql https://github.com/stupidloud/ols-docker-env.git
cd ols-docker-env
docker compose up -d --build
```

首次启动需要 `--build` 以构建带 APCu 的 Web 镜像；之后修改 `custom/Dockerfile` 或升级 `OLS_VERSION` / `PHP_VERSION` 时也需重新 `--build`。

## 组件

| 组件 | 版本 |
| :---: | :---: |
| Linux | Ubuntu 26.04 |
| OpenLiteSpeed | [最新版](https://hub.docker.com/r/litespeedtech/openlitespeed) |
| MySQL | [kl3x/mysql-mecab](https://hub.docker.com/r/kl3x/mysql-mecab) |
| PHP | [最新版](http://rpms.litespeedtech.com/debian/) + APCu |
| LiteSpeed Cache | [WordPress.org 最新版](https://wordpress.org/plugins/litespeed-cache/) |
| ACME | [acme.sh 官方最新版](https://github.com/acmesh-official/get.acme.sh) |
| WordPress | [官方最新版](https://wordpress.org/download/) |
| phpMyAdmin | [Docker Hub](https://hub.docker.com/r/phpmyadmin/phpmyadmin/) |
| Redis | [Docker Hub](https://hub.docker.com/_/redis/) |

## 目录结构

```
├── acme                # Let's Encrypt 证书
├── bin                 # 宿主机侧管理脚本
│   └── container       # 挂载到容器内 /usr/local/bin 的脚本
├── custom
│   ├── Dockerfile      # 在官方镜像上安装 APCu
│   ├── my.cnf          # MySQL 调优配置
│   └── php.ini         # 追加的 PHP 配置（99-php.ini）
├── data
│   └── db              # MySQL 数据目录
├── logs                # Web 服务器及各虚拟主机日志
├── lsws
│   ├── admin-conf      # WebAdmin 配置
│   └── conf            # OpenLiteSpeed 主配置
├── redis               # Redis 数据与 redis.conf
├── sites               # 站点根目录（WordPress 装在这里）
├── .env
└── docker-compose.yml
```

## 使用

### 启动 / 停止 / 删除容器

```bash
docker compose up -d        # 后台启动
docker compose stop         # 停止
docker compose down         # 停止并删除容器（数据卷保留在 ./data、./sites 等目录）
```

### 设置 WebAdmin 密码

强烈建议启动后立即设置：

```bash
bash bin/webadmin.sh my_password
```

WebAdmin 控制台地址：`https://<服务器IP>:7080`。

### 启动演示站点

执行后可通过 `.env` 中的 `DOMAIN`（默认 <http://localhost>）访问 WordPress 安装向导：

```bash
bash bin/demosite.sh
```

### 添加 / 删除域名与虚拟主机

```bash
bash bin/domain.sh [-A, --add] example.com
bash bin/domain.sh [-D, --del] example.com
```

> 未申请证书前访问会出现 SSL 警告，忽略即可。

### 创建数据库

自动生成用户名、密码和库名：

```bash
bash bin/database.sh [-D, --domain] example.com
```

或自行指定：

```bash
bash bin/database.sh [-D, --domain] example.com [-U, --user] USER_NAME [-P, --password] MY_PASS [-DB, --database] DATABASE_NAME
```

用户名、库名只允许 `[A-Za-z0-9_]`，最长 63 字符；密码至少 8 位且不能包含 `' " \ $ \``。

### 安装 WordPress

先为域名执行上面的 `database.sh`（会预写 `wp-config.php`），再安装：

```bash
bash bin/appinstall.sh [-A, --app] wordpress [-D, --domain] example.com
```

### 连接 Redis 对象缓存

WordPress 后台 → LiteSpeed Cache → Cache → [Object](https://docs.litespeedtech.com/lscache/lscwp/cache/#object-tab)，方法选 **Redis**，Host 填 `redis`。

### 直连 MySQL

MySQL 已绑定到宿主机 `127.0.0.1:3306`，可用本机客户端直接连接：

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -p
```

### 使用 MeCab 全文分词

`kl3x/mysql-mecab` 镜像已内置 MeCab 解析器插件，`custom/my.cnf` 中 `innodb_ft_min_token_size = 1` 允许索引单字词元。建表时指定解析器即可：

```sql
CREATE FULLTEXT INDEX ft_content ON wp_posts (post_content) WITH PARSER mecab;
```

### 安装 ACME（仅首次）

```bash
bash bin/acme.sh [-I, --install] [-E, --email] EMAIL_ADDR
```

### 申请 Let's Encrypt 证书

传入根域名，脚本会同时为带 `www` 和不带 `www` 的域名申请：

```bash
bash bin/acme.sh [-D, --domain] example.com
```

其他参数：

* `-r, --renew`：配合 `-D` 续签指定域名，加 `-f` 强制续签
* `-R, --renew-all`：续签全部域名，加 `-f` 强制续签
* `-f, -F, --force`：强制续签
* `-v, --revoke`：吊销证书
* `-V, --remove`：移除域名证书

### 本地开发用 mkcert 证书

针对 `.test`、`.local`、`.dev` 等本地域名，可用 `mkcert` 生成受信任证书，避免浏览器警告。

首次安装（Windows + Chocolatey）：

```bash
bash bin/mkcert.sh --install
```

先用 `domain.sh --add` 添加域名，再生成证书：

```bash
bash bin/mkcert.sh [-D, --domain] example.test
```

脚本会为 `example.test` 和 `www.example.test` 生成证书、创建带 SSL 的 `dockerLocal` 模板、把域名迁移到该模板并重启 OpenLiteSpeed。移除证书并还原为 HTTP：

```bash
bash bin/mkcert.sh [-R, --remove] [-D, --domain] example.test
```

### 升级 Web 服务器

```bash
bash bin/webadmin.sh [-U, --upgrade]
```

### 启用 / 关闭 OWASP ModSecurity

```bash
bash bin/webadmin.sh [-M, --mod-secure] enable
bash bin/webadmin.sh [-M, --mod-secure] disable
```

> 部分规则服务器不支持会有警告，忽略即可。

### 其他 webadmin.sh 参数

* `-R, --restart`：平滑重启 OpenLiteSpeed
* `-S, --serial [序列号|TRIAL]`：应用 LiteSpeed 序列号

### phpMyAdmin

出于安全考虑，phpMyAdmin 端口默认未暴露。需要时在 `docker-compose.yml` 中取消注释：

```yaml
  phpmyadmin:
    ports:
      - 8080:80
```

然后 `docker compose up -d` 重新创建，访问 `http://127.0.0.1:8080`，用户名 `root`，密码为 `.env` 中的 `MYSQL_ROOT_PASSWORD`。

## 自定义

### 追加 PHP 扩展

编辑 `custom/Dockerfile`，在 `apt-get install` 行追加包名（如 `${PHP_VERSION}-pspell`），然后：

```bash
docker compose up -d --build
```

### 修改 PHP 配置

编辑 `custom/php.ini`，它会以 `99-php.ini` 挂载到容器内的 `mods-available` 目录，优先级高于默认配置。修改后重启 Web 服务器：

```bash
bash bin/webadmin.sh -R
```

### 修改 MySQL 配置

编辑 `custom/my.cnf` 后重启数据库容器：

```bash
docker compose restart mysql
```

> 注意：`innodb_buffer_pool_size` 超过物理内存会导致容器启动失败。

## 同步上游

```bash
git remote add upstream https://github.com/litespeedtech/ols-docker-env.git
git fetch upstream
git merge upstream/master
```

合并时冲突通常集中在 `docker-compose.yml`（镜像名）、`bin/database.sh`（`mariadb` → `mysql` 客户端及 `db_setup`）和 `.env`（时区 / 版本号）。解决时保留本分支的 MySQL 相关改动，接受上游的版本升级，并同步更新 `PHP_TAG`。

## 支持

* 上游项目问题：[litespeedtech/ols-docker-env Issues](https://github.com/litespeedtech/ols-docker-env/issues)
* [OpenLiteSpeed 论坛](https://forum.openlitespeed.org/)
* [GoLiteSpeed Slack](https://litespeedtech.com/slack)
