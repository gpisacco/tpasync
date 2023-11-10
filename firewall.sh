apt-get install openssh-server nmap net-tools iptables tcpdump iftop -y
IFC=`ip link | grep -v lo | cut -d' '   -f2 | cut -d: -f1 | sed  '/^$/d'`
IS_NTW=`cat /etc/network/interfaces | grep 192 | wc -l`
if [ $IS_NTW -gt 0 ]; then
    echo "La interfaz ya esta configurada"
else
    echo "Configurando la interfaz"
read -r -d '' CONFIG <<- EOF
auto $IFC:1\n
iface $IFC:1 inet static\n
address 192.168.10.161\n
netmask 255.255.255.224\n
EOF
    echo -e $CONFIG >> /etc/network/interfaces
    /etc/init.d/networking restart
    ip addr | grep 192
fi

echo "Habilitando el forward"
IP_FWD=`cat /proc/sys/net/ipv4/ip_forward`
if [ $IP_FWD -eq 1 ]; then
    echo "El forward ya esta habilitado"
else
    echo "Habilitando el forward"
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
fi

echo "Removiendo todas las reglas existentes"
/sbin/iptables -F
/sbin/iptables -X
/sbin/iptables -t nat -F
/sbin/iptables -t nat -X
/sbin/iptables -t mangle -F
/sbin/iptables -t mangle -X
/sbin/iptables -t filter -F
/sbin/iptables -t filter -X
/sbin/iptables -P INPUT ACCEPT
/sbin/iptables -P OUTPUT ACCEPT
/sbin/iptables -P FORWARD ACCEPT

echo "Denegando todo el trafico entrante y saliente de la table filter"
/sbin/iptables -P INPUT DROP
/sbin/iptables -P OUTPUT DROP
/sbin/iptables -P FORWARD DROP

echo "Permitiendo el trafico de la interfaz loopback"
/sbin/iptables -A INPUT -i lo -j ACCEPT
/sbin/iptables -A OUTPUT -o lo -j ACCEPT
/sbin/iptables -A OUTPUT -o $IFC -j ACCEPT
/sbin/iptables -A FORWARD -o $IFC -j ACCEPT
/sbin/iptables -A INPUT -i $IFC -j DROP

echo "Habilitar la navegacion web para todas las computadoras"
/sbin/iptables -t nat -A POSTROUTING -s 192.168.10.161/27 -d 0.0.0.0/0 -j MASQUERADE
/sbin/iptables -A FORWARD -s 192.168.10.161/27 -d 0.0.0.0/0 -i $IFC:1 -o $IFC -j ACCEPT
/sbin/iptables -A FORWARD -d 192.168.10.161/27 -s 0.0.0.0/0 -i $IFC -o $IFC:1 -j ACCEPT

echo "Habilitando SSH para las computadoras de IT"
/sbin/iptables -A INPUT -p tcp -s  192.168.10.162,192.168.10.163,192.168.10.164 --dport 22 -j ACCEPT
/sbin/iptables -A OUTPUT -p tcp -d 192.168.10.162,192.168.10.163,192.168.10.164  --sport 22 -m state --state ESTABLISHED -j ACCEPT

echo "Persistiendo las reglas"
/sbin/iptables-save > /etc/iptables.up.rules

read -r -d '' RESTORE <<- EOF
#!/bin/sh\n
iptables-restore < /etc/iptables.up.rules\n
EOF

echo -e $RESTORE > /etc/network/if-pre-up.d/iptables
chmod 755 /etc/network/if-pre-up.d/iptables

echo "Reiniciando el servicio de red"
/etc/init.d/networking restart