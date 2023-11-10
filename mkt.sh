apt-get install openssh-server nmap net-tools xfce4 -y
IFC=`ip link | grep -v lo | cut -d' '   -f2 | cut -d: -f1 | sed  '/^$/d'`

echo "Configurando la interfaz"
IS_NTW=`cat /etc/dhcp/dhclient.conf | grep 211 | wc -l`
if [ $IS_NTW -gt 0 ]; then
    echo "La interfaz ya esta configurada"
else
    echo "Configurando la interfaz"
    echo "reject 10.211.55.0/24" >> /etc/dhcp/dhclient.conf
fi
/etc/init.d/networking restart