# Monitoreo y observabilidad

## Meta

Hacer visible el impacto de los ataques sobre contenedores, servicios web, base de datos, red y logs, sin alterar la topologia base del laboratorio.

## Stack implementado

| Componente | Uso | Motivo tecnico |
|---|---|---|
| Grafana | Visualizacion | Presentacion academica y correlacion temporal |
| Prometheus | Recoleccion | Consultas PromQL y scraping continuo |
| cAdvisor | Contenedores | Base de metricas de runtime Docker |
| docker_metrics_exporter | Complemento propio | Mejor fidelidad por contenedor en Docker Desktop / WSL |
| Blackbox Exporter | Probes | Latencia HTTP y disponibilidad TCP |
| apache_exporter | Web | `mod_status`, workers, accesos |
| mysqld_exporter | MySQL | Estado y actividad del motor |
| Loki | Logs | Consulta centralizada de eventos |
| Promtail | Recoleccion de logs | Envio de logs de contenedores hacia Loki |

## Datasources provisionados

- `Prometheus`
- `Loki`

Grafana se provisiona automaticamente desde:

- `monitoring/grafana/provisioning/datasources/datasources.yml`
- `monitoring/grafana/provisioning/dashboards/dashboards.yml`

## Dashboards provisionados

| Dashboard | UID | Enfoque |
|---|---|---|
| Infraestructura General | `infra-general` | CPU, memoria, estado y red por contenedor |
| Servidor Web | `servidor-web` | disponibilidad, latencia, workers y accesos |
| Base de Datos | `base-datos` | salud, conexiones y consultas |
| Red y Ataques | `red-ataques` | trafico, eventos del panel y correlacion de ataques |
| Academico Explicativo | `academico-explicativo` | capa OSI, TCP/IP, objetivo y sintoma observable |
| Logs del Laboratorio | `logs-laboratorio` | eventos y logs correlacionados |

## Metricas relevantes

### Contenedores

- `lab_container_up`
- `lab_container_cpu_percent`
- `lab_container_memory_usage_bytes`
- `lab_container_memory_limit_bytes`
- `lab_container_network_rx_bytes_total`
- `lab_container_network_tx_bytes_total`
- `lab_container_network_rx_packets_total`
- `lab_container_network_tx_packets_total`
- `lab_container_network_rx_errors_total`
- `lab_container_network_tx_errors_total`
- `lab_container_network_rx_dropped_total`
- `lab_container_network_tx_dropped_total`
- `lab_container_uptime_seconds`

### Web

- `probe_success`
- `probe_duration_seconds`
- `apache_up`
- `apache_accesses_total`
- `apache_workers`
- `apache_scoreboard`

### Base de datos

- `mysql_up`
- `mysql_global_status_questions`
- `mysql_global_status_threads_connected`
- `mysql_global_status_aborted_connects`
- `mysql_global_status_bytes_received`
- `mysql_global_status_bytes_sent`

### Panel y ataques

- `attack_launch_total`
- `attack_active`
- `attack_last_start_timestamp_seconds`
- `attack_last_stop_timestamp_seconds`

## Logs

Promtail recoge logs de contenedores Docker y los envia a Loki. En Grafana se pueden filtrar por etiquetas como:

- `compose_service`
- `service_name`
- `container`
- `stream`

Esto permite correlacionar el lanzamiento y el stop de ataques con el comportamiento del web, la DB y el panel.

## Limitacion conocida y decision adoptada

`cAdvisor` se mantuvo porque aporta valor real, pero en Docker Desktop / WSL no siempre refleja con suficiente detalle algunos contadores de red por contenedor. Para no cambiar el laboratorio y aun asi poder demostrar el impacto de los floods, se agrego `docker_metrics_exporter`, que consulta Docker y los contadores de interfaz internos del contenedor.

## Lo que no se agrego y por que

- No se agrego `node_exporter`.
- Motivo: el foco del laboratorio es la red simulada y los contenedores del escenario, no el host del estudiante.
- Esto reduce ruido y mantiene la demo alineada con el objetivo academico.
