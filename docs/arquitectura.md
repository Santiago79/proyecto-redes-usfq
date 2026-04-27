# Arquitectura del proyecto final

## Objetivo

Describir la topologia del proyecto final y dejar claro que la observabilidad se agrego como capa complementaria, no como reemplazo del diseno original.

## Redes

| Red | Subred | Proposito | Estado final |
|---|---|---|---|
| `red_publica` | `172.20.10.0/24` | DMZ y exposicion del servidor web | Conservada |
| `red_privada` | `172.20.20.0/24` | Backend y base de datos | Conservada |
| `red_ataque` | `172.20.30.0/24` | Segmento del atacante y panel | Conservada |
| `red_monitoreo` | `172.20.40.0/24` | Observabilidad, Prometheus, Grafana, Loki y exporters | Nueva, complementaria |

## Contenedores principales

| Servicio | Contenedor | Red(es) | IP fija | Puerto host | Rol |
|---|---|---|---|---|---|
| Router | `router` | publica, privada, ataque | `.10.254`, `.20.254`, `.30.254` | No expone | Enrutamiento |
| Web | `servidor_web` | publica | `172.20.10.10` | `8080:80` | EmpresaX + login vulnerable |
| Base de datos | `base_datos` | privada | `172.20.20.10` | No expone | MySQL |
| Atacante | `atacante` | ataque | `172.20.30.10` | No expone | `hping3` y `curl` de ataque |
| Monitor | `monitor` | publica, privada, ataque | `.10.50`, `.20.50`, `.30.50` | No expone | Observacion multi-interfaz |
| Panel | `panel_control` | ataque, monitoreo | `172.20.30.5` | `5000:5000` | Lanzamiento y stop de ataques |
| phpMyAdmin | `phpmyadmin` | privada | dinamica | `8081:80` | Soporte DB |

## Capa de monitoreo

| Servicio | Red(es) | Funcion |
|---|---|---|
| `prometheus` | monitoreo | Recoleccion de metricas |
| `grafana` | monitoreo | Dashboards |
| `blackbox_exporter` | publica, privada, monitoreo | Probes HTTP y TCP |
| `mysqld_exporter` | privada, monitoreo | MySQL |
| `apache_exporter` | publica, monitoreo | Apache |
| `cadvisor` | monitoreo | Contenedores y runtime Docker |
| `docker_metrics_exporter` | monitoreo | CPU, memoria, red y estado por contenedor |
| `loki` | monitoreo | Almacenamiento de logs |
| `promtail` | monitoreo | Recoleccion de logs de contenedores |

## Flujo logico

1. El host entra a `EmpresaX` por `localhost:8080`.
2. `servidor_web` consulta a `base_datos` por la red privada a traves del router virtual.
3. `panel_control` ordena los cuatro ataques finales sobre el web o la base de datos desde la red de ataque.
4. `monitor` conserva la capacidad academica de ver las tres redes.
5. `Prometheus` y `Grafana` observan el laboratorio desde `red_monitoreo`.

## Conservacion de interfaces

- `infra/html/index.html` se mantuvo para preservar la interfaz `EmpresaX`.
- `panel/templates/index.html` se mantuvo para preservar el panel de control.
- No se sustituyeron estas vistas por dashboards de Grafana.

## Decision arquitectonica clave

La unica extension estructural fue `red_monitoreo`. Todo lo demas conserva el mismo sentido del proyecto final: una empresa simulada con servicios segmentados, un atacante aislado, un router virtual y un monitor transversal.
