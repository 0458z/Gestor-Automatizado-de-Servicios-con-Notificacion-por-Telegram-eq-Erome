#!/bin/bash

# Parámetros: umbral CPU y disco (por defecto 70%)
UMBRAL_CPU=${1:-70}
UMBRAL_DISCO=${2:-70}
TOKEN="7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"
CHAT_ID="5268491936"
ARCHIVO_LOG="/var/log/monitoreo_alertas.log"
FECHA=$(date "+%Y-%m-%d %H:%M:%S")

# Función para enviar alerta a Telegram
enviar_alerta() {
    local mensaje=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d chat_id=$CHAT_ID -d text="$mensaje"
}

# Función para registrar evento en log
registrar_log() {
    echo "[$FECHA] $1" >> "$ARCHIVO_LOG"
}

# Obtener uso actual de CPU
uso_cpu=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' -v prefix="$(hostname)" \
    '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); print 100 - v }')

# Obtener uso actual de disco (/)
uso_disco=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

# Comprobar CPU
if [ $(echo "$uso_cpu > $UMBRAL_CPU" | bc) -eq 1 ]; then
    mensaje=" Alerta: Uso de CPU $uso_cpu% (umbral: $UMBRAL_CPU%)"
    enviar_alerta "$mensaje"
    registrar_log "$mensaje"
fi

# Comprobar Disco
if [ "$uso_disco" -gt "$UMBRAL_DISCO" ]; then
    mensaje=" Alerta: Uso de disco $uso_disco% (umbral: $UMBRAL_DISCO%)"
    enviar_alerta "$mensaje"
    registrar_log "$mensaje"
fi
