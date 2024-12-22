#! /bin/bash

source ./colors.sh

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echoRR "请使用 root 权限运行此脚本"
    exit 1
fi

# 判断 .env 文件是否存在
if [ ! -f ../.env ]; then
    # 复制 .env.sample 文件为 .env
    cp ../env.sample ../.env
fi

# 卸载旧版本 Docker（如果存在）
echoSB "Remove Old Version Docker."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1
apt update

# 安装依赖包
echoSB "Install Necessary Packages."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip gawk certbot

# 添加 Docker 官方 GPG 密钥 和 仓库
echoSB "Add Docker Official GPG Key and Repository."
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

# 安装 Docker Engine
echoSB "Install Docker Engine."
apt install -y docker-ce docker-ce-cli containerd.io

# 将当前用户添加到 docker 组
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
fi

# 判断是否安装成功 根据docker 命令是否存在
if [ -x "$(command -v docker)" ]; then
    systemctl start docker
    systemctl enable docker
    echoGC "Docker Install Success."
else
    echoRR "Docker Install Failed."
    exit 1
fi

# 安装 docker-compose
echoSB "Install Docker Compose."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 判断docker-compose 命令是否存在
if [ -x "$(command -v docker-compose)" ]; then
    cd ..
    echoSB "Start Docker Compose Service."
    docker-compose up -d
else
    echoRR "docker-compose Install Failed."
    exit 1
fi

# 验证安装
# echoBC "验证安装..."
# docker --version
# docker-compose --version

# echoRC "Docker 安装完成"