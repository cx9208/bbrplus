 #!/usr/bin/env bash

#脚本制作:cx9208
kernel_version="4.14.129-bbrplus"
if [[ ! -f /etc/redhat-release ]]; then
	echo -e "仅支持centos"
	exit 0
fi

if [[ "$(uname -r)" == "${kernel_version}" ]]; then
	echo -e "内核已经安装，无需重复执行。"
	exit 0
fi

#卸载原加速
echo -e "卸载加速..."
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
if [[ -e /appex/bin/serverSpeeder.sh ]]; then
	wget --no-check-certificate -O appex.sh https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh && chmod +x appex.sh && bash appex.sh uninstall
	rm -f appex.sh
fi
echo -e "下载内核..."
wget https://github.com/cx9208/bbrplus/raw/master/centos7/x86_64/kernel-${kernel_version}.rpm
echo -e "安装内核..."
yum install -y kernel-${kernel_version}.rpm

#检查内核是否安装成功
list="$(awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg)"
target="CentOS Linux (${kernel_version})"
result=$(echo $list | grep "${target}")
if [[ "$result" = "" ]]; then
	echo -e "内核安装失败"
	exit 1
fi

echo -e "切换内核..."
grub2-set-default 'CentOS Linux (${kernel_version}) 7 (Core)'
echo -e "启用模块..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
rm -f kernel-${kernel_version}.rpm

read -p "bbrplus安装完成，现在重启 ? [Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
	echo -e "重启中..."
	reboot
fi
