#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           VERIFICACIÓN DE INFRAESTRUCTURA DE RED           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Obtener IPs usando docker inspect (sin -it)
ROUTER_IPS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' router 2>/dev/null)
WEB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' servidor_web 2>/dev/null)
DB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' base_datos 2>/dev/null)
ATACANTE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' atacante 2>/dev/null)
MONITOR_IPS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' monitor 2>/dev/null)

# Mostrar tabla
echo -e "${YELLOW}[1] Contenedores y sus direcciones IP:${NC}"
echo -e "${BLUE}┌─────────────────┬──────────┬──────────────────────────────────────────┐${NC}"
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "CONTAINER" "STATUS" "IPs"
echo -e "${BLUE}├─────────────────┼──────────┼──────────────────────────────────────────┤${NC}"

# Router
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "router" "$(docker ps --filter name=router --format '{{.Status}}' | cut -d' ' -f1)" "$ROUTER_IPS"
# Web
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "servidor_web" "$(docker ps --filter name=servidor_web --format '{{.Status}}' | cut -d' ' -f1)" "$WEB_IP"
# DB
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "base_datos" "$(docker ps --filter name=base_datos --format '{{.Status}}' | cut -d' ' -f1)" "$DB_IP"
# Atacante
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "atacante" "$(docker ps --filter name=atacante --format '{{.Status}}' | cut -d' ' -f1)" "$ATACANTE_IP"
# Monitor
printf "${BLUE}│${NC} %-15s ${BLUE}│${NC} %-8s ${BLUE}│${NC} %-40s ${BLUE}│${NC}\n" "monitor" "$(docker ps --filter name=monitor --format '{{.Status}}' | cut -d' ' -f1)" "$MONITOR_IPS"

echo -e "${BLUE}└─────────────────┴──────────┴──────────────────────────────────────────┘${NC}"
echo ""

# El resto del script (rutas, pings, etc.) sigue igual, pero también deberías quitar los -it de los comandos docker exec dentro del script para evitar problemas.