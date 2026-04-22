# README2_MONITOREO_CAMBIOS

## 1. Resumen ejecutivo

Este proyecto implementa un laboratorio academico de simulacion de red empresarial con Docker para demostrar ataques de denegacion de servicio, observar sus efectos y correlacionar el impacto con metricas tecnicas y logs. La topologia base se mantiene con una DMZ publica, una red privada, una red de ataque, un router virtual y un monitor multi-interfaz.

La version auditada y corregida conserva los ataques existentes, conserva las dos interfaces visuales principales y agrega una capa complementaria de observabilidad con Grafana, Prometheus, Loki, exporters de servicios y un exporter propio de metricas de contenedores. El resultado final permite medir CPU, memoria, red, disponibilidad, latencia HTTP, actividad de MySQL, eventos del panel y logs del laboratorio sin rediseñar la arquitectura academica original.

## 2. Estado inicial del repositorio

### Que ya funcionaba

- La topologia logica principal ya existia y era valida como laboratorio academico.
- Existian los contenedores `router`, `servidor_web`, `base_datos`, `atacante`, `monitor`, `phpmyadmin` y `panel_control`.
- Ya existia la segmentacion en tres subredes: publica, privada y de ataque.
- Ya existian las dos interfaces visuales clave: `EmpresaX` y `Panel de Control DDoS y Explotacion`.
- El panel ya mostraba los seis ataques esperados: `UDP Flood`, `SYN Flood`, `ACK Flood`, `Conntrack Killer`, `HTTP Flood` y `SQLi DoS`.

### Que no funcionaba o era fragil

- `login.php` fallaba por ausencia de `mysqli` en el contenedor web.
- `SQLi DoS` no impactaba correctamente a MySQL porque el servicio web no estaba listo de forma estable.
- La validacion heredada no cubria Grafana, Prometheus ni exporters reales.
- El boton `DETENER TODOS LOS ATAQUES` era fragil y dejaba procesos persistentes de `curl` y `sh`.
- La documentacion del repositorio era parcial, incoherente y el `README.md` estaba truncado.
- No existia una pila de monitoreo provisionada de forma reproducible.

### Que estaba incompleto

- No habia dashboards de Grafana provisionados automaticamente.
- No habia Prometheus scrapeando servicios reales del laboratorio.
- No habia monitoreo consistente del panel, del web, de MySQL ni de logs.
- No habia scripts separados y claros para Linux y Windows.

### Inconsistencias detectadas

- La documentacion heredada hablaba de `NGINX`, pero la implementacion real del web es `Apache + PHP`.
- Algunas descripciones antiguas de topologia usaban otras IPs de router, pero el compose real usa `.254` como gateway en las tres redes.
- La interfaz `EmpresaX` conserva un texto historico de `NGINX / Alpine`, pero el contenedor real hoy corre sobre `Apache/PHP`. Se mantuvo asi para preservar la interfaz visual existente.
- El valor visible y documentado de `tcp_syncookies` no siempre coincidia con el runtime; se corrigio para quedar efectivamente en `0`.

### Elementos preservados deliberadamente

- La topologia logica DMZ / red privada / red de ataque.
- El router virtual como pivote entre las tres subredes.
- El monitor multi-interfaz.
- Los nombres visibles `EmpresaX` y `Panel de Control DDoS y Explotacion`.
- La lista completa de ataques.
- La distribucion visual del panel y de EmpresaX.

## 3. Cambios implementados

### Archivos modificados

- `infra/docker-compose.yml`
- `infra/router-entrypoint.sh`
- `infra/web-entrypoint.sh`
- `infra/db_init/init.sql`
- `panel/app.py`
- `panel/requirements.txt`
- `monitoring/docker_metrics_exporter/app.py`
- `monitoring/prometheus/prometheus.yml`
- `scripts/validacion.sh`
- `scripts/generar_trafico.sh`
- `scripts/ataque_syn_flood.sh`
- `scripts/ataque_udp_flood.sh`
- `README.md`

### Archivos creados

- `infra/web.Dockerfile`
- `infra/apache-status.conf`
- `monitoring/blackbox/blackbox.yml`
- `monitoring/mysqld_exporter/.my.cnf`
- `monitoring/promtail/promtail-config.yml`
- `monitoring/loki/local-config.yaml`
- `monitoring/grafana/provisioning/datasources/datasources.yml`
- `monitoring/grafana/provisioning/dashboards/dashboards.yml`
- `monitoring/grafana/dashboards/infraestructura-general.json`
- `monitoring/grafana/dashboards/servidor-web.json`
- `monitoring/grafana/dashboards/base-datos.json`
- `monitoring/grafana/dashboards/red-ataques.json`
- `monitoring/grafana/dashboards/academico-explicativo.json`
- `monitoring/grafana/dashboards/logs-laboratorio.json`
- `monitoring/docker_metrics_exporter/Dockerfile`
- `monitoring/docker_metrics_exporter/requirements.txt`
- `scripts/attacker/stop_attacks.sh`
- `scripts/linux/common.sh`
- `scripts/linux/up.sh`
- `scripts/linux/validate.sh`
- `scripts/linux/generate_legitimate_traffic.sh`
- `scripts/linux/attack.sh`
- `scripts/linux/stop_attacks.sh`
- `scripts/linux/reset_lab.sh`
- `scripts/linux/logs.sh`
- `scripts/linux/metrics.sh`
- `scripts/windows/Common.ps1`
- `scripts/windows/up.ps1`
- `scripts/windows/validate.ps1`
- `scripts/windows/generate_legitimate_traffic.ps1`
- `scripts/windows/attack.ps1`
- `scripts/windows/stop_attacks.ps1`
- `scripts/windows/reset_lab.ps1`
- `scripts/windows/logs.ps1`
- `scripts/windows/metrics.ps1`
- `scripts/windows/up.cmd`
- `scripts/windows/validate.cmd`
- `scripts/windows/generate_legitimate_traffic.cmd`
- `scripts/windows/attack.cmd`
- `scripts/windows/stop_attacks.cmd`
- `scripts/windows/reset_lab.cmd`
- `scripts/windows/logs.cmd`
- `scripts/windows/metrics.cmd`
- `docs/arquitectura.md`
- `docs/monitoreo.md`
- `docs/linux.md`
- `docs/windows.md`
- `docs/pruebas.md`
- `CHANGELOG_CODEX.md`

### Explicacion tecnica de los cambios

- Se construyo un `web.Dockerfile` estable para instalar `mysqli`, `curl`, cliente MySQL y habilitar `mod_status` de Apache.
- Se corrigio el `entrypoint` del web para esperar a MySQL antes de levantar Apache.
- Se ajusto el router para depender del `sysctl` declarado por Docker y mantener reglas de forwarding explicitas.
- Se agrego el usuario `exporter` en MySQL para `mysqld_exporter`.
- Se incorporaron `Prometheus`, `Grafana`, `Loki`, `Promtail`, `Blackbox Exporter`, `apache_exporter`, `mysqld_exporter`, `cAdvisor` y un exporter propio.
- Se instrumentaron metricas del panel (`attack_launch_total`, `attack_active`, timestamps de inicio y stop).
- Se corrigio la parada de ataques mediante un script dedicado dentro de `atacante`, evitando falsos positivos de `pkill -f` sobre la propia linea de comando del stop.
- Se agregaron scripts reproducibles para Linux y Windows.
- Se documentaron decisiones, limitaciones y validaciones reales.

## 4. Justificacion de que no se rompe la infraestructura

Los cambios no reemplazan el laboratorio original. Lo que se hizo fue complementar la infraestructura con observabilidad y reforzar componentes fragiles:

- La segmentacion principal `red_publica`, `red_privada` y `red_ataque` no se altero.
- El router virtual sigue siendo el gateway entre las tres subredes originales.
- El trafico legitimo y el trafico de ataque siguen fluyendo por la misma topologia academica.
- Los servicios `web`, `db`, `atacante`, `monitor` y `panel_control` mantienen sus roles originales.
- `Grafana`, `Prometheus`, `Loki` y la mayor parte de exporters viven fuera del flujo academico en `red_monitoreo`.
- `red_monitoreo` es una red auxiliar de observabilidad, no una sustitucion de la arquitectura existente.
- El panel de control y EmpresaX siguen existiendo como interfaces del laboratorio; Grafana se suma como capa externa de demostracion tecnica.

