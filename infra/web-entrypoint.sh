#!/bin/sh
set -eu

echo "Configurando rutas WEB..."
ip route add 172.20.20.0/24 via 172.20.10.254 || true
ip route add 172.20.30.0/24 via 172.20.10.254 || true

echo "Esperando MySQL..."
until mysqladmin --protocol=TCP --skip-ssl ping -h 172.20.20.10 -uappuser -papppass --silent; do
  sleep 1
done

echo "MySQL listo"
exec apache2-foreground
