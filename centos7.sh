#!/bin/bash
function installVPN(){
    echo "begin to install VPN services";
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm > /dev/null
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

function installGoAgent() {
    goagent_dir=/tmp/goagent
    rm -rf $goagent_dir
    yum install -y git
    git clone https://github.com/goagent/goagent.git $goagent_dir
    cp -r ${goagent_dir}/server/vps/ /opt/goagent
    mkdir -p /opt/goagent/log/
    cp $goagent_dir/local/proxylib.py /opt/goagent/
    setGoagentUser
    chmod +x /opt/goagent/goagentvps.sh
    /opt/goagent/goagentvps.sh start
    echo '*/10 * * * * root /opt/goagent/goagentvps.sh restart' >> /etc/crontab
    rm -rf $goagent_dir
}

function installShadowSocks() {
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
