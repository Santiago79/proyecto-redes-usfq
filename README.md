# Simulación de Red Empresarial con Docker — Proyecto Final

## Integrantes
- Santiago Reátegui
- María Emilia Cueva
- Jorge Gómez

## Descripción general del proyecto final

Este proyecto final implementa una simulación de red empresarial segmentada mediante Docker, diseñada para analizar el impacto de distintos ataques de denegación de servicio y degradación de servicios sobre una infraestructura distribuida.

La infraestructura principal **se conserva con la misma lógica académica original del laboratorio**, manteniendo los mismos roles de red y la misma segmentación base:

- `servidor_web` en `172.20.10.10` dentro de la DMZ.
- `base_datos` en `172.20.20.10` dentro de la red privada.
- `atacante` en `172.20.30.10` dentro de la red de ataque.
- `router` como gateway virtual `.254` en las tres subredes originales.
- `monitor` conectado a todas las redes principales para observación y captura.
- `panel_control` como interfaz de lanzamiento de ataques.
- `EmpresaX` como interfaz visual principal del entorno empresarial.

Como parte del proyecto final, se añadió una **capa de observabilidad** orientada al monitoreo y análisis forense, compuesta por herramientas como Grafana, Prometheus, Loki y exporters especializados.  
Esta adición **no reemplaza ni rompe la topología original**, sino que la complementa para permitir la recolección y visualización de métricas de red, recursos y disponibilidad.

## Topología de red conservada

Las redes académicas originales se preservan:

- `red_publica`: `172.20.10.0/24`
- `red_privada`: `172.20.20.0/24`
- `red_ataque`: `172.20.30.0/24`

La única adición estructural es:

- `red_monitoreo`: `172.20.40.0/24`

Esta red adicional se usa **exclusivamente para la capa de observabilidad** y no altera el flujo principal del laboratorio, ni el enrutamiento base entre la DMZ, la red privada y la red de ataque.

```mermaid
graph TD
    subgraph "Host Físico"
        subgraph "RED DOCKER: 172.20.0.0/16 (Proyecto Final)"

            subgraph "Subred Pública (DMZ) - 172.20.10.0/24"
                WEB["🖥️ Servidor Web / EmpresaX<br/>172.20.10.10"]
            end

            subgraph "Subred Privada (Backend) - 172.20.20.0/24"
                DB["🗄️ Base de Datos MySQL<br/>172.20.20.10"]
            end

            subgraph "Subred de Ataque - 172.20.30.0/24"
                ATTACKER["💀 Atacante<br/>172.20.30.10"]
                PANEL["🎛️ Panel de Control DDoS<br/>172.20.30.5"]
            end

            subgraph "Router Virtual - Conecta las subredes originales"
                ROUTER["🚦 Router<br/>eth0: 172.20.10.254<br/>eth1: 172.20.20.254<br/>eth2: 172.20.30.254"]
            end

            subgraph "Monitor Académico - Conectado a las redes principales"
                MONITOR["📡 Monitor<br/>172.20.10.50<br/>172.20.20.50<br/>172.20.30.50"]
            end

            subgraph "Red de Observabilidad - 172.20.40.0/24"
                GRAFANA["📊 Grafana"]
                PROM["📈 Prometheus"]
                LOKI["📝 Loki"]
                CADV["📦 cAdvisor"]
                BBX["🌐 Blackbox Exporter"]
                MYSQLX["🗄️ mysqld_exporter"]
                APX["🌍 apache_exporter"]
                PROMTAIL["📚 Promtail"]
                DMX["⚙️ docker_metrics_exporter"]
            end

        end
    end

    %% Conexiones principales a router
    WEB --- ROUTER
    DB --- ROUTER
    ATTACKER --- ROUTER
    MONITOR --- ROUTER

    %% Panel de control hacia atacante
    PANEL -.->|"Lanza ataques"| ATTACKER

    %% Tráfico malicioso
    ATTACKER -.->|"SYN Flood / ACK Flood / HTTP Flood"| WEB
    ATTACKER -.->|"UDP Flood"| WEB
    ATTACKER -.->|"UDP Flood"| DB
    ATTACKER -.->|"Conntrack Killer"| ROUTER
    ATTACKER -.->|"SQLi DoS"| WEB

    %% Tráfico legítimo
    MONITOR -.->|"Peticiones HTTP legítimas"| WEB
    WEB -.->|"Consultas SQL normales"| DB

    %% Observabilidad
    GRAFANA -.->|"Dashboards"| PROM
    GRAFANA -.->|"Logs"| LOKI
    PROM -.->|"Scraping métricas"| WEB
    PROM -.->|"Scraping métricas"| DB
    PROM -.->|"Scraping métricas"| PANEL
    PROM -.->|"Scraping métricas"| CADV
    PROM -.->|"Scraping métricas"| BBX
    PROM -.->|"Scraping métricas"| MYSQLX
    PROM -.->|"Scraping métricas"| APX
    PROM -.->|"Scraping métricas"| DMX
    PROMTAIL -.->|"Recolección de logs"| LOKI
