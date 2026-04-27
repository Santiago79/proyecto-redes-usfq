# README2 Monitoreo y Cambios

## 1. Resumen ejecutivo

Este proyecto final implementa una simulacion de red empresarial segmentada con Docker para demostrar el impacto de ataques de denegacion de servicio y de carga maliciosa sobre servicios criticos. La topologia base se conserva: DMZ publica, red privada, red de ataque, router virtual y monitor multi-interfaz. Sobre esa infraestructura se mantiene una capa complementaria de observabilidad con Prometheus, Grafana y Loki.

El estado final simplificado conserva cuatro ataques para la presentacion:

- `SYN Flood`
- `UDP Flood`
- `HTTP Flood`
- `SQLi DoS`

Y conserva cuatro dashboards enfocados:

- `Red y Ataques`
- `Servidor Web`
- `Base de Datos`
- `Logs del Laboratorio`

## 2. Que se simplifico

Se eliminaron por completo:

- `ACK Flood`
- `Conntrack Killer`

Tambien se dejaron de publicar los dashboards:

- `Infraestructura General`
- `Academico Explicativo`

La infraestructura base no cambia. La simplificacion fue funcional y visual: menos ataques, menos paneles redundantes y una narrativa mas clara para la exposicion final.

## 3. Por que se simplifico

La version anterior era tecnicamente valida, pero mas amplia de lo necesario para una presentacion final corta. Mantener seis ataques y seis dashboards hacia mas dificil explicar el proyecto con claridad. La simplificacion mejora:

- foco tecnico
- facilidad de lectura en Grafana
- trazabilidad entre cada ataque y su metrica principal
- velocidad de demostracion en vivo

## 4. Por que no rompe la infraestructura propuesta

No se cambio:

- la topologia logica
- la segmentacion de redes
- el router virtual
- `EmpresaX`
- el `Panel de Control DDoS y Explotacion`
- el stack base de monitoreo

La topologia sigue siendo esencialmente la misma. Solo se redujo la complejidad visible del flujo final para que el proyecto final sea mas claro y defendible.

## 5. Topologia final y conservacion de la topologia original

Redes conservadas:

- `red_publica` -> `172.20.10.0/24`
- `red_privada` -> `172.20.20.0/24`
- `red_ataque` -> `172.20.30.0/24`
- `red_monitoreo` -> `172.20.40.0/24`

La topologia final sigue usando:

- `router` para conectar los segmentos del escenario
- `servidor_web` en la DMZ
- `base_datos` en la red privada
- `atacante` y `panel_control` en la red de ataque
- `monitor` como observador multi-interfaz
- Prometheus, Grafana, Loki y exporters como capa complementaria

No hubo cambios de puertos, redes logicas, roles de contenedores ni flujo principal.

## 6. Funcionamiento completo del proyecto

### Servicios principales

- `router`: conecta la red publica, privada y de ataque.
- `servidor_web`: publica `EmpresaX`, recibe trafico legitimo y es objetivo principal de `SYN Flood`, `UDP Flood` y `HTTP Flood`.
- `base_datos`: almacena credenciales y consultas del sitio; es objetivo principal de `SQLi DoS`.
- `atacante`: ejecuta los scripts de los cuatro ataques finales.
- `monitor`: mantiene la observacion de las tres redes operativas del escenario.
- `panel_control`: expone botones y endpoints para lanzar y detener ataques.
- `phpmyadmin`: acceso auxiliar para la base de datos.

### Servicios de observabilidad

- `prometheus`: hace scraping de exporters y endpoints de metricas.
- `grafana`: visualiza dashboards provisionados automaticamente.
- `loki`: almacena logs.
- `promtail`: recolecta logs Docker y los envia a Loki.
- `blackbox_exporter`: mide disponibilidad y latencia HTTP/TCP.
- `apache_exporter`: lee `mod_status` del web y expone accesos, workers y estado Apache.
- `mysqld_exporter`: expone metadatos y contadores internos de MySQL.
- `cadvisor`: aporta metricas de contenedores desde Docker.
- `docker_metrics_exporter`: exporter propio que consulta Docker y complementa CPU, memoria, red, uptime y `SYN_RECV`.

