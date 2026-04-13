#!/bin/bash

# =============================================================================
# Script de pruebas automáticas para infraestructura Docker
# Proyecto Redes - Ataques DDoS
# Versión: 2.1 (con detección automática de prefijo)
# =============================================================================

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contador de pruebas
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Detectar prefijo del proyecto
# Busca redes que terminen en "_1_red_publica"
PREFIX=$(docker network ls --format "{{.Name}}" | grep "_1_red_publica$" | head -1 | sed 's/_1_red_publica$//')
if [ -z "$PREFIX" ]; then
    # Si no encuentra, intenta con el nombre directo
    if docker network ls --format "{{.Name}}" | grep -q "^1_red_publica$"; then
        PREFIX=""
    else
        echo -e "${RED}✗ No se pudo detectar el prefijo de las redes${NC}"
        echo "  Redes disponibles:"
        docker network ls --format "{{.Name}}"
        exit 1
    fi
fi

# Construir nombres reales de redes
if [ -n "$PREFIX" ]; then
    RED_PUBLICA="${PREFIX}_1_red_publica"
    RED_PRIVADA="${PREFIX}_2_red_privada"
    RED_ATAQUE="${PREFIX}_3_red_ataque"
else
    RED_PUBLICA="1_red_publica"
    RED_PRIVADA="2_red_privada"
    RED_ATAQUE="3_red_ataque"
fi

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Encabezado
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    PRUEBAS DE INFRAESTRUCTURA - PROYECTO REDES              ║${NC}"
echo -e "${BLUE}║                        Monitor Multi-Interfaz + Panel de Control            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📌 Prefijo detectado: ${GREEN}${PREFIX:-ninguno}${NC}"
echo ""

# =============================================================================
# 1. VERIFICAR CONTENEDORES
# =============================================================================
echo -e "${YELLOW}[1] Verificando estado de contenedores...${NC}"

CONTAINERS=("router" "servidor_web" "base_datos" "atacante" "monitor" "phpmyadmin" "panel_control")
for container in "${CONTAINERS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        STATUS=$(docker ps --filter "name=$container" --format "{{.Status}}" | cut -d' ' -f1)
        if [ "$STATUS" = "Up" ]; then
            print_result 0 "Contenedor $container está Up"
        else
            print_result 1 "Contenedor $container existe pero no está corriendo (estado: $STATUS)"
        fi
    else
        print_result 1 "Contenedor $container no existe"
    fi
done
echo ""

# =============================================================================
# 2. VERIFICAR REDES (con nombre detectado)
# =============================================================================
echo -e "${YELLOW}[2] Verificando redes Docker...${NC}"

if docker network ls --format "{{.Name}}" | grep -q "^${RED_PUBLICA}$"; then
    print_result 0 "Red pública existe: $RED_PUBLICA"
else
    print_result 1 "Red pública NO existe: $RED_PUBLICA"
fi

if docker network ls --format "{{.Name}}" | grep -q "^${RED_PRIVADA}$"; then
    print_result 0 "Red privada existe: $RED_PRIVADA"
else
    print_result 1 "Red privada NO existe: $RED_PRIVADA"
fi

if docker network ls --format "{{.Name}}" | grep -q "^${RED_ATAQUE}$"; then
    print_result 0 "Red ataque existe: $RED_ATAQUE"
else
    print_result 1 "Red ataque NO existe: $RED_ATAQUE"
fi
echo ""

# =============================================================================
# 3. VERIFICAR IPs DE LOS CONTENEDORES
# =============================================================================
echo -e "${YELLOW}[3] Verificando direcciones IP...${NC}"

# Router IPs
ROUTER_IPS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' router 2>/dev/null)
if echo "$ROUTER_IPS" | grep -q "172.20.10.254"; then
    print_result 0 "Router tiene IP pública 172.20.10.254"
else
    print_result 1 "Router NO tiene IP pública 172.20.10.254"
fi

if echo "$ROUTER_IPS" | grep -q "172.20.20.254"; then
    print_result 0 "Router tiene IP privada 172.20.20.254"
else
    print_result 1 "Router NO tiene IP privada 172.20.20.254"
fi

if echo "$ROUTER_IPS" | grep -q "172.20.30.254"; then
    print_result 0 "Router tiene IP ataque 172.20.30.254"
else
    print_result 1 "Router NO tiene IP ataque 172.20.30.254"
fi

# Web IP
WEB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' servidor_web 2>/dev/null)
if [ "$WEB_IP" = "172.20.10.10" ]; then
    print_result 0 "Web tiene IP correcta: $WEB_IP"
