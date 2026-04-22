# Simulación de Red Empresarial con Docker — Proyecto Final

## Integrantes
- Santiago Reátegui
- María Emilia Cueva
- Jorge Gómez

## Descripción general del proyecto final

Este proyecto final implementa una infraestructura de red empresarial segmentada mediante Docker, diseñada para simular tráfico legítimo, ejecutar ataques controlados y analizar su impacto sobre los servicios críticos de la organización.

La arquitectura principal del proyecto **mantiene la misma topología lógica planteada originalmente**, conservando los mismos roles de red:

- `servidor_web` en `172.20.10.10` dentro de la DMZ.
- `base_datos` en `172.20.20.10` dentro de la red privada.
- `atacante` en `172.20.30.10` dentro de la red de ataque.
- `router` como gateway virtual `.254` en las tres subredes originales.
- `monitor` como módulo de monitorización conectado a la infraestructura para observación, recolección y visualización de métricas.
- `panel_control` como interfaz de ejecución de ataques.
- `EmpresaX` como interfaz visual principal del servicio empresarial expuesto.

A diferencia de una propuesta inicial o de un laboratorio parcial, este repositorio corresponde al **proyecto final**, por lo que incluye no solo la topología de red y los ataques, sino también una capa completa de observabilidad para analizar en tiempo real el comportamiento de la infraestructura.

## Topología del proyecto final

Las redes principales del proyecto se conservan:

- `red_publica`: `172.20.10.0/24`
- `red_privada`: `172.20.20.0/24`
- `red_ataque`: `172.20.30.0/24`

Adicionalmente, se incorpora una red complementaria de observabilidad:

- `red_monitoreo`: `172.20.40.0/24`

Esta red adicional **no reemplaza ni rompe la topología original**, sino que permite integrar el sistema de monitorización del proyecto final sin alterar el flujo académico principal entre la DMZ, la red privada y la red de ataque.

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
                ATT["💀 Atacante<br/>172.20.30.10"]
                PANEL["🎛️ Panel de Control DDoS y Explotación<br/>172.20.30.5"]
            end

            subgraph "Router Virtual - Conecta las subredes principales"
                RTR["🚦 Router<br/>172.20.10.254<br/>172.20.20.254<br/>172.20.30.254"]
            end

            subgraph "Módulo de Monitorización"
                MON["📡 Monitor<br/>Nodo lógico de observación del proyecto"]
            end

            subgraph "Red de Monitoreo - 172.20.40.0/24"
                PROM["📈 Prometheus<br/>Recolección de métricas"]
                GRAF["📊 Grafana<br/>Visualización de métricas"]
                LOKI["📝 Loki<br/>Agregación de logs"]
                CADV["📦 cAdvisor"]
                BBX["🌐 Blackbox Exporter"]
                MYSQLX["🗄️ mysqld_exporter"]
                APX["🌍 apache_exporter"]
                PROMTAIL["📚 Promtail"]
                DMX["⚙️ docker_metrics_exporter"]
            end

        end
    end

    WEB --- RTR
    DB --- RTR
    ATT --- RTR
    MON --- RTR

    PANEL -.->|"Lanza ataques"| ATT

    ATT -.->|"SYN Flood / ACK Flood / HTTP Flood"| WEB
    ATT -.->|"UDP Flood"| WEB
    ATT -.->|"UDP Flood"| DB
    ATT -.->|"Conntrack Killer"| RTR
    ATT -.->|"SQLi DoS"| WEB

    MON -.->|"Tráfico legítimo y validación"| WEB
    WEB -.->|"Consultas SQL normales"| DB

    PROM -.->|"Recolecta métricas"| WEB
    PROM -.->|"Recolecta métricas"| DB
    PROM -.->|"Recolecta métricas"| PANEL
    PROM -.->|"Recolecta métricas"| CADV
    PROM -.->|"Recolecta métricas"| BBX
    PROM -.->|"Recolecta métricas"| MYSQLX
    PROM -.->|"Recolecta métricas"| APX
    PROM -.->|"Recolecta métricas"| DMX

    GRAF -.->|"Visualiza métricas almacenadas por"| PROM
    PROMTAIL -.->|"Envía logs a"| LOKI
