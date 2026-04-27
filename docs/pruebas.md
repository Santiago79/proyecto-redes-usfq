# Validaciones y pruebas ejecutadas

## Objetivo de esta fase

Validar que la simplificacion final no rompe el proyecto y deja solo:

- 4 ataques: `SYN Flood`, `UDP Flood`, `HTTP Flood`, `SQLi DoS`
- 4 dashboards: `Red y Ataques`, `Servidor Web`, `Base de Datos`, `Logs del Laboratorio`

## Comandos de validacion previstos

### Estado general

```powershell
docker compose -f infra/docker-compose.yml ps
curl.exe -s http://localhost:9090/api/v1/targets
curl.exe -s -u admin:admin http://localhost:3000/api/search?query=
docker exec servidor_web cat /proc/sys/net/ipv4/tcp_syncookies
```

### Scripts de validacion

```powershell
powershell -ExecutionPolicy Bypass -File scripts/windows/validate.ps1
```

```bash
bash scripts/linux/validate.sh
```

### Lanzamiento de ataques finales

```powershell
curl.exe http://localhost:5000/atacar/http
curl.exe http://localhost:5000/atacar/sqli_dos
curl.exe http://localhost:5000/atacar/udp
curl.exe http://localhost:5000/atacar/syn
curl.exe http://localhost:5000/atacar/stop
```

## Criterios de exito

- `servidor_web`, `base_datos`, `panel_control` y `router` operativos
- `prometheus`, `grafana` y `loki` operativos
- targets `up` en Prometheus
- solo 4 dashboards publicados en Grafana
- metrica `attack_active` sin `ack` ni `conntrack`
- panel sin botones de `ACK Flood` ni `Conntrack Killer`
- metrica `lab_container_tcp_syn_recv_connections` disponible

## Evidencias tecnicas que deben observarse

- `SYN Flood`: aumento en paquetes por segundo y en `lab_container_tcp_syn_recv_connections`
- `UDP Flood`: aumento claro en `NET I/O` y paquetes por segundo
- `HTTP Flood`: aumento de CPU web, latencia HTTP y throughput
- `SQLi DoS`: aumento en consultas y conexiones MySQL

## Resultado de esta revision

Durante esta fase de simplificacion se dejaron alineados:

- panel backend
- panel frontend
- scripts Linux
- scripts Windows
- dashboards de Grafana
- validaciones automaticas
- documentacion tecnica

Si el daemon de Docker no esta disponible en el host al momento de la revision, la revalidacion operativa debe repetirse una vez vuelva a estar levantado Docker Desktop o Docker Engine.
