# Validaciones y pruebas ejecutadas

## Contexto de validacion

- Fecha local de trabajo: `2026-04-21`
- Zona horaria local: `America/Bogota`
- Muchos logs de contenedores quedaron en UTC y por eso aparecen como `2026-04-22T...Z`

## Comandos ejecutados

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

### Ataques y evidencias

```powershell
curl.exe http://localhost:5000/atacar/http
curl.exe http://localhost:5000/atacar/sqli_dos
curl.exe http://localhost:5000/atacar/udp
curl.exe http://localhost:5000/atacar/syn
curl.exe http://localhost:5000/atacar/ack
curl.exe http://localhost:5000/atacar/conntrack
curl.exe http://localhost:5000/atacar/stop
```

## Resultados confirmados

### Estado de servicios

- `servidor_web`: healthy
- `base_datos`: healthy
- `panel_control`: healthy
- `router`: healthy
- `prometheus`: up
- `grafana`: up
- `loki`: ready
- `apache_exporter`: up
- `mysqld_exporter`: up
- `blackbox_exporter`: up
- `docker_metrics_exporter`: up
- `cadvisor`: up

### Dashboards en Grafana

Se confirmo la provision automatica de:

- `Infraestructura General`
- `Servidor Web`
- `Base de Datos`
- `Red y Ataques`
- `Academico Explicativo`
- `Logs del Laboratorio`

### Evidencias tecnicas observadas

- `tcp_syncookies` dentro de `servidor_web` = `0`
- `attack_active` en cero despues de detener ataques
- `HTTP Flood` produjo aproximadamente `119.24 req/s` en `rate(apache_accesses_total[30s])`
- `SQLi DoS` produjo aproximadamente `3.8577 q/s` en `rate(mysql_global_status_questions[30s])`
- `UDP Flood` genero un delta de `345768` paquetes TX en `atacante` durante una ventana controlada de 10 s
- `SYN Flood` genero un delta de `133264` paquetes TX en `atacante` durante una ventana controlada de 10 s
- `ACK Flood` genero un delta de `180939` paquetes TX en `atacante` durante una ventana controlada de 10 s
- `Conntrack Killer` genero un delta de `160101` paquetes TX en `atacante` durante una ventana controlada de 10 s

## Scripts comprobados

### Windows

- `scripts/windows/validate.ps1`
- `scripts/windows/metrics.ps1`
- `scripts/windows/attack.ps1`
- `scripts/windows/stop_attacks.ps1`
- `scripts/windows/generate_legitimate_traffic.ps1`
- `scripts/windows/logs.ps1`

### Linux

- Validacion funcional: `scripts/linux/validate.sh`
- Validacion sintactica: `bash -n` sobre los scripts de `scripts/linux`

## Limitaciones pendientes

- La demostracion de degradacion severa puede variar segun la capacidad del host.
- En Docker Desktop / WSL, algunos contadores de red dependen del exporter complementario propio para verse con claridad.
- No se generaron capturas visuales porque no se modificaron las interfaces de frontend.
