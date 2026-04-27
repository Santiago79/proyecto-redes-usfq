#!/bin/sh

set -eu

for _ in 1 2 3; do
  pkill -x hping3 2>/dev/null || true
  pkill -f 'http://172.20.10.10 -o /dev/null' 2>/dev/null || true
  pkill -f 'curl -s http://172.20.10.10 -o /dev/null' 2>/dev/null || true
  pkill -f 'login.php' 2>/dev/null || true
  pkill -f 'SLEEP(5)' 2>/dev/null || true
  pkill -f 'curl -s -X POST' 2>/dev/null || true
  iptables -F OUTPUT 2>/dev/null || true
  sleep 1
done

exit 0
