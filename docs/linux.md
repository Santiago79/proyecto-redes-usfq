# Uso en Linux

## Requisitos

- Docker Engine
- Docker Compose v2
- `bash`
- `curl`

## Levantar el laboratorio

```bash
bash scripts/scripts_captura_ataques/linux/up.sh
```

## Validar el entorno

```bash
bash scripts/scripts_captura_ataques/linux/validate.sh
```

La validacion comprueba:

- salud de contenedores clave
- `tcp_syncookies=0`
- disponibilidad de EmpresaX, panel, Grafana y Loki
- targets `up` en Prometheus
- dashboards simplificados provisionados en Grafana
- presencia de metricas del laboratorio
- ausencia de `ACK Flood` y `Conntrack Killer`

## Generar trafico legitimo

```bash
bash scripts/scripts_captura_ataques/linux/generate_legitimate_traffic.sh 60 1
```

Salida por defecto:

- `analisis/trafico_legitimo.csv`

## Capturas Wireshark

```bash
bash scripts/scripts_captura_ataques/linux/start_capture.sh red_publica syn
bash scripts/scripts_captura_ataques/linux/stop_capture.sh
```

La salida queda en:

- `analisis/pcaps`

Modos disponibles:

- `red_publica`
- `red_privada`
- `red_ataque`
- `todas`

Ejemplos utiles:

- `bash scripts/scripts_captura_ataques/linux/start_capture.sh red_publica syn`
- `bash scripts/scripts_captura_ataques/linux/start_capture.sh red_ataque udp`
- `bash scripts/scripts_captura_ataques/linux/start_capture.sh red_publica http`
- `bash scripts/scripts_captura_ataques/linux/start_capture.sh red_privada sqli`

Capturas automatizadas de 45 segundos:

```bash
bash scripts/scripts_captura_ataques/linux/capture_attack.sh syn 45
bash scripts/scripts_captura_ataques/linux/capture_attack.sh udp 45
bash scripts/scripts_captura_ataques/linux/capture_attack.sh http 45
bash scripts/scripts_captura_ataques/linux/capture_attack.sh sqli_dos 45
```

Corrida completa:

```bash
bash scripts/scripts_captura_ataques/linux/capture_all_attacks.sh 45
```

Resumen:

- `analisis/pcaps/capturas_45s_resumen.txt`

## Lanzar ataques

```bash
bash scripts/scripts_captura_ataques/linux/attack.sh udp
bash scripts/scripts_captura_ataques/linux/attack.sh syn
bash scripts/scripts_captura_ataques/linux/attack.sh http
bash scripts/scripts_captura_ataques/linux/attack.sh sqli_dos
```

Ataques finales permitidos:

- `udp`
- `syn`
- `http`
- `sqli_dos`

## Detener ataques

```bash
bash scripts/scripts_captura_ataques/linux/stop_attacks.sh
```

## Reiniciar el laboratorio

```bash
bash scripts/scripts_captura_ataques/linux/reset_lab.sh
```

Este comando hace `down -v --remove-orphans` y luego `up -d --build`.

## Consultar logs y metricas

```bash
bash scripts/scripts_captura_ataques/linux/logs.sh
bash scripts/scripts_captura_ataques/linux/logs.sh panel_control
bash scripts/scripts_captura_ataques/linux/metrics.sh
```

## URLs utiles

- `http://localhost:8080`
- `http://localhost:5000`
- `http://localhost:3000`
- `http://localhost:9090`
- `http://localhost:8081`

## Troubleshooting rapido

- Si Docker pide privilegios, agrega tu usuario al grupo `docker` o ejecuta con el mecanismo habitual de tu distribucion.
- Si `Grafana` no muestra los cuatro dashboards finales, reejecuta `bash scripts/scripts_captura_ataques/linux/validate.sh` y revisa `docker compose -f infra/docker-compose.yml logs grafana prometheus`.
- Si un ataque queda activo, usa `bash scripts/scripts_captura_ataques/linux/stop_attacks.sh`.
- Si quieres validar una captura, abre el archivo `.pcapng` generado en `analisis/pcaps` con Wireshark en el host.
