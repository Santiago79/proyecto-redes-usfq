#!/bin/sh

# Limpiar reglas iptables que puedan bloquear
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -F

# Mostrar configuración actual
echo "=== Router iniciado ==="
echo "Interfaces de red:"
ip addr show | grep -E "^[0-9]+:|inet "

# Mantener el contenedor vivo
tail -f /dev/null