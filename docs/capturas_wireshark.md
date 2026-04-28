# Capturas Wireshark

## Objetivo

Generar archivos `.pcap` o `.pcapng` desde el proyecto final para analizarlos con Wireshark en el host, sin mover la topologia ni sustituir el `monitor`.

## Como funciona

- El contenedor `monitor` sigue siendo el punto de observacion del proyecto.
- La captura efectiva se ejecuta en `router`, porque el trafico entre subredes realmente cruza por ese contenedor.
- `router` monta la carpeta persistente `analisis/pcaps` del host como `/captures`.
- Los scripts de captura lanzan `tcpdump` dentro de `router`.
- Los archivos se guardan en `/captures` y quedan disponibles en el host en `analisis/pcaps`.
- Grafana, Prometheus, Loki y los exporters no se modifican ni se sustituyen.

## Modos de captura

- `red_publica`
- `red_privada`
- `red_ataque`
- `todas`

La resolucion de interfaz se hace por IP dentro del `router`:

- `172.20.10.254` -> `red_publica`
- `172.20.20.254` -> `red_privada`
- `172.20.30.254` -> `red_ataque`

Para `todas`, la captura usa `any`.

## Nombres de archivo

Formato base:

- `<etiqueta>_<modo>_YYYYMMDD_HHMMSS.pcap` o `.pcapng`

Ejemplos:

- `syn_red_publica_20260427_101500.pcapng`
- `udp_red_ataque_20260427_101900.pcapng`
- `http_red_publica_20260427_102200.pcapng`
- `sqli_red_privada_20260427_102700.pcapng`

## Proteccion contra archivos gigantes

Las capturas usan ring buffer:

- tamano por archivo: `25 MB`
- cantidad de archivos: `5`

Esto limita el uso de disco incluso durante floods prolongados.

## Comandos Linux

```bash
bash scripts/scripts_captura_ataques/linux/start_capture.sh red_publica syn
bash scripts/scripts_captura_ataques/linux/stop_capture.sh
```

Captura automatizada por ataque:

```bash
bash scripts/scripts_captura_ataques/linux/capture_attack.sh syn 45
```

Secuencia completa de los cuatro ataques:

```bash
bash scripts/scripts_captura_ataques/linux/capture_all_attacks.sh 45
```

## Comandos Windows

```powershell
scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_publica -Label syn
scripts\scripts_captura_ataques\windows\stop_capture.ps1
```

Captura automatizada por ataque:

```powershell
scripts\scripts_captura_ataques\windows\capture_attack.ps1 -Attack syn -DurationSeconds 45
```

Secuencia completa de los cuatro ataques:

```powershell
scripts\scripts_captura_ataques\windows\capture_all_attacks.ps1 -DurationSeconds 45
```

## Recomendaciones por ataque

- `SYN Flood`: capturar `red_publica`
- `UDP Flood`: capturar `red_publica` o `red_ataque`
- `HTTP Flood`: capturar `red_publica`
- `SQLi DoS`: capturar `red_privada`

## Apertura en Wireshark

1. Ejecuta la captura.
2. Detenla con el script correspondiente.
3. Abre el archivo `.pcap` o `.pcapng` desde `analisis/pcaps` en el host con Wireshark.
4. Si usaste la corrida automatizada de 45 segundos, revisa tambien `analisis/pcaps/capturas_45s_resumen.txt`.

No se ejecuta Wireshark dentro de Docker.