## 7. Inventario final de ataques

| Ataque | Objetivo | Metricas clave | Estado final |
|---|---|---|---|
| `SYN Flood` | pila TCP del web | paquetes por segundo, `NET I/O`, `lab_container_tcp_syn_recv_connections` | Conservado |
| `UDP Flood` | ancho de banda y trafico | paquetes por segundo, `NET I/O` | Conservado |
| `HTTP Flood` | procesamiento del servidor web | CPU del web, latencia HTTP, throughput | Conservado |
| `SQLi DoS` | base de datos MySQL | conexiones MySQL, ritmo de consultas | Conservado |

Ataques eliminados de forma intencional:

- `ACK Flood`
- `Conntrack Killer`

Ya no aparecen en el panel, scripts, validaciones, dashboards ni documentacion activa.

## 8. Arquitectura de monitoreo y pipeline completo

### 8.1 Prometheus

`Prometheus` es el colector central. Consulta periodicamente endpoints `/metrics` o exporters dedicados. Guarda series temporales y permite consultas `PromQL`.

Fuentes relevantes:

- `panel_control`: expone `attack_active`, `attack_launch_total` y timestamps de inicio y stop.
- `docker_metrics_exporter`: expone estado y consumo por contenedor, incluyendo `lab_container_tcp_syn_recv_connections`.
- `blackbox_exporter`: expone `probe_success` y `probe_duration_seconds` para HTTP y TCP.
- `apache_exporter`: expone `apache_accesses_total`, `apache_workers`, `apache_scoreboard`, `apache_up`.
- `mysqld_exporter`: expone `mysql_up`, `mysql_global_status_questions`, `mysql_global_status_threads_connected` y contadores relacionados.
- `cadvisor`: mantiene una referencia adicional de contenedores.
- `prometheus`: tambien se auto-monitorea.

### 8.2 Grafana

`Grafana` no recolecta datos directamente. Consulta datasources ya provisionados:

- `Prometheus` para metricas
- `Loki` para logs

Dashboards finales:

- `Red y Ataques`
- `Servidor Web`
- `Base de Datos`
- `Logs del Laboratorio`

### 8.3 Loki

`Loki` almacena logs del laboratorio. No scrapea Prometheus ni genera metricas del panel. Su rol es centralizar eventos textuales y permitir correlacion temporal.

### 8.4 Promtail

`Promtail` sigue los logs de contenedores Docker, los etiqueta y los envia a `Loki`. Asi Grafana puede consultar los streams por etiquetas como `compose_service`, `container` o `stream`.

### 8.5 Blackbox Exporter

Realiza probes activos:

- HTTP a `EmpresaX`
- TCP a MySQL

Entrega a `Prometheus`:

- exito o fallo del probe
- latencia de la peticion

Es la base de las metricas de disponibilidad y latencia visibles en Grafana.

### 8.6 Apache Exporter

Consulta el endpoint `mod_status` del servidor Apache dentro del contenedor web y expone:

- estado del exporter y del web
- accesos acumulados
- workers / scoreboard

`Prometheus` scrapea esas metricas y `Grafana` las usa para throughput HTTP y observacion del web.

### 8.7 mysqld_exporter

Se autentica contra MySQL y expone:

- `mysql_up`
- conexiones activas
- ritmo de consultas
- contadores de trafico y actividad del motor

`Prometheus` lo scrapea y `Grafana` lo usa en el dashboard `Base de Datos`.

### 8.8 docker_metrics_exporter

Es un exporter propio que sigue siendo necesario porque en Docker Desktop / WSL algunos contadores de red de `cAdvisor` no siempre son suficientemente claros para la demostracion. Este exporter:

- consulta la API de Docker
- lee `stats` de contenedores
- expone CPU, memoria, red, uptime y estado por contenedor
- entra al contenedor `servidor_web` y ejecuta `ss -tan state syn-recv` para obtener una metrica real de conexiones `SYN_RECV`

Metrica nueva relevante:

- `lab_container_tcp_syn_recv_connections{service="web"}`

Esto permite mostrar de forma directa la presion de conexiones durante `SYN Flood`.

