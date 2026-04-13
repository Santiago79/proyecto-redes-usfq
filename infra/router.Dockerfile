FROM alpine:latest

# Instalar herramientas (incluyendo bash)
RUN apk add --no-cache iptables iproute2 iperf3 git make bash

# Instalar wondershaper
RUN git clone https://github.com/magnific0/wondershaper.git && \
    cd wondershaper && \
    make install

COPY router-entrypoint.sh /router-entrypoint.sh
RUN chmod +x /router-entrypoint.sh

ENTRYPOINT ["/router-entrypoint.sh"]