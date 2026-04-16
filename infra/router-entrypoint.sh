#!/bin/sh

echo "Activando IP forward..."
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Limpiando iptables..."
iptables -F
iptables -t nat -F

echo "Configurando FORWARD..."
iptables -P FORWARD ACCEPT

iptables -A FORWARD -s 172.20.10.0/24 -d 172.20.20.0/24 -j ACCEPT
iptables -A FORWARD -s 172.20.20.0/24 -d 172.20.10.0/24 -j ACCEPT

iptables -A FORWARD -s 172.20.30.0/24 -d 172.20.10.0/24 -j ACCEPT
iptables -A FORWARD -s 172.20.10.0/24 -d 172.20.30.0/24 -j ACCEPT

echo "Configurando NAT..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Router listo"
tail -f /dev/null