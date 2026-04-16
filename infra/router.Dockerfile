FROM alpine:latest

RUN apk add --no-cache iptables iproute2 iperf3 bash

COPY router-entrypoint.sh /router-entrypoint.sh
RUN chmod +x /router-entrypoint.sh

ENTRYPOINT ["/router-entrypoint.sh"]