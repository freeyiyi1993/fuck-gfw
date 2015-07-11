#!/bin/bash
set -e
function installVPN(){
    echo 'VPN User:'
    read user
    echo 'Password:'
    read pass
    cd /tmp
    echo "begin to install VPN services";
    yum remove -y pptpd ppp
    iptables --flush POSTROUTING --table nat
    iptables --flush FORWARD
    rm -rf /etc/pptpd.conf
    rm -rf /etc/ppp
    arch=`uname -m`
    yum -y install ppp iptables pptpd
    mknod /dev/ppp c 108 0
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
    echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
    echo "localip 192.168.0.1" >> /etc/pptpd.conf
    echo "remoteip 192.168.0.234-238,192.168.0.245" >> /etc/pptpd.conf
    echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
    echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd
    echo "${user} pptpd ${pass} *" >> /etc/ppp/chap-secrets
    iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth1 -jMASQUERADE 
    service iptables save
    chkconfig iptables on
    chkconfig pptpd on
    service iptables start
    service pptpd start
    echo "VPN service is installed, your VPN username is ${user}, VPN password is ${pass}"
    cd -
}

function installPython(){
    cd ~
    yum install -y gcc zlib-devel openssl-devel libffi-devel
    wget --no-check-certificate https://www.python.org/ftp/python/2.7.7/Python-2.7.7.tgz -O Python-2.7.7.tgz
    tar zxf Python-2.7.7.tgz
    cd Python-2.7.7
    ./configure --prefix=/usr/local/Python2.7 --enable-shared
    make && make install
    echo /usr/local/Python2.7/lib >> /etc/ld.so.conf
    cp /usr/local/Python2.7/bin/python2.7 /usr/bin/python2.7
    ln -s /usr/local/Python2.7/lib/libpython2.7.so.1.0 /usr/lib/libpython2.7.so
    ldconfig
    wget https://bootstrap.pypa.io/get-pip.py
    python2.7 get-pip.py
    /usr/local/Python2.7/bin/pip install gevent pyOpenSSL dnslib supervisor
    cd -
    rm -rf ~/Python-2.7.7 ~/Python-2.7.7.tgz
}

function installGoAgent() {
    installPython
    echo 'goagent User:'
    read user
    echo 'Password:'
    read pass
    goagent_dir=/tmp/goagent
    rm -rf $goagent_dir
    yum install -y git
    git clone https://github.com/goagent/goagent.git $goagent_dir
    cp -r ${goagent_dir}/server/vps/ /opt/goagent
    mkdir -p /opt/goagent/log/
    sed -i 's~/usr/bin/env python~/usr/bin/env python2.7~' /opt/goagent/goagentvps.sh
    echo "${user} ${pass}" > /opt/goagent/goagentvps.conf
    cp $goagent_dir/local/proxylib.py /opt/goagent/
    sh /opt/goagent/goagentvps.sh start
    echo '*/10 * * * * root sh /opt/goagent/goagentvps.sh restart'
    rm -rf $goagent_dir
}
echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. install goagent service"
echo "3. install shadowsocks service"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (installGoAgent);;
[3] ) ();;
*) echo "nothing,exit";;
esac
