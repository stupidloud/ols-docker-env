# 使用官方 MySQL 8.0 Debian 镜像作为基础
FROM mysql:8.0-debian

# 设置环境变量，避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 一次性安装所有编译依赖、MeCab、证书工具，并清理
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # 构建 MySQL 插件所需
        g++ \
        make \
        git \
        cmake \
        libssl-dev \
        libncurses-dev \
        libtirpc-dev \
        pkg-config \
        bison \
        # MeCab 依赖
        mecab \
        libmecab-dev \
        mecab-ipadic-utf8 \
        # CA 证书
        ca-certificates \
    && \
    # 更新 CA 证书
    update-ca-certificates && \
    # 清理 APT 缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 获取 MySQL 源码 (选择与 8.0 版本匹配的分支)
# 将源码放在临时目录，方便后续清理
WORKDIR /usr/src
RUN git clone --depth 1 --branch 8.0 https://github.com/mysql/mysql-server.git mysql-server

# 创建构建目录并配置 CMake
WORKDIR /usr/src/mysql-server
RUN mkdir build && cd build && \
    cmake .. \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST=/usr/src/boost \
        -DWITH_MECAB=system

# 编译 MeCab 插件
# 使用 WORKDIR /usr/src/mysql-server/build 确保在构建目录执行
WORKDIR /usr/src/mysql-server/build
RUN make -j$(nproc) mecab_parser

# 将编译后的插件复制到 MySQL 插件目录，并清理源码和构建依赖
# 假设 Debian 的插件目录是 /usr/lib/mysql/plugin/
RUN cp plugin_output_directory/libpluginmecab.so /usr/lib/mysql/plugin/ && \
    # 清理源码和 Boost
    rm -rf /usr/src/mysql-server /usr/src/boost && \
    # 清理编译时依赖以减小镜像体积
    apt-get purge -y --auto-remove \
        g++ \
        make \
        git \
        cmake \
        libssl-dev \
        libncurses-dev \
        libtirpc-dev \
        pkg-config \
        bison \
        libmecab-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 添加初始化脚本以确保插件安装
COPY install-mecab.sql /docker-entrypoint-initdb.d/

# 切换回默认工作目录
WORKDIR /

# 恢复交互式环境设置 (虽然基础镜像可能已处理，显式设置无害)
ENV DEBIAN_FRONTEND=dialog

# 基础镜像的 CMD 会启动 mysqld
