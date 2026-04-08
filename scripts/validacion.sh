#!/bin/bash
echo "========================================="
echo " VALIDACIÓN COMPLETA - INFRAESTRUCTURA   "
echo "========================================="

echo -e "\n[1] Contenedores Up:"
sudo docker compose -f infra/docker-compose.yml ps --format "table {{.Name}}\t{{.State}}"

echo -e "\n[2] IP forwarding router (Debe ser 1):"
sudo docker exec router cat /proc/sys/net/ipv4/ip_forward

echo -e "\n[3] Rutas del Servidor Web:"
sudo docker exec servidor_web ip route | grep "172.20."

echo -e "\n[4] Rutas de la Base de Datos:"
sudo docker exec base_datos ip route | grep "172.20."

echo -e "\n[5] Rutas del Atacante:"
sudo docker exec atacante ip route | grep "172.20."

echo -e "\n[6] Ping Web -> DB (Debe decir '2 received'):"
sudo docker exec servidor_web ping -c 2 172.20.20.10 | grep "received"

echo -e "\n[7] Ping Atacante -> Web (Debe decir '2 received'):"
sudo docker exec atacante ping -c 2 172.20.10.10 | grep "received"

echo -e "\n[8] Acceso HTTP desde el host (Debe ser 200):"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080

echo -e "\n[9] Escaneo de puerto MySQL desde Monitor (Debe decir 'succeeded' u 'open'):"
sudo docker exec monitor nc -zv 172.20.20.10 3306 2>&1 | grep -iE "open|succeeded|connected"

echo -e "\n[10] Prueba de estrés rápida (CPU del Web debe subir):"
# Lanzamos 10 hilos de peticiones agresivas en segundo plano
sudo docker exec -d atacante sh -c "for i in \$(seq 1 10); do while true; do wget -q -O /dev/null http://172.20.10.10; done & done"
# Le damos 4 segundos a Docker para que actualice sus métricas
sleep 4
# Tomamos la captura de la CPU
sudo docker stats --no-stream servidor_web --format "CPU del Servidor Web: {{.CPUPerc}}"
# Detenemos el ataque limpiamente
sudo docker exec atacante sh -c "pkill wget"

echo -e "\n========================================="
echo " VALIDACIÓN TERMINADA                    "
echo "========================================="