### 8.9 cAdvisor

Sigue activo como fuente complementaria de metricas de contenedor. No se elimino porque sigue aportando visibilidad de runtime. Sin embargo, el dashboard final depende principalmente de `docker_metrics_exporter` para las series que interesan en la exposicion.

## 9. Dashboards finales

### Red y Ataques

Datasource: `Prometheus`

Paneles:

- `Ataques Activos`
- `Estado por Ataque`
- `Paquetes por Segundo`
- `NET I/O del Atacante hacia la DMZ`

Uso principal:

- `SYN Flood`
- `UDP Flood`

### Servidor Web

Datasource: `Prometheus`

Paneles:

- `CPU del Contenedor Web`
- `Latencia HTTP`
- `Throughput HTTP`
- `Conexiones SYN_RECV en el Web`

Uso principal:

- `HTTP Flood`
- `SYN Flood`

### Base de Datos

Datasource: `Prometheus`

Paneles:

- `MySQL Disponible`
- `Conexiones MySQL`
- `Ritmo de Consultas`

Uso principal:

- `SQLi DoS`

### Logs del Laboratorio

Datasource: `Loki`

Paneles:

- guia de correlacion
- logs web
- logs MySQL
- logs del panel

## 10. Archivos afectados en esta simplificacion

### Modificados

- `panel/app.py`
- `panel/templates/index.html`
- `scripts/linux/common.sh`
- `scripts/linux/attack.sh`
- `scripts/linux/validate.sh`
- `scripts/windows/Common.ps1`
- `scripts/windows/validate.ps1`
- `monitoring/docker_metrics_exporter/app.py`
- `monitoring/grafana/dashboards/red-ataques.json`
- `monitoring/grafana/dashboards/servidor-web.json`
- `monitoring/grafana/dashboards/base-datos.json`
- `monitoring/grafana/dashboards/logs-laboratorio.json`
- `docs/arquitectura.md`
- `docs/monitoreo.md`
- `docs/linux.md`
- `docs/windows.md`
- `docs/pruebas.md`
- `CHANGELOG_CODEX.md`

### Eliminados

- `monitoring/grafana/dashboards/infraestructura-general.json`
- `monitoring/grafana/dashboards/academico-explicativo.json`

### Creados

- `README.md`
- `README2_MONITOREO_CAMBIOS.md`
- `CONTEXTO_CHATGPT_CAMBIOS_SIMPLIFICACION.md`

## 11. Instrucciones de uso

### Linux

```bash
bash scripts/linux/up.sh
bash scripts/linux/validate.sh
bash scripts/linux/attack.sh syn
bash scripts/linux/attack.sh udp
bash scripts/linux/attack.sh http
bash scripts/linux/attack.sh sqli_dos
bash scripts/linux/stop_attacks.sh
```

### Windows

```powershell
scripts\windows\up.ps1
scripts\windows\validate.ps1
scripts\windows\attack.ps1 -Attack syn
scripts\windows\attack.ps1 -Attack udp
scripts\windows\attack.ps1 -Attack http
scripts\windows\attack.ps1 -Attack sqli_dos
scripts\windows\stop_attacks.ps1
```

## 12. Validacion y estado final

Lo que debe confirmarse en la validacion final:

- solo existen cuatro ataques
- el panel ya no muestra `ACK Flood` ni `Conntrack Killer`
- Grafana solo publica cuatro dashboards
- `Logs del Laboratorio` sigue funcionando
- Prometheus, Grafana y Loki siguen activos
- la topologia no cambia
- la metrica `lab_container_tcp_syn_recv_connections` queda disponible para `SYN Flood`

## 13. Conclusiones tecnicas

La simplificacion no debilita el proyecto. Lo vuelve mas claro. El escenario sigue demostrando:

- presion sobre la pila TCP con `SYN Flood`
- saturacion de trafico con `UDP Flood`
- saturacion de procesamiento HTTP con `HTTP Flood`
- impacto directo sobre MySQL con `SQLi DoS`

La observabilidad sigue siendo suficiente y correcta porque mantiene metricas de red, servicio web, base de datos y logs, pero ahora con una narrativa de exposicion mucho mas directa.

