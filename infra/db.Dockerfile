FROM mysql:8.0-debian

# Instalar la herramienta 'ip' para poder configurar el enrutamiento
RUN apt-get update && apt-get install -y iproute2