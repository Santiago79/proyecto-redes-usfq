FROM mysql:8.0-debian

# Instalar iproute2 y iperf3
RUN apt-get update && apt-get install -y iproute2 iperf3 && rm -rf /var/lib/apt/lists/*