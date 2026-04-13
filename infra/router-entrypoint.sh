#!/bin/bash

# === NAT usando IPs en lugar de nombres de interfaz ===
# Obtener interfaz que tiene la IP pública (172.20.10.254)
PUBLIC_IF=$(ip -o addr show | grep "172.20.10.254" | awk '{print $2}')

# Obtener interfaz que tiene la IP privada (172.20.20.254)
PRIVATE_IF=$(ip -o addr show | grep "172.20.20.254" | awk '{print $2}')

# Obtener interfaz que tiene la IP de ataque (172.20.30.254)
ATTACK_IF=$(ip -o addr show | grep "172.20.30.254" | awk '{print $2}')

echo "=== Interfaces detectadas ==="
echo "Interfaz pública (172.20.10.254): $PUBLIC_IF"
echo "Interfaz privada (172.20.20.254): $PRIVATE_IF"
echo "Interfaz ataque (172.20.30.254): $ATTACK_IF"

# === NAT (usando interfaces detectadas) ===
iptables -t nat -A POSTROUTING -s 172.20.20.0/24 -o $PUBLIC_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.30.0/24 -o $PUBLIC_IF -j MASQUERADE
iptables -P FORWARD ACCEPT

# === LIMITAR ANCHO DE BANDA (en la interfaz pública) ===
wondershaper -a $PUBLIC_IF -d 1024 -u 1024

echo "=== Router con NAT y límite de 1 Mbps iniciado ==="
ip addr show | grep -E "^[0-9]+:|inet "

tail -f /dev/null