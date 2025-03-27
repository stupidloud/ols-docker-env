-- 安装 MeCab 全文解析插件
-- 如果插件已存在 (例如通过 Dockerfile COPY)，此命令会安全地跳过或更新
INSTALL PLUGIN mecab SONAME 'libpluginmecab.so';

-- 验证插件是否安装成功 (可选，日志中会显示)
-- SHOW PLUGINS LIKE 'mecab';