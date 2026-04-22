# Uso en Linux

## Requisitos

- Docker Engine
- Docker Compose v2
- `bash`
- `curl`

## Levantar el laboratorio

```bash
bash scripts/linux/up.sh
```

## Validar el entorno

```bash
bash scripts/linux/validate.sh
```

La validacion comprueba:

- salud de contenedores clave
- `tcp_syncookies=0`
- disponibilidad de EmpresaX, panel, Grafana y Loki
- targets `up` en Prometheus
- dashboards provisionados en Grafana
- presencia de metricas del laboratorio

## Generar trafico legitimo

```bash
bash scripts/linux/generate_legitimate_traffic.sh 60 1
```

Salida por defecto:

- `analisis/trafico_legitimo.csv`

## Lanzar ataques

```bash
bash scripts/linux/attack.sh udp
bash scripts/linux/attack.sh syn
bash scripts/linux/attack.sh ack
bash scripts/linux/attack.sh conntrack
bash scripts/linux/attack.sh http
bash scripts/linux/attack.sh sqli_dos
```

## Detener ataques

```bash
bash scripts/linux/stop_attacks.sh
```

## Reiniciar el laboratorio

```bash
bash scripts/linux/reset_lab.sh
```

Este comando hace `down -v --remove-orphans` y luego `up -d --build`.

## Consultar logs y metricas

```bash
bash scripts/linux/logs.sh
bash scripts/linux/logs.sh panel_control
bash scripts/linux/metrics.sh
```

## URLs utiles

- `http://localhost:8080`
- `http://localhost:5000`
- `http://localhost:3000`
- `http://localhost:9090`
- `http://localhost:8081`

## Troubleshooting rapido

- Si Docker pide privilegios, agrega tu usuario al grupo `docker` o ejecuta con el mecanismo habitual de tu distribucion.
- Si `Grafana` no muestra dashboards, reejecuta `bash scripts/linux/validate.sh` y revisa `docker compose -f infra/docker-compose.yml logs grafana prometheus`.
- Si un ataque queda activo, usa `bash scripts/linux/stop_attacks.sh`.
