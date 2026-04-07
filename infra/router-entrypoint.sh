#!/bin/sh

# Habilitar IP forwarding dinámicamente (inmediatamente, sin reiniciar)
# El comando 'sysctl -w' cambia parámetros del kernel en tiempo real
sysctl -w net.ipv4.ip_forward=1

# Mostrar que el router está activo (
echo "Router iniciado - IP forwarding habilitado"

# Mostrar las interfaces de red disponibles
echo "Interfaces de red disponibles:"
ip addr show

# Mantener el contenedor vivo
# Sin esto, el contenedor se detendría inmediatamente después de ejecutar el script
tail -f /dev/null