# Uso en Windows

## Entorno recomendado

- Windows 10/11
- Docker Desktop
- WSL2 habilitado
- PowerShell

## Levantar el laboratorio

```powershell
scripts\windows\up.ps1
```

Tambien se puede usar:

```cmd
scripts\windows\up.cmd
```

## Validar el entorno

```powershell
scripts\windows\validate.ps1
```

## Generar trafico legitimo

```powershell
scripts\windows\generate_legitimate_traffic.ps1 -DurationSeconds 60 -IntervalMilliseconds 1000
```

Salida por defecto:

- `analisis\trafico_legitimo_windows.csv`

## Lanzar ataques

```powershell
scripts\windows\attack.ps1 -Attack udp
scripts\windows\attack.ps1 -Attack syn
scripts\windows\attack.ps1 -Attack http
scripts\windows\attack.ps1 -Attack sqli_dos
```

Ataques finales permitidos:

- `udp`
- `syn`
- `http`
- `sqli_dos`

Tambien existe el wrapper:

```cmd
scripts\windows\attack.cmd syn
```

## Detener ataques

```powershell
scripts\windows\stop_attacks.ps1
```

## Reiniciar el laboratorio

```powershell
scripts\windows\reset_lab.ps1
```

## Consultar logs y metricas

```powershell
scripts\windows\logs.ps1 -Service panel_control
scripts\windows\logs.ps1 -Follow
scripts\windows\metrics.ps1
```

## URLs utiles

- `http://localhost:8080`
- `http://localhost:5000`
- `http://localhost:3000`
- `http://localhost:9090`
- `http://localhost:8081`

## Troubleshooting rapido

- Si Docker Desktop no esta iniciado, los scripts fallaran al consultar contenedores o endpoints.
- Si Grafana no muestra los cuatro dashboards finales, ejecuta `scripts\windows\validate.ps1` y revisa los logs de `grafana`, `prometheus` y `docker_metrics_exporter`.
- Si una prueba deja trafico activo, ejecuta `scripts\windows\stop_attacks.ps1`.
- Si quieres volver al estado limpio inicial, ejecuta `scripts\windows\reset_lab.ps1`.