En otras palabras, la red propuesta sigue siendo esencialmente la misma. Lo nuevo solo observa, no redefine la simulacion.

## 5. Topologia final y conservacion de la topologia original

### Topologia original conservada

- `red_publica`: `172.20.10.0/24`
- `red_privada`: `172.20.20.0/24`
- `red_ataque`: `172.20.30.0/24`
- Router virtual con `172.20.10.254`, `172.20.20.254`, `172.20.30.254`
- Monitor multi-interfaz con `172.20.10.50`, `172.20.20.50`, `172.20.30.50`

### Ajuste minimo agregado

- `red_monitoreo`: `172.20.40.0/24`

### Justificacion del ajuste

La red adicional permite que Prometheus, Grafana, Loki y exporters intercambien metricas y logs sin invadir la logica principal del laboratorio. Es una red de soporte, no una red academica sustitutiva.

## 6. Funcionamiento completo del proyecto

### Contenedores y roles

- `router`: enruta trafico entre DMZ, backend y red de ataque.
- `servidor_web`: expone `EmpresaX` en `localhost:8080`, sirve `index.html` y `login.php`, y consulta MySQL.
- `base_datos`: ejecuta MySQL con la base `empresa`.
- `atacante`: ejecuta `hping3` y bucles `curl` para generar floods y `SQLi DoS`.
- `monitor`: conserva el rol de observacion multi-interfaz del laboratorio.
- `panel_control`: lanza y detiene ataques desde la interfaz visual existente y expone metricas Prometheus.
- `phpmyadmin`: apoyo para inspeccion de base de datos.
- `prometheus`: recolecta metricas.
- `grafana`: visualiza dashboards provisionados.
- `blackbox_exporter`: mide disponibilidad y latencia de HTTP y TCP.
- `mysqld_exporter`: expone metricas de MySQL.
- `apache_exporter`: expone metricas de Apache `mod_status`.
- `cadvisor`: entrega metricas de contenedores y host Docker.
- `docker_metrics_exporter`: expone estado, CPU, memoria y red por contenedor con mejor detalle para este laboratorio.
- `loki` y `promtail`: agregan y consultan logs de contenedores.

### Flujo de trafico legitimo

- El host accede a `EmpresaX` por `http://localhost:8080`.
- El web consulta a MySQL en `172.20.20.10`.
- El panel de control en `localhost:5000` lanza ataques sobre `172.20.10.10`.
- El monitor puede capturar trafico en las tres redes originales.

### Flujo de trafico malicioso

- `UDP`, `SYN`, `ACK` y `Conntrack Killer` salen desde `atacante` hacia el web en la DMZ.
- `HTTP Flood` dispara peticiones GET repetitivas contra `172.20.10.10`.
- `SQLi DoS` envia POST repetidos a `login.php` con una carga basada en `SLEEP(5)`.

### Integracion del monitoreo

- Prometheus scrapea panel, exporters y blackbox probes.
- Grafana consume Prometheus y Loki.
- Loki recibe logs de contenedores via Promtail.
- La red de monitoreo separa la observabilidad de la red academica original.

## 7. Inventario y preservacion de ataques

| Ataque | Objetivo | Protocolo afectado | Capa OSI | Capa TCP/IP | Script / panel | Comando de ejecucion | Evidencia principal | Estado final |
|---|---|---|---|---|---|---|---|---|
| UDP Flood | Saturar trafico hacia el web | UDP | 4 | Transport | `scripts/windows/attack.ps1 -Attack udp` o `scripts/linux/attack.sh udp` | `GET /atacar/udp` | Delta observado de `345768` paquetes TX en `atacante` durante 10 s | Preservado y operativo |
| SYN Flood | Saturar aperturas TCP contra el web | TCP SYN | 4 | Transport | `scripts/windows/attack.ps1 -Attack syn` o `scripts/linux/attack.sh syn` | `GET /atacar/syn` | Delta observado de `133264` paquetes TX en `atacante` durante 10 s | Preservado y operativo |
| ACK Flood | Inundar con segmentos TCP ACK | TCP ACK | 4 | Transport | `scripts/windows/attack.ps1 -Attack ack` o `scripts/linux/attack.sh ack` | `GET /atacar/ack` | Delta observado de `180939` paquetes TX en `atacante` durante 10 s | Preservado y operativo |
| Conntrack Killer | Presionar el seguimiento de conexiones del stack | TCP + estado conntrack | 3/4 | Internet / Transport | `scripts/windows/attack.ps1 -Attack conntrack` o `scripts/linux/attack.sh conntrack` | `GET /atacar/conntrack` | Delta observado de `160101` paquetes TX en `atacante` durante 10 s | Preservado y operativo |
| HTTP Flood | Aumentar carga HTTP y workers del web | HTTP sobre TCP | 7 | Application | `scripts/windows/attack.ps1 -Attack http` o `scripts/linux/attack.sh http` | `GET /atacar/http` | `rate(apache_accesses_total[30s])` observado en `119.24 req/s` en prueba controlada | Preservado y operativo |
| SQLi DoS | Forzar consultas lentas hacia MySQL via `login.php` | HTTP + SQL | 7 | Application | `scripts/windows/attack.ps1 -Attack sqli_dos` o `scripts/linux/attack.sh sqli_dos` | `GET /atacar/sqli_dos` | `rate(mysql_global_status_questions[30s])` observado en `3.8577 q/s` con multiples POST concurrentes | Preservado y operativo |

## 8. Capas OSI y TCP/IP

| Ataque | Protocolo | Capa OSI | Capa TCP/IP | Sintoma observable | Panel o metrica donde se evidencia |
|---|---|---|---|---|---|
| UDP Flood | UDP | 4 | Transport | Pico de paquetes y ancho de banda | Dashboard `Red y Ataques`, `lab_container_network_tx_packets_total`, `lab_container_network_tx_bytes_total` |
| SYN Flood | TCP SYN | 4 | Transport | Saturacion de intentos de conexion, mas latencia o menor disponibilidad | Dashboard `Servidor Web`, `probe_duration_seconds`, `probe_success`, metricas de red |
| ACK Flood | TCP ACK | 4 | Transport | Trafico alto sin sesion valida completa | Dashboard `Red y Ataques`, metricas TX/RX por contenedor |
| Conntrack Killer | TCP + seguimiento de estado | 3/4 | Internet / Transport | Presion sobre el manejo de conexiones del kernel/router | Dashboard `Red y Ataques`, blackbox HTTP/TCP y metricas de red |
| HTTP Flood | HTTP | 7 | Application | Aumento de accesos, workers ocupados, mayor latencia | Dashboard `Servidor Web`, `apache_accesses_total`, `apache_workers`, `probe_duration_seconds` |
| SQLi DoS | HTTP + SQL | 7 | Application | Aumento de consultas, hilos conectados y lentitud de respuesta | Dashboard `Base de Datos`, `mysql_global_status_questions`, `mysql_global_status_threads_connected`, blackbox |

## 9. Preservacion de interfaces visuales

Las dos interfaces existentes se conservaron:

- `EmpresaX` en `infra/html/index.html`
- `Panel de Control DDoS y Explotacion` en `panel/templates/index.html`

No se hicieron redisenos de layout, colores, estructura, titulos visibles ni orden de botones. La integracion del monitoreo se hizo por fuera, con Grafana como panel tecnico adicional.

No se modificaron archivos de frontend en esta intervencion. Por eso no hubo razon tecnica para generar capturas comparativas antes/despues. La decision fue deliberada: preservar la apariencia original.

## 10. Arquitectura de monitoreo

### Componentes usados

- `Prometheus` como recolector principal
- `Grafana` como visualizacion
- `cAdvisor` para metricas de contenedores y runtime Docker
- `docker_metrics_exporter` propio para complementar CPU, memoria, estado y red por contenedor
- `Blackbox Exporter` para disponibilidad HTTP y TCP
- `mysqld_exporter` para MySQL
- `apache_exporter` para Apache
- `Loki` y `Promtail` para logs

### Fuentes de datos en Grafana

