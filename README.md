# BBRplus
//编写中  

在https://blog.csdn.net/dog250/article/details/80629551 中，  
dog250大神提到了bbr初版的两个问题：bbr在高丢包率下易失速以及bbr收敛慢的问题，  
提到了他个人与bbr作者对这两个问题的一些修正，并在文末给出了修正后的完整代码。  
在这里我**只是将它编译出来（不是我写的）并做成了一键脚本**，我叫它bbr修正版，或者bbrplus。  
它基于原版bbr，但修正了bbr存在的上述问题，尝试使其更好，减少排队和丢包。  
  
由于编译修正后的模块需要4.14版的内核，  
以及需要修改内核的部分源码，所以需要重新编译整个内核。  
这里提供一个编译好并内置bbrplus的适用于centos7的内核，以及安装方法供大家测试。  
编译的详细方法有时间也会写上来。  

**感谢dog250大神对bbr相关原理和代码的解析与分享！**  

**注意，这是一个实验性的修改，没有人对它的稳定性负责，也不担保它一定能产生正向的效果。  
所以请酌情使用，at your own risk.**

# 脚本安装方法：  
由于我只用centos7以及编译内核是一个相当折腾的事，  
目前只编译了适合CentOS的内核，Debian/Ubuntu有时间的话折腾一个。  

一键脚本(CentOS)：  
```bash
wget "https://github.com/cx9208/bbrplus/raw/master/ok_bbrplus_centos.sh" && chmod +x ok_bbrplus_centos.sh && ./ok_bbrplus_centos.sh
```
安装后，执行uname -r，显示4.14.89则切换内核成功  
执行lsmod | grep bbr，显示有bbrplus则开启成功   

# 手动安装方法：  
1.  
卸载本机的锐速（如果有）  

2.  
下载内核  
wget https://github.com/cx9208/bbrplus/raw/master/centos7/x86_64/kernel-4.14.90.rpm  

3.  
安装内核  
yum install -y kernel-4.14.89-1.x86_64.rpm  

4.  
切换启动内核  
grub2-set-default 'CentOS Linux (4.14.90) 7 (Core)'  

5.  
设置fq  
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf  
设置bbrplus  
echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf  

6.  
重启  
reboot  

7.
检查内核版本  
uname -r  
显示4.14.89则成功  

检查bbrplus是否已经启动  
lsmod | grep bbrplus  
显示有tcp_bbrplus则成功  

# 卸载方法：  
安装别的内核bbrplus自动失效，卸载内核自行谷歌即可  

# 内核编译：  

只能用于4.14.x内核，更高版本的tcp部分源码有改动，要移植到高版本内核得自己研究  

下载4.14内核源码   
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.91.tar.xz   

解压   
tar  -Jxvf  linux-4.14.91.tar.xz -C  /root/   

修改linux-4.14.91/include/net/inet_connection_sock.h，139行  
u64     icsk_ca_priv[112 / sizeof(u64)];  
#define ICSK_CA_PRIV_SIZE      (14 * sizeof(u64))  
这两段数值改为112和14，如上  

修改/net/ipv4/tcp_output.c#L，1823行  
tcp_snd_wnd_test函数大括号后}  
换行添加EXPORT_SYMBOL(tcp_snd_wnd_test);  

添加tcp_bbrplus.c，删除/net/ipv4/tcp_bbr.c  
修改linux-4.14.91/net/ipv4/Makefile，  
obj-$(CONFIG_TCP_CONG_BBR) += tcp_bbrplus.o，bbr改为bbrplus  

安装依赖
centos  
yum -y groupinstall Development tools  
yum -y install ncurses-devel bc gcc gcc-c++ ncurses ncurses-devel cmake elfutils-libelf-devel openssl-devel rpm-build redhat-rpm-config asciidoc hmaccalc perl-ExtUtils-Embed xmlto audit-libs-devel binutils-devel elfutils-devel elfutils-libelf-devel newt-devel python-devel zlib-devel  

debian  
wget -qO- git.io/superupdate.sh | bash  
apt-get install build-essential libncurses5-dev  
apt-get build-dep linux  

切换到目录 
cd /root/linux-4.14.91  

配置  
make oldconfig  
或者  
make menuconfig  

确保CONFIG_TCP_CONG_BBR=m  

禁用签名调试  
scripts/config --disable MODULE_SIG  
scripts/config --disable DEBUG_INFO  


开始编译  
centos：make rpm-pkg

debian：make deb-pkg

