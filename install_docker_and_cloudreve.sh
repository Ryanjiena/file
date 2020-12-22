#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#============================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Install Docker + Cloudreve for Linux
#	Version: 0.1.2
#	Author: ryanjiena
#	Blog: https://www.ryanjie.cn
#============================================================
# Fonts Color
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"

# Notification Information
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

# 版本、初始化变量
sh_ver="0.1.2"
filepath=$(cd "$(dirname "$0")"; pwd)
docker_compose_default_ver="1.27.0"
cloudreve_date_default_path="/cloudreve"
cloudreve_default_port="80"
cloudreve_default_name="docker-cloudreve"
curl="/usr/bin/curl"

# shellcheck disable=SC1091

# 检查账户权限
check_root(){
  if [ 0 == $UID ]; then
        echo -e "${Info} 当前用户是 ROOT 用户，可以继续操作" && sleep 1
    else
        echo -e "${Error} 当前非 ROOT 账号(或没有 ROOT 权限)，无法继续操作，请更换 ROOT 账号或使用 ${Green_background_prefix}su${Font_color_suffix} 命令获取临时 ROOT权限（执行后可能会提示输入当前账号的密码）。"&& exit 1
    fi
}

# 检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
  fi
}

# 检查 curl 是否安装
check_curl_installed_status(){
	if [[ ! -e ${curl} ]]; then
		echo -e "${Error} curl 没有安装，开始安装..."
		if [[ ${release} == "centos" ]]; then
			yum install curl -y
		else
			apt-get install curl -y
		fi
		if [[ ! -e ${curl} ]]; then
			echo -e "${Error} curl 安装失败，请检查！" && exit 1
		else
			echo -e "${Info} curl 安装成功！"
		fi
	fi
}

# 检测 Docker
check_docker() {
	if [ -x "$(command -v docker)" ]; then
		echo -e "${Info} 您的系统已安装 Docker"
	else
		echo -e "${Info} 开始安装docker。。。"
    # systemctl is-active "docker" &>/dev/null || install_docker
		install_docker        
	fi
}

# 安装 Docker
install_docker() {
    echo -e "${Info} 开始安装 Docker 最新版本 ... "
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    systemctl daemon-reload
    systemctl enable docker && groupadd docker && usermod -aG docker ${USER} && systemctl restart docker
    
}

# 检测 Docker 环境
check_docker_compose() {
	if [ -x "$(command -v docker-compose)" ]; then
		echo -e "${Info} docker-compose is installed"
	else
		echo -e "${Info} Install docker-compose ..."
		install_docker_compose
	fi
}

# 安装 Docker 环境
install_docker_compose() {
  echo -e "${Info} 开始安装 Docker 环境 ... "
  docker_compose_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/docker/compose/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
  if [[ -z ${docker_compose_new_ver} ]]; then
    echo -e "${Error} docker compose 最新版本获取失败，请手动获取最新版本号[ https://github.com/docker/compose/releases ]"
    read -e -p "请输入版本号 [ 格式如 1.27.0 ] :" docker_compose_new_ver
    if [[ -z "${docker_compose_new_ver}" ]]; then
      echo -e "${Info} 默认安装 docker compose 版本为 [ ${docker_compose_default_ver} ]"
      curl -L "https://github.com/docker/compose/releases/download/${docker_compose_default_ver}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
    fi
  else
    echo -e "${Info} 检测到 docker compose 最新版本为 [ ${docker_compose_new_ver} ]"
    curl -L "https://github.com/docker/compose/releases/download/${docker_compose_new_ver}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi
}

# 检查 cloudreve
check_cloudreve(){
  systemctl is-active "docker" &>/dev/null || install_docker
  docker ps -a | grep cloudreve &>/dev/null || install_cloudreve
}

# 安装 Cloudreve
install_cloudreve(){
  docker pull ilemonrain/cloudreve:latest
  read -e -p "请输入映射路径(将容器中的 /cloudreve 目录进行映射，以确保容器中数据的安全，避免在容器意外崩溃时导致数据丢失)， [ 默认为 /cloudreve ] :" cloudreve_date_path
    if [[ -z "${cloudreve_date_path}" ]]; then
      cloudreve_date_path=${cloudreve_date_default_path}
      echo -e "${Info} 默认安装 docker compose 版本为 [ ${cloudreve_date_path} ]"
    fi
  read -e -p "请输入 Cloudreve 绑定的 URL(例如：www.ryanjie.cn)， [ 默认为本地 IP ] :" cloudreve_url  
    if [[ -z "${cloudreve_url}" ]]; then
      echo -e "${Info} 正在获取 公网ip 信息，请耐心等待 ${Font_color_suffix}"
      cloudreve_url=$(curl -s https://api64.ipify.org)
    fi
  # read -e -p "请输入 Docker 容器的名称 [ 默认为 docker-cloudreve ] :" cloudreve_name
  #   if [[ -z "${cloudreve_name}" ]]; then
  #     cloudreve_name=${cloudreve_default_name}
  #     echo -e "${Info} Docker 容器的名称为 [ ${cloudreve_name} ]"
  #   fi  
  docker run -t -p 80:80 -v ${cloudreve_date_path}:/cloudreve -e CLOUDREVE_URL="http:${cloudreve_url}/" --name cloudreve ilemonrain/cloudreve
  echo -e "${Info} 安装完成，请访问 http:${cloudreve_url} 配置 Cloudreve！"
}

# 卸载 cloudreve
uninstall_cloudreve(){
  docker stop cloudreve
  docker rm -f cloudreve
    echo -e "${Info} 卸载 cloudreve 完成！ ${Font_color_suffix}"
  sleep 3
}

# 环境检查
status_check(){
    systemctl is-active "docker" &>/dev/null || echo -e "${Error} docker 未安装！"
    if [ ! -x "$(command -v docker-compose)" ]; then
      echo -e "${Error} docker-compose 未安装！"
    fi
    docker ps -a | grep cloudreve &>/dev/null || echo -e "${Error} cloudreve 未安装！"
}

# 开始菜单
menu(){
  clear
  check_root
  status_check
  echo && echo -e " Docker + Cloudreve 一键安装脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ————————————
  ${Green_font_prefix} 0.${Font_color_suffix} 安装 Docker
  ${Green_font_prefix} 1.${Font_color_suffix} 安装 Docker 环境
  ${Green_font_prefix} 2.${Font_color_suffix} 安装 Cloudreve 
  ${Green_font_prefix} 3.${Font_color_suffix} 卸载 Cloudreve 
  ${Green_font_prefix} 4.${Font_color_suffix} 退出脚本 
  ————————————" && echo
  echo
  read -e -p " 请输入数字 [0-4]:" num
  case "$num" in
    0)
      check_docker
      ;;
    1)
      check_docker_compose
      ;;
    2)
      check_cloudreve
      ;;
    3)
      uninstall_cloudreve
      ;;
    4)
      exit 0
      ;;
    *)
    echo "请输入正确数字 [0-4]"
    ;;
  esac
  fi
}

start_menu
