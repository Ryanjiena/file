#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#===================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Config Docker Hub Mirrors
#	Version: 0.0.1
#	Author: ryanjiena
#	Blog: https://www.ryanjie.cn
#===================================================
# Fonts Color
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"

# Notification Information
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

# 版本、初始化变量
sh_ver="0.0.1"
filepath=$(cd "$(dirname "$0")"; pwd)
docker_conf_dir="/etc/docker"
docker_conf="${docker_conf_dir}/daemon.json"

# shellcheck disable=SC1091

# 检查账户权限
check_root(){
  if [ 0 == $UID ]; then
        echo -e "${Info} 当前用户是 ROOT 用户，可以继续操作" && sleep 1
    else
        echo -e "${Error} 当前非 ROOT 账号(或没有 ROOT 权限)，无法继续操作，请更换 ROOT 账号或使用 ${Green_background_prefix}su${Font_color_suffix} 命令获取临时 ROOT权限（执行后可能会提示输入当前账号的密码）。"&& exit 1
    fi
}

# 配置 
config_dockerhub_mirrors(){
  if [[ ! -d ${docker_conf_dir} ]]; then
    mkdir -p ${docker_conf_dir}
  fi
  cat > ${docker_conf} <<-EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/"]
}
EOF
  systemctl daemon-reload && systemctl restart docker
}

check_root
config_dockerhub_mirrors
