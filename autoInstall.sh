#/bin/bash

[ -f /etc/init.d/functions ] && . /etc/init.d/functions

# 创建文件夹
function createNotExist(){
	if [ ! -d "$1" ];then
		mkdir -p "$1";
	fi
}
# 显示文字
function echoGreen(){
	echo -e "\033[32m$1\033[0m"  
}

createSuccess= createNotExist "/data/download";
createSuccess= createNotExist "/data/software";

tomcatVersion="8.5.47";
tomcatInstallPath="/data/software/apache-tomcat-${tomcatVersion}";

nginxVersion="1.16.1";
nginxInstallPath="/data/software/nginx"

mysqlVersion="mysql-5.7.24-linux-glibc2.12-x86_64";
mysqlInstallPath="/usr/local/mysql";

yum -y install wget

function JDK(){
	echoGreen "开始安装jdk" &&\
	yum install java-1.8.0-openjdk.x86_64 -y &&\
	echoGreen "jdk安装成功"
}
# JDK;

function TOMCAT(){
	cd /data/download
	# 安装需要的软件
	echoGreen "开始安装Tomcat,版本:${tomcatVersion}"
	wget http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v${tomcatVersion}/bin/apache-tomcat-${tomcatVersion}.tar.gz&&\
	tar -zxvf apache-tomcat-${tomcatVersion}.tar.gz&&\
	mv apache-tomcat-${tomcatVersion} ${tomcatInstallPath}&&\
	rm apache-tomcat-${tomcatVersion}.tar.gz
}

# TOMCAT;
function NGINX(){
	cd /data/download
	echoGreen "开始安装nginx,版本:${nginxVersion}"

	echoGreen "开始安装nginx依赖包"
	yum -y install gcc zlib zlib-devel pcre-devel openssl openssl-devel automake autoconf libtool make &&\
	wget http://nginx.org/download/nginx-${nginxVersion}.tar.gz&&\
	tar -zxvf nginx-${nginxVersion}.tar.gz&&\
	mv nginx-${nginxVersion} ${nginxInstallPath}&&\
	rm nginx-${nginxVersion}.tar.gz&&\

	cd ${nginxInstallPath}&&\
	./configure && make && make install&&\
	echoGreen "nginx安装完成,nginx配置文件地址:/usr/local/nginx/conf/nginx.conf"
}
# NGINX;

function MYSQL(){
	cd /data/download
	groupadd mysql;
	useradd -r -g mysql mysql;
	wget http://mirror.centos.org/centos/6/os/x86_64/Packages/libaio-0.3.107-10.el6.x86_64.rpm&&\
	rpm -ivh libaio-0.3.107-10.el6.x86_64.rpm
	yum install -y numactl
	wget http://172.18.163.64:8080/${mysqlVersion}.tar.gz&&\
	tar xzvf ${mysqlVersion}.tar.gz&&\

	#mkdir -p ${mysqlInstallPath}&&\
	mv ${mysqlVersion} ${mysqlInstallPath}&&\
	cd ${mysqlInstallPath}&&\
	mkdir ${mysqlInstallPath}/data&&\

	chown -R mysql:mysql ${mysqlInstallPath}&&\
	chmod -R 755 ${mysqlInstallPath}&&\
	cd ${mysqlInstallPath}/bin&&\
	./mysqld --initialize --user=mysql --datadir=/${mysqlInstallPath}/data --basedir=${mysqlInstallPath}  2>&1 | tee mysqlInstallInfo.txt
	mysqlPassword=$(cat mysqlInstallInfo.txt|grep "root@localhost:")
	mysqlPassword=${mysqlPassword#*for}
	rm -f mysqlInstallInfo.txt

	if [ -f /etc/my.cnf ];then
    	mv /etc/my.cnf /etc/my.cnf.bak
    fi
    # 配置写入
    cat >>/etc/my.cnf<<EOF
[mysqld]
datadir=$mysqlInstallPath/data
socket = /tmp/mysql.sock
log-error = $mysqlInstallPath/data/error.log
pid-file = $mysqlInstallPath/data/mysql.pid
port = 3306
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
symbolic-links=0
max_connections=400
innodb_file_per_table=1
#表名大小写不明感，敏感为
lower_case_table_names=1
user = mysql
EOF
#启动所需文件生成
touch "$mysqlInstallPath/3306erroe.log"
touch "$mysqlInstallPath/3306mysql.pid"
# 添加链接
ln -s /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
# 预设置开机自启动
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
}
MYSQL;

echoGreen "Tomcat安装成功: ${tomcatInstallPath}"
echoGreen "nginx启动命令:/usr/local/nginx/sbin/nginx"
echoGreen "nginx重加载命令:/usr/local/nginx/sbin/nginx -s reload"
echoGreen "MySQL密码为:${mysqlPassword}"
echoGreen "MySQL启动命令: ${mysqlInstallPath}/support-files/mysql.server start"
echoGreen "MySQL登陆后修改密码: ALTER USER USER() IDENTIFIED BY 'root';"
echoGreen "MySQL设置开机自启动: chkconfig --add mysqld"





