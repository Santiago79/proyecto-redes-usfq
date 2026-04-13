FROM nicolaka/netshoot:latest

# Instalar mysql-client y iperf3
RUN apk add --no-cache mysql-client iperf3