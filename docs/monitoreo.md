# Monitoreo y observabilidad

## Objetivo final

El monitoreo quedo simplificado para la presentacion final. Se mantiene la misma infraestructura de observabilidad, pero Grafana publica solo los paneles realmente necesarios para demostrar de forma clara el efecto de los cuatro ataques finales:

- `SYN Flood`
- `UDP Flood`
- `HTTP Flood`
- `SQLi DoS`

## Pipeline completo de observabilidad

### Prometheus

`Prometheus` es el recolector central. Hace scraping periodico de exporters y endpoints `/metrics`, guarda series temporales y resuelve las consultas `PromQL` que luego usa Grafana.

### Grafana

`Grafana` es la capa de visualizacion. No recolecta datos por si mismo. Consulta dos datasources provisionados:

- `Prometheus` para metricas
- `Loki` para logs

### Loki

`Loki` almacena logs estructurados del laboratorio. Permite correlacionar eventos del panel, del web y de MySQL durante las pruebas.

### Promtail

`Promtail` lee los logs de contenedores Docker, agrega etiquetas y los envia a `Loki`.

## Exporters e integraciones activas

| Componente | Que extrae | Desde donde | Como llega a Grafana |
|---|---|---|---|
| `blackbox_exporter` | disponibilidad HTTP/TCP y latencia | probes activos contra `EmpresaX` y MySQL | Prometheus scrapea el exporter y Grafana consulta Prometheus |
| `apache_exporter` | `apache_up`, accesos, workers, scoreboard | `mod_status` del contenedor web | Prometheus scrapea el exporter y Grafana consulta Prometheus |
| `mysqld_exporter` | `mysql_up`, conexiones, ritmo de consultas y estado del motor | servidor MySQL | Prometheus scrapea el exporter y Grafana consulta Prometheus |
| `docker_metrics_exporter` | CPU, memoria, red, uptime, estado y `SYN_RECV` por contenedor | API Docker y `ss -tan state syn-recv` dentro del web | Prometheus scrapea el exporter y Grafana consulta Prometheus |
| `cadvisor` | metricas complementarias de runtime Docker | engine Docker | Prometheus scrapea cAdvisor y Grafana puede consultarlo via Prometheus |
| `panel_control` | `attack_active`, `attack_launch_total`, timestamps | backend Flask del panel | Prometheus scrapea el panel y Grafana consulta Prometheus |
| `promtail` | logs etiquetados | stdout/stderr de contenedores | Promtail envia a Loki y Grafana consulta Loki |

## Dashboards finales publicados

### Red y Ataques

Datasource: `Prometheus`

Paneles finales:

- `Ataques Activos`
- `Estado por Ataque`
- `Paquetes por Segundo`
- `NET I/O del Atacante hacia la DMZ`

Explica principalmente:

- `SYN Flood`
- `UDP Flood`

### Servidor Web

Datasource: `Prometheus`

Paneles finales:

- `CPU del Contenedor Web`
- `Latencia HTTP`
- `Throughput HTTP`
- `Conexiones SYN_RECV en el Web`

La metrica `SYN_RECV` viene de `docker_metrics_exporter` y se obtiene ejecutando `ss -tan state syn-recv` dentro del contenedor `servidor_web`. Es una metrica real y directa para evidenciar presion sobre conexiones TCP durante `SYN Flood`.

### Base de Datos

Datasource: `Prometheus`

Paneles finales:

- `MySQL Disponible`
- `Conexiones MySQL`
- `Ritmo de Consultas`

Explica principalmente `SQLi DoS`.

### Logs del Laboratorio

Datasource: `Loki`

Paneles finales:

- guia de correlacion
- logs del web
- logs de MySQL
- logs del panel

## Metricas clave para la exposicion final

| Ataque | Metrica clave | Motivo |
|---|---|---|
| `SYN Flood` | paquetes por segundo + `lab_container_tcp_syn_recv_connections` | muestra presion de red y acumulacion de conexiones TCP pendientes |
| `UDP Flood` | paquetes por segundo + `NET I/O` | muestra saturacion de trafico y ancho de banda |
| `HTTP Flood` | CPU web + latencia HTTP + throughput | muestra saturacion del procesamiento HTTP |
| `SQLi DoS` | `mysql_global_status_questions` + `mysql_global_status_threads_connected` | muestra impacto directo sobre el motor MySQL |

## Metricas relevantes que siguen activas

- `attack_active`
- `attack_launch_total`
- `lab_container_cpu_percent`
- `lab_container_network_rx_bytes_total`
- `lab_container_network_tx_bytes_total`
- `lab_container_network_rx_packets_total`
- `lab_container_network_tx_packets_total`
- `lab_container_tcp_syn_recv_connections`
- `probe_success`
- `probe_duration_seconds`
- `apache_accesses_total`
- `mysql_up`
- `mysql_global_status_questions`
- `mysql_global_status_threads_connected`

## Lo que ya no se publica

Grafana ya no publica:

- `Infraestructura General`
- `Academico Explicativo`

Esos dashboards se retiraron para reducir ruido visual. No se eliminaron exporters utiles ni la capacidad tecnica de observacion del proyecto final.

## Decision tecnica importante

No se elimino `cAdvisor`, `Prometheus`, `Grafana`, `Loki`, `Promtail` ni los exporters utiles. La simplificacion fue visual y funcional, no arquitectonica. El pipeline sigue siendo completo, pero mas facil de explicar.
