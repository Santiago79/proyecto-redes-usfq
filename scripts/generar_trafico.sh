#!/bin/bash

# ==============================================================================
# Script Generador de Tráfico y Sonda de Rendimiento
# Autores: Equipo de Redes (Santi)
# ==============================================================================

# IP del servidor NGINX (Mare te dará la IP exacta cuando levante Docker)
# Para probarlo ahora mismo, puedes cambiarlo temporalmente por "http://example.com"
TARGET_URL="http://192.168.100.10"

# Ruta del archivo CSV (asumiendo que ejecutas el script desde la carpeta scripts/)
OUTPUT_FILE="../analisis/trafico_base.csv"

echo "======================================================"
echo " Iniciando sonda de tráfico HTTP hacia $TARGET_URL"
echo " Presiona [Ctrl+C] para detener la ejecución."
echo "======================================================"

# 1. Escribir la cabecera en el archivo CSV (Sobreescribe si ya existe)
echo "timestamp,http_code,latency_seconds" > "$OUTPUT_FILE"

# 2. Bucle infinito para generar tráfico constante
while true; do
    # Obtener la marca de tiempo actual
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # 3. La magia de curl: 
    # -s: Modo silencioso (no muestra barra de progreso)
    # -o /dev/null: Descarta el HTML (no nos importa el contenido, solo la red)
    # -w: Formateamos la salida para que solo nos dé "código_http,tiempo_total"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "$TARGET_URL")

    # Separar los valores usando la coma como delimitador
    HTTP_CODE=$(echo "$RESPONSE" | cut -d',' -f1)
    LATENCY=$(echo "$RESPONSE" | cut -d',' -f2)

    # 4. Mostrar en pantalla para monitoreo en vivo
    echo "[$TIMESTAMP] Código HTTP: $HTTP_CODE | Latencia: ${LATENCY}s"

    # 5. Guardar los datos en el archivo CSV
    echo "$TIMESTAMP,$HTTP_CODE,$LATENCY" >> "$OUTPUT_FILE"

    # Esperar medio segundo antes de la siguiente petición (tráfico ligero)
    sleep 0.5
done