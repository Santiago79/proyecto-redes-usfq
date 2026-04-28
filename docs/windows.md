# Uso en Windows

## Entorno recomendado

- Windows 10/11
- Docker Desktop
- WSL2 habilitado
- PowerShell

## Levantar el laboratorio

```powershell
scripts\scripts_captura_ataques\windows\up.ps1
```

## Validar el entorno

```powershell
scripts\scripts_captura_ataques\windows\validate.ps1
```

## Generar trafico legitimo

```powershell
scripts\scripts_captura_ataques\windows\generate_legitimate_traffic.ps1
```

El generador ahora funciona como sonda continua:

- envia peticiones indefinidas hasta `Ctrl + C`
- sobrescribe el CSV al iniciar una nueva corrida
- muestra codigo HTTP y latencia en vivo

Salida por defecto:

- `analisis\trafico_base.csv`

Opciones utiles:

- `scripts\scripts_captura_ataques\windows\generate_legitimate_traffic.ps1 -IntervalMilliseconds 500`
- `scripts\scripts_captura_ataques\windows\generate_legitimate_traffic.ps1 -OutputFile analisis\trafico_base_custom.csv`
- `scripts\scripts_captura_ataques\windows\generate_legitimate_traffic.ps1 -IntervalMilliseconds 500 -TargetUrl http://localhost:8080`

## Capturas Wireshark

```powershell
scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_publica -Label syn
scripts\scripts_captura_ataques\windows\stop_capture.ps1
```

La salida queda en:

- `analisis\pcaps`

Modos disponibles:

- `red_publica`
- `red_privada`
- `red_ataque`
- `todas`

Ejemplos utiles:

- `scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_publica -Label syn`
- `scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_ataque -Label udp`
- `scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_publica -Label http`
- `scripts\scripts_captura_ataques\windows\start_capture.ps1 -Mode red_privada -Label sqli`

Capturas automatizadas de 45 segundos:

```powershell
scripts\scripts_captura_ataques\windows\capture_attack.ps1 -Attack syn -DurationSeconds 45
scripts\scripts_captura_ataques\windows\capture_attack.ps1 -Attack udp -DurationSeconds 45
scripts\scripts_captura_ataques\windows\capture_attack.ps1 -Attack http -DurationSeconds 45
scripts\scripts_captura_ataques\windows\capture_attack.ps1 -Attack sqli_dos -DurationSeconds 45
```

Corrida completa:

```powershell
scripts\scripts_captura_ataques\windows\capture_all_attacks.ps1 -DurationSeconds 45
```

Resumen:

- `analisis\pcaps\capturas_45s_resumen.txt`

## Lanzar ataques

```powershell
scripts\scripts_captura_ataques\windows\attack.ps1 -Attack udp
scripts\scripts_captura_ataques\windows\attack.ps1 -Attack syn
scripts\scripts_captura_ataques\windows\attack.ps1 -Attack http
scripts\scripts_captura_ataques\windows\attack.ps1 -Attack sqli_dos
```

Ataques finales permitidos:

- `udp`
- `syn`
- `http`
- `sqli_dos`

## Detener ataques

```powershell
scripts\scripts_captura_ataques\windows\stop_attacks.ps1
```

## Reiniciar el laboratorio

```powershell
scripts\scripts_captura_ataques\windows\reset_lab.ps1
```

## Consultar logs y metricas

```powershell
scripts\scripts_captura_ataques\windows\logs.ps1 -Service panel_control
scripts\scripts_captura_ataques\windows\logs.ps1 -Follow
scripts\scripts_captura_ataques\windows\metrics.ps1
```

## URLs utiles

- `http://localhost:8080`
- `http://localhost:5000`
- `http://localhost:3000`
- `http://localhost:9090`
- `http://localhost:8081`

## Troubleshooting rapido

- Si Docker Desktop no esta iniciado, los scripts fallaran al consultar contenedores o endpoints.
- Si Grafana no muestra los cuatro dashboards finales, ejecuta `scripts\scripts_captura_ataques\windows\validate.ps1` y revisa los logs de `grafana`, `prometheus` y `docker_metrics_exporter`.
- Si una prueba deja trafico activo, ejecuta `scripts\scripts_captura_ataques\windows\stop_attacks.ps1`.
- Si quieres volver al estado limpio inicial, ejecuta `scripts\scripts_captura_ataques\windows\reset_lab.ps1`.
- Si quieres validar una captura, abre el archivo `.pcapng` de `analisis\pcaps` con Wireshark en el host.