else
    print_result 1 "Web IP incorrecta: $WEB_IP (esperada 172.20.10.10)"
fi

# DB IP
DB_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' base_datos 2>/dev/null)
if [ "$DB_IP" = "172.20.20.10" ]; then
    print_result 0 "Base de datos tiene IP correcta: $DB_IP"
else
    print_result 1 "Base de datos IP incorrecta: $DB_IP (esperada 172.20.20.10)"
fi

# Atacante IP
ATACANTE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' atacante 2>/dev/null)
if [ "$ATACANTE_IP" = "172.20.30.10" ]; then
    print_result 0 "Atacante tiene IP correcta: $ATACANTE_IP"
else
    print_result 1 "Atacante IP incorrecta: $ATACANTE_IP (esperada 172.20.30.10)"
fi

# Panel IP
PANEL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' panel_control 2>/dev/null)
if [ "$PANEL_IP" = "172.20.30.5" ]; then
    print_result 0 "Panel de control tiene IP correcta: $PANEL_IP"
else
    print_result 1 "Panel de control IP incorrecta: $PANEL_IP (esperada 172.20.30.5)"
fi

# Monitor multi-interfaz
MONITOR_IPS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' monitor 2>/dev/null)

if echo "$MONITOR_IPS" | grep -q "172.20.10.50"; then
    print_result 0 "Monitor tiene IP pública 172.20.10.50"
else
    print_result 1 "Monitor NO tiene IP pública 172.20.10.50"
fi

if echo "$MONITOR_IPS" | grep -q "172.20.20.50"; then
    print_result 0 "Monitor tiene IP privada 172.20.20.50"
else
    print_result 1 "Monitor NO tiene IP privada 172.20.20.50"
fi

if echo "$MONITOR_IPS" | grep -q "172.20.30.50"; then
    print_result 0 "Monitor tiene IP ataque 172.20.30.50"
else
    print_result 1 "Monitor NO tiene IP ataque 172.20.30.50"
fi

MONITOR_IP_COUNT=$(echo "$MONITOR_IPS" | wc -w)
if [ "$MONITOR_IP_COUNT" -eq 3 ]; then
    print_result 0 "Monitor tiene 3 interfaces de red"
else
    print_result 1 "Monitor tiene $MONITOR_IP_COUNT interfaces"
fi
echo ""

# =============================================================================
# 4. VERIFICAR tcp_syncookies (web)
# =============================================================================
echo -e "${YELLOW}[4] Verificando tcp_syncookies...${NC}"

SYN_COOKIES=$(docker exec servidor_web cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null | tr -d '\r')
if [ "$SYN_COOKIES" = "0" ]; then
    print_result 0 "tcp_syncookies=0 (vulnerable a SYN Flood)"
else
    print_result 1 "tcp_syncookies=$SYN_COOKIES (debería ser 0)"
fi
echo ""

# =============================================================================
# 5. VERIFICAR SERVICIOS HTTP
# =============================================================================
echo -e "${YELLOW}[5] Verificando servicios HTTP...${NC}"

# Web
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    print_result 0 "Servidor web HTTP 200 OK"
else
    print_result 1 "Servidor web código $HTTP_CODE"
fi

# phpMyAdmin
PMA_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 2>/dev/null)
if [ "$PMA_CODE" = "200" ]; then
    print_result 0 "phpMyAdmin HTTP 200 OK"
else
    print_result 1 "phpMyAdmin código $PMA_CODE"
fi

# Panel
PANEL_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 2>/dev/null)
if [ "$PANEL_CODE" = "200" ]; then
    print_result 0 "Panel de control HTTP 200 OK"
else
    print_result 1 "Panel de control código $PANEL_CODE"
fi
echo ""

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                              RESUMEN DE PRUEBAS                            ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC} Total pruebas: ${TOTAL_TESTS}                                                       ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} ${GREEN}Pruebas exitosas: ${PASSED_TESTS}${NC}                                                      ${BLUE}║${NC}"
echo -e "${BLUE}║${NC} ${RED}Pruebas fallidas: ${FAILED_TESTS}${NC}                                                      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${BLUE}📌 Servicios accesibles:${NC}"
echo -e "   • Web: ${GREEN}http://localhost:8080${NC}"
echo -e "   • phpMyAdmin: ${GREEN}http://localhost:8081${NC}"
echo -e "   • Panel: ${GREEN}http://localhost:5000${NC}"