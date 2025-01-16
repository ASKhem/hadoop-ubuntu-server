#!/bin/bash

# Esperar a que el sistema esté listo
sleep 5

# Cargar módulos necesarios
modprobe ip_tables
modprobe iptable_filter
modprobe iptable_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp

# Limpiar reglas existentes
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Política por defecto
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir localhost y conexiones establecidas
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir puertos específicos
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9870 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8088 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9000 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9864 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 41414 -j ACCEPT

# Permitir ping
iptables -A INPUT -p icmp -j ACCEPT

# Logging (opcional)
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
iptables -A LOGGING -j DROP

exit 0
