#!/bin/sh
set -eu

echo "IP forward habilitado por sysctl del contenedor"
echo "Reiniciando reglas de forwarding..."
iptables -F FORWARD
iptables -t nat -F
iptables -P FORWARD ACCEPT

# Mantiene la topologia original con reglas explicitas entre subredes sin
# introducir NAT adicional ni alterar el flujo academico del laboratorio.
for src in 172.20.10.0/24 172.20.20.0/24 172.20.30.0/24; do
  for dst in 172.20.10.0/24 172.20.20.0/24 172.20.30.0/24; do
    if [ "$src" != "$dst" ]; then
      iptables -A FORWARD -s "$src" -d "$dst" -j ACCEPT
    fi
  done
done

echo "Router listo"
exec tail -f /dev/null