- `Prometheus`
- `Loki`

### Dashboards disponibles

- `Infraestructura General`
- `Servidor Web`
- `Base de Datos`
- `Red y Ataques`
- `Academico Explicativo`
- `Logs del Laboratorio`

### Metricas recolectadas

- CPU por contenedor
- memoria por contenedor
- bytes y paquetes RX/TX por contenedor
- errores y drops de interfaz cuando estan disponibles
- estado y uptime de contenedores
- latencia y disponibilidad HTTP
- disponibilidad TCP de MySQL
- accesos y workers de Apache
- consultas y conexiones de MySQL
- logs de servicios y eventos del panel
- estados y contadores de ataques lanzados desde el panel

### Limitaciones conocidas

- En Docker Desktop / WSL, `cAdvisor` por si solo puede no reflejar con suficiente fidelidad algunos detalles de red por contenedor.
- Por esa razon se agrego `docker_metrics_exporter`, que consulta tanto Docker como contadores de interfaz dentro del contenedor.
- No se agrego `node_exporter` porque el foco del laboratorio es la red y los contenedores del escenario, no el host completo.

## 11. Instrucciones de uso

### Linux

```bash
bash scripts/linux/up.sh
bash scripts/linux/validate.sh
bash scripts/linux/generate_legitimate_traffic.sh 60 1
bash scripts/linux/attack.sh syn
bash scripts/linux/stop_attacks.sh
bash scripts/linux/metrics.sh
```

### Windows

```powershell
scripts\windows\up.ps1
scripts\windows\validate.ps1
scripts\windows\generate_legitimate_traffic.ps1 -DurationSeconds 60 -IntervalMilliseconds 1000
scripts\windows\attack.ps1 -Attack syn
scripts\windows\stop_attacks.ps1
scripts\windows\metrics.ps1
```

### Accesos

- EmpresaX: `http://localhost:8080`
- Panel: `http://localhost:5000`
- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- phpMyAdmin: `http://localhost:8081`

## 12. Validaciones y evidencias

Las validaciones principales se ejecutaron el `2026-04-21` en horario `America/Bogota`. Los logs internos de contenedor quedaron en `2026-04-22` porque varios servicios reportan en UTC.

### Comandos ejecutados

- `docker compose -f infra/docker-compose.yml ps`
- `curl http://localhost:9090/api/v1/targets`
- `curl -u admin:admin http://localhost:3000/api/search?query=`
- `docker exec servidor_web cat /proc/sys/net/ipv4/tcp_syncookies`
- `powershell -ExecutionPolicy Bypass -File scripts/windows/validate.ps1`
- `bash scripts/linux/validate.sh`
- Pruebas controladas de `http`, `sqli_dos`, `udp`, `syn`, `ack` y `conntrack`

### Evidencias confirmadas

- Todos los targets de Prometheus requeridos quedaron en estado `up`.
- Grafana provisiono los seis dashboards esperados.
- Loki respondio `ready`.
- `tcp_syncookies` quedo realmente en `0` dentro de `servidor_web`.
- El `HTTP Flood` incremento `apache_accesses_total` hasta aproximadamente `119.24 req/s` en una prueba controlada.
- El `SQLi DoS` incremento `mysql_global_status_questions` a aproximadamente `3.8577 q/s` en una prueba controlada.
- Los ataques de red incrementaron contadores de interfaz en `atacante` con deltas medidos de `345768` paquetes (`udp`), `133264` (`syn`), `180939` (`ack`) y `160101` (`conntrack`) en ventanas de 10 segundos.
- El boton de stop y los scripts de stop dejaron el panel en `attack_active = 0` para los seis ataques.

## 13. Conclusiones tecnicas

El laboratorio final demuestra de forma trazable la relacion entre trafico malicioso, degradacion de servicio y metricas observables por capa. Se conservo la arquitectura original del proyecto y se agrego una capa robusta de monitoreo sin rediseñar el ejercicio academico.

La principal mejora tecnica fue convertir un escenario funcional pero fragil en un entorno reproducible y observable. El valor agregado de esta version no es cambiar la topologia, sino permitir explicar con mayor rigor que pasa antes, durante y despues de cada ataque.
