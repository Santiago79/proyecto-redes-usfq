# Simulación de Red Empresarial con Docker

## Integrantes
- Santiago Reátegui
- María Emilia Cueva  
- Jorge Gómez

## Topología de Red

```mermaid
graph TD
    subgraph "Host Físico"
        subgraph "RED DOCKER: 172.20.0.0/16 (Superred)"
            
            subgraph "Subred Pública (DMZ) - 172.20.10.0/24"
                WEB["🖥️ Servidor Web (NGINX)<br/>172.20.10.10<br/>sysctl: tcp_syncookies=0"]
            end

            subgraph "Subred Privada (Backend) - 172.20.20.0/24"
                DB["🗄️ Base de Datos (MySQL)<br/>172.20.20.10<br/>Sin puerto expuesto"]
            end

            subgraph "Subred de Ataque - 172.20.30.0/24"
                ATTACKER["💀 Atacante (Alpine + hping3)<br/>172.20.30.10"]
            end

            subgraph "Router Virtual - Conecta todas las subredes"
                ROUTER["🚦 Router<br/>eth0: 172.20.10.1 (Pública)<br/> eth1: 172.20.20.1 (Privada)<br/>eth2: 172.20.30.1 (Ataque)"]
            end

            subgraph "Monitor - Conectado a TODAS las subredes"
                MONITOR["📡 Monitor (netshoot)<br/>eth0: 172.20.10.50 (Pública)<br/>eth1: 172.20.20.50 (Privada)<br/>eth2: 172.20.30.50 (Ataque)"]
            end

        end
    end

    %% Conexiones al Router (cada contenedor se conecta a su subred correspondiente)
    WEB --- ROUTER
    DB --- ROUTER
    ATTACKER --- ROUTER
    
    %% Monitor se conecta a las tres subredes
    MONITOR --- ROUTER

    %% Tráfico de ataque (flechas punteadas)
    ATTACKER -.->|"SYN Flood (TCP) hacia puerto 80"| WEB
    ATTACKER -.->|"UDP Flood hacia puertos aleatorios"| WEB
    ATTACKER -.->|"UDP Flood hacia puertos aleatorios"| DB

    %% Tráfico legítimo desde el monitor hacia el web
    MONITOR -.->|"Peticiones HTTP (curl) para medir latencia"| WEB

    %% Tráfico normal web -> base de datos (a través del router)
    WEB -.->|"Consultas SQL a DB"| DB