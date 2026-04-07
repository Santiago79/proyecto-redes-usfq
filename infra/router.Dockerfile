
FROM alpine:latest

# Instalar herramientas necesarias para configurar el router (iptables para NAT y iproute2 para routing)
RUN apk add --no-cache iptables iproute2

# Habilitar IP forwarding de forma permanente 
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Copiar el script de entrada al contenedor
COPY router-entrypoint.sh /router-entrypoint.sh

# Permisos de ejecución al script
RUN chmod +x /router-entrypoint.sh

# Definir el punto de entrada 
ENTRYPOINT ["/router-entrypoint.sh"]