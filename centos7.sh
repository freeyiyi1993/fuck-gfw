#!/bin/bash
function installVPN(){
    echo "begin to install VPN services";
    rm -rf /etc/pptpd.conf
    rm -rf /etc/ppp
    yum install -y epel-release
    yum install -y ppp firewalld pptpd > /dev/null
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
    echo "localip 10.0.0.1" >> /etc/pptpd.conf
    echo "remoteip 10.0.0.100-200" >> /etc/pptpd.conf
    echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
    echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd
    systemctl start firewalld
    zone=public
    firewall-cmd --permanent --new-service=pptp
    cat >/etc/firewalld/services/pptp.xml<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <port protocol="tcp" port="1723"/>
</service>
EOF
    firewall-cmd --permanent --zone=$zone --add-service=pptp
    firewall-cmd --permanent --zone=$zone --add-masquerade
    firewall-cmd --reload
    systemctl start pptpd.service

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
