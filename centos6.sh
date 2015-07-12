#!/bin/bash
function installVPN(){
    echo "begin to install VPN services";
    rpm -Uvh http://mirrors.hustunique.com/epel/6/i386/epel-release-6-8.noarch.rpm > /dev/null
    iptables --flush POSTROUTING --table nat
    iptables --flush FORWARD
    rm -rf /etc/pptpd.conf
    rm -rf /etc/ppp
    arch=`uname -m`
    yum -y install ppp iptables pptpd > /dev/null
    mknod /dev/ppp c 108 0
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
    echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
    echo "localip 192.168.0.1" >> /etc/pptpd.conf
    echo "remoteip 192.168.0.234-238,192.168.0.245" >> /etc/pptpd.conf
    echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
    echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd
    iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth1 -jMASQUERADE 
    service iptables save
    chkconfig iptables on
    chkconfig pptpd on
    service iptables start
    service pptpd start
    addVPNUser
    echo "VPN service is installed"
}

function addVPNUser() {
    echo 'VPN User:'
    read user
    echo 'Password:'
    read pass
    echo "${user} pptpd ${pass} *" >> /etc/ppp/chap-secrets
}

function installPython(){
    if [ -e /usr/bin/python2.7 ]; then
        return
    fi
    cd ~
    yum install -y gcc zlib-devel openssl-devel libffi-devel wget
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
    echo 'PATH=$PATH:/usr/local/Python2.7/bin' >> /etc/rc.local
    source /etc/rc.local
    pip install gevent pyOpenSSL dnslib supervisor
    cd -
    rm -rf ~/Python-2.7.7 ~/Python-2.7.7.tgz
}

function installGoAgent() {
    installPython
    goagent_dir=/tmp/goagent
    rm -rf $goagent_dir
    yum install -y git
    git clone https://github.com/goagent/goagent.git $goagent_dir
    cp -r ${goagent_dir}/server/vps/ /opt/goagent
    mkdir -p /opt/goagent/log/
    sed -i 's~/usr/bin/env python~/usr/bin/env python2.7~' /opt/goagent/goagentvps.sh
    cp $goagent_dir/local/proxylib.py /opt/goagent/
    setGoagentUser
    cp /opt/goagent/goagentvps.sh /etc/init.d/goagentvps
    chkconfig add goagentvps
    chkconfig goagentvps on
    service goagentvps start
    echo '*/10 * * * * root service goagentvps restart' >> /etc/crontab
    rm -rf $goagent_dir
}
function installShadowSocks() {
    installPython
    pip install shadowsocks
    
}
function setGoagentUser(){
    echo 'goagent User:'
    read user
    echo 'Password:'
    read pass
    echo "${user} ${pass}" > /opt/goagent/goagentvps.conf
}
echo "which do you want to?input the number."
echo "1. install VPN service"
echo "2. install goagent service"
echo "3. install shadowsocks service"
echo "4. Add VPN User"
echo "5. Set goagent User"
read num

case "$num" in
[1] ) (installVPN);;
[2] ) (installGoAgent);;
[3] ) (installShadowSocks);;
[4] ) (addVPNUser);;
[5] ) (setGoagentUser);;
*) echo "nothing,exit";;
esac
