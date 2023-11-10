apt-get install openssh-server nmap net-tools lvm2 iproute2 isc-dhcp-server rsync -y
IFC=`ip link | grep -v lo | cut -d' '   -f2 | cut -d: -f1 | sed  '/^$/d'`
IS_NTW=`cat /etc/network/interfaces | grep 192 | wc -l`
if [ $IS_NTW -gt 0 ]; then
    echo "La interfaz ya esta configurada"
else
    echo "Configurando la interfaz"
fi

# por como funciona parallels es necesario bloquear el DHCP interno
IS_DHCP=`cat /etc/dhcp/dhclient.conf | grep 211 | wc -l`
if [ $IS_DHCP -gt 0 ]; then
    echo "DHCP client ya esta configurado"
else
    echo "Configurando DHCP client"
    echo "reject 10.211.55.0/24" >> /etc/dhcp/dhclient.conf
fi

#  configuracion ip fija y default gateway
read -r -d '' CONFIG <<- EOF
auto $IFC:1\n
iface $IFC:1 inet static\n
address 192.168.10.162\n
netmask 255.255.255.224\n
gateway 192.168.10.161\n
EOF
    echo -e $CONFIG >> /etc/network/interfaces
    /etc/init.d/networking restart
    ip addr | grep 192

ip route flush 0/0
/sbin/route add default gw 192.168.10.161

echo "Configurando el DHCP server"
if [ -f /etc/default/isc-dhcp-server.original ]; then
    echo "Ya hay un backup isc-dhcp-server"
else
    echo "Haciendo backup del archivo de isc-dhcp-server"
    cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.original
fi

if [ -f /etc/dhcp/dhcpd.conf.original ]; then
    echo "Ya hay un backup de dhcpd"
else
    echo "Haciendo backup del archivo de dhcpd"
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.original
fi

echo "INTERFACESv4=\"$IFC:1\"" > /etc/default/isc-dhcp-server

# en cait1 y cait2 hay que poner la mac address de las VM
read -r -d '' DHCPD_CONFIG <<- EOF
option domain-name "palermo.org";\n
option domain-name-servers 8.8.8.8;\n

default-lease-time 600;\n
max-lease-time 7200;\n
authoritative;\n

subnet 192.168.10.160 netmask 255.255.255.224 {\n
  range 192.168.10.171 192.168.10.190;\n
  option subnet-mask 255.255.255.224;\n
  option routers 192.168.10.161;\n
  option domain-name-servers 8.8.8.8;\n
}\n

host cait1 {\n
  hardware ethernet 00:1c:42:da:fb:60;\n
  fixed-address 192.168.10.163;\n
}\n

host cait2 {\n
  hardware ethernet 00:1c:42:da:fb:61; \n
  fixed-address 192.168.10.165;\n
}\n
EOF

echo -e $DHCPD_CONFIG > /etc/dhcp/dhcpd.conf
systemctl stop isc-dhcp-server 
systemctl start isc-dhcp-server

echo "Instalando cronjob de backups"
cp backup-data1.sh /home/caadmin/
chmod 755 /home/caadmin/backup-data1.sh

IS_CTB=`cat /etc/crontab | grep backup-data1 | wc -l`
if [ $IS_CTB -gt 0 ]; then
    echo "El cronjob ya esta instalado"
else
    echo "Instalando el cronjob"
    echo "*/5 * * * * root /home/caadmin/backup-data1.sh" >> /etc/crontab
fi
