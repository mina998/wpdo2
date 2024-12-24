#!/bin/bash
# 获取当前脚本的软链接路径
SYMLINK_PATH=$(readlink -f "$0")
# 当前目录
SOROY_DIR=$(dirname "$SYMLINK_PATH")
MYSQL_CONF=$(realpath "$SOROY_DIR/../services/mysql/mysql.cnf")
echo "MySQL配置文件: $MYSQL_CONF"

# 获取系统信息
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')  # 总内存(MB)
CPU_CORES=$(nproc)  # CPU核心数
# 计算配置参数
max_connections=$(echo "${TOTAL_MEM}/1024*55" | bc | cut -d. -f1)
max_allowed_packet=$(echo "${TOTAL_MEM} * 0.7" | bc | cut -d. -f1)M
table_definition_cache=$(echo "${TOTAL_MEM} * 0.2 * 0.9" | bc | cut -d. -f1)

myisam_sort_buffer_size=$(echo "${TOTAL_MEM}/1024*7" | bc | cut -d. -f1)M
myisam_max_sort_file_size=$(echo "${TOTAL_MEM} * 0.3" | bc | cut -d. -f1)M

# 内存小于 1.5G 退出 使用默认配置
if [ ${TOTAL_MEM} -le 1500 ]; then
    exit 1
# 内存小于 2.5G 配置
elif [ ${TOTAL_MEM} -gt 1500 -a ${TOTAL_MEM} -le 2500 ]; then
    thread_cache_size=16
    key_buffer_size=16M
    innodb_buffer_pool_size=128M
    tmp_table_size=32M
    table_open_cache=256
    max_allowed_packet=8M
# 内存小于 3.5G 配置
elif [ ${TOTAL_MEM} -gt 2500 -a ${TOTAL_MEM} -le 3500 ]; then
    thread_cache_size=32
    key_buffer_size=64M
    innodb_buffer_pool_size=512M
    tmp_table_size=64M
    table_open_cache=512
    max_allowed_packet=16M
# 内存小于 4.5G 配置
elif [ ${TOTAL_MEM} -gt 3500 -a ${TOTAL_MEM} -le 4500 ]; then
    thread_cache_size=64
    key_buffer_size=256M
    innodb_buffer_pool_size=1024M
    tmp_table_size=128M
    table_open_cache=1024
    max_allowed_packet=32M
# 内存大于 4.5G 配置
elif [ ${TOTAL_MEM} -gt 4500 ]; then
    thread_cache_size=128
    key_buffer_size=512M
    innodb_buffer_pool_size=2048M
    tmp_table_size=256M
    table_open_cache=2048
    max_allowed_packet=64M
fi


# 生成配置文件
cat > $MYSQL_CONF << EOF
[client]
port = 3306
default-character-set = utf8mb4

[mysql]
no-auto-rehash
default-character-set = utf8mb4

[mysqld]
# 基础配置
user = mysql
port = 3306

# 字符集配置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init-connect = 'SET NAMES utf8mb4'

# 连接数限制
max_connections = ${max_connections}
max_connect_errors = 6000
max_allowed_packet = ${max_allowed_packet}
wait_timeout = 600
interactive_timeout = 600

# 缓冲区设置
key_buffer_size = ${key_buffer_size}
sort_buffer_size = 8M
read_buffer_size = 8M
read_rnd_buffer_size = 8M
join_buffer_size = 8M
table_open_cache = ${table_open_cache}
table_definition_cache = ${table_definition_cache}
thread_cache_size = ${thread_cache_size}

# InnoDB 配置
default_storage_engine = InnoDB
innodb_buffer_pool_size = ${innodb_buffer_pool_size}
innodb_log_buffer_size = 16M
innodb_file_per_table = 1
innodb_read_io_threads = ${CPU_CORES}
innodb_write_io_threads = ${CPU_CORES}
innodb_flush_log_at_trx_commit = 1
innodb_log_file_size = 384M
innodb_log_files_in_group = 2
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120

# 慢查询日志
slow_query_log = 1
long_query_time = 3
slow-query-log-file = /var/log/mysql/mysql.slow.log
log-error = /var/log/mysql/mysql.error.log

# 其他设置
sql_mode = NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
tmp_table_size = ${tmp_table_size}
max_heap_table_size = 32M
disable-log-bin 
skip-character-set-client-handshake
explicit_defaults_for_timestamp
skip-external-locking
default-time-zone = '+8:00'

# FT 配置
ft_min_word_len = 4

[mysqldump]
quick
max_allowed_packet = ${max_allowed_packet}

[myisamchk]
myisam_sort_buffer_size = ${myisam_sort_buffer_size}
myisam_max_sort_file_size = ${myisam_max_sort_file_size}
read_buffer = 3M
write_buffer = 3M
EOF

