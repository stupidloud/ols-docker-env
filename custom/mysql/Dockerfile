# 使用官方 MySQL 8.0 Debian 镜像作为基础
FROM mysql:8.0-debian AS builder

# 设置环境变量，避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装编译依赖和 MeCab，以及运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ make git cmake libssl-dev libncurses-dev libtirpc-dev pkg-config bison mecab libmecab-dev mecab-ipadic-utf8 ca-certificates && \
    update-ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 获取 MySQL 源码
WORKDIR /usr/src
RUN git clone --depth 1 --branch 8.0 https://github.com/mysql/mysql-server.git mysql-server

# 创建构建目录并配置 CMake，移除调试信息
WORKDIR /usr/src/mysql-server
RUN mkdir build && cd build && \
    cmake .. -D CMAKE_BUILD_TYPE=Release -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/src/boost -DWITH_MECAB=system

# 编译 MeCab 插件
WORKDIR /usr/src/mysql-server/build
RUN make -j$(nproc) mecab_parser
# 最终镜像
FROM mysql:8.0-debian

# 复制 MeCab 插件
COPY --from=builder /usr/src/mysql-server/build/plugin_output_directory/libpluginmecab.so /usr/lib/mysql/plugin/

# 添加初始化脚本
COPY install-mecab.sql /docker-entrypoint-initdb.d/

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends mecab libmecab-dev mecab-ipadic-utf8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 恢复交互式环境设置
ENV DEBIAN_FRONTEND=dialog

# 基础镜像的 CMD 会启动 mysqld
