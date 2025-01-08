#! /bin/bash

# 获取当前脚本的软链接路径
SYMLINK_PATH=$(readlink -f "$0")
# 当前目录
DNMP_DIR=$(dirname "$SYMLINK_PATH")
DNMP_DIR=$(realpath "$DNMP_DIR")
# 生成密码
MYSQL_ROOT_PASSWORD=$(head -c 15 /dev/urandom | base64 | tr -d '/' | tr -d '=' | tr -d '+')
# 替换.env文件中的MYSQL_ROOT_PASSWORD
sed -i "s/MYSQL_ROOT_PASSWORD=.*/MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD/" $DNMP_DIR/.env
# 加载ENV
source $DNMP_DIR/.env
# 加载颜色
source $DNMP_DIR/colors.sh
# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echoRR "请使用 root 权限运行此脚本"
    exit 1
fi

# 初始化备份目录
mkdir -p $BACKUP_STORAGE_DIR
# 初始化站点目录
mkdir -p $VHOSTS_ROOT
# 初始化站点配置目录
mkdir -p $VHOSTS_CONF_DIR
# 初始化站点日志目录
mkdir -p $LOG_DIR/{nginx,php83,mysql}

# 卸载旧版本 Docker（如果存在）
echoSB "Remove Old Version Docker."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1
apt update

# 安装依赖包
echoSB "Install Necessary Packages."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip gawk certbot zstd pv ghostscript bc tzdata iptables
# 创建防火墙规则
function firewall_rules_create {
    #是否存在iptables
    if [ -z "$(which iptables)" ]; then
        echoRC 'iptables不存在'
        exit 1
    fi
    # 添加防火墙规则
    cp $DNMP_DIR/firewall /etc/iptables.rules
    # 添加重启自动加载防火寺规则
    cp $DNMP_DIR/rc.local /etc/rc.local
    # ssh端口
    local ssh=$(ss -tapl | grep sshd | awk 'NR==1 {print $4}' | cut -f2 -d :)
    [ -n "$ssh" ] && sed -i "s/22,80/$ssh,80/" /etc/iptables.rules
    # 添加执行权限
    chmod +x /etc/rc.local
    # 启动服务
    systemctl start rc-local
}
firewall_rules_create

# 添加 Docker 官方 GPG 密钥 和 仓库
echoSB "Add Docker Official GPG Key and Repository."
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y

# 安装 Docker Engine
echoSB "Install Docker Engine."
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 将当前用户添加到 docker 组
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
fi

# 克隆 modsecurity 规则
echoSB "Download Modsecurity Rules."
git clone --depth 1 https://github.com/coreruleset/coreruleset.git 
mv coreruleset/rules/* $DNMP_DIR/nginx/modsecurity/rules/
rm -rf coreruleset
# 指定目录下 删除文件名中包含 java | iis 的文件 不区分大小写
rm -r $DNMP_DIR/nginx/modsecurity/rules/*java* $DNMP_DIR/nginx/modsecurity/rules/*iis*
rm -r $DNMP_DIR/nginx/modsecurity/rules/*JAVA* $DNMP_DIR/nginx/modsecurity/rules/*IIS*

# 下载 wordpress 规则例外
wget https://raw.githubusercontent.com/coreruleset/wordpress-rule-exclusions-plugin/master/plugins/wordpress-rule-exclusions-config.conf -O $DNMP_DIR/nginx/modsecurity/exceptions/wordpress-rule-exclusions-config.conf
wget https://raw.githubusercontent.com/coreruleset/wordpress-rule-exclusions-plugin/master/plugins/wordpress-rule-exclusions-before.conf -O $DNMP_DIR/nginx/modsecurity/exceptions/wordpress-rule-exclusions-before.conf

# 判断是否安装成功 根据docker 命令是否存在
if [ -x "$(command -v docker)" ]; then
    systemctl start docker
    systemctl enable docker
    echoGC "Docker Install Success."
    echoSB "Start Docker Compose Service."
    cd $DNMP_DIR
    docker compose down >/dev/null 2>&1
    docker compose up -d
else
    echoRR "Docker Install Failed."
    exit 1
fi

# 创建软链接
rm -rf /usr/local/bin/vhost.sh
chmod +x $DNMP_DIR/vhost.sh
ln -s $DNMP_DIR/vhost.sh /usr/local/bin/vhost.sh


