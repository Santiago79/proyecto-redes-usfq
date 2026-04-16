#!/bin/sh
set -e

echo "Instalando paquetes..."
apt-get update
apt-get install -y iproute2 net-tools procps default-mysql-client || apt-get install -y mariadb-client

echo "Esperando MySQL..."
until mysqladmin ping -h 172.20.20.10 --silent; do
  sleep 1
done

echo "MySQL listo"

echo "Configurando rutas..."
ip route add 172.20.30.0/24 via 172.20.10.254 || true
ip route add 172.20.20.0/24 via 172.20.10.254 || true

echo "Iniciando Apache..."
exec apache2-foreground