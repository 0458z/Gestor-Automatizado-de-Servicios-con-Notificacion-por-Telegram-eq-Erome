#!/bin/bash

# Variables
ARCHIVO_IPS="/home/zeta/pps_prueba/ips.txt"
SCRIPT_LOCAL="/home/zeta/pps_prueba/script_remoto.sh"
REPORTE="/var/log/reporte_remoto.log"
USUARIO_REMOTO="zeta"
TOKEN="7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"
CHAT_ID="5268491936"
FECHA=$(date "+%Y-%m-%d %H:%M:%S")

# Función para enviar notificación por Telegram
enviar_mensaje() {
    local mensaje=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d chat_id=$CHAT_ID \
         -d text="$mensaje"
}

# Función para registrar en log
registrar_log() {
    echo "[$FECHA] $1" >> $REPORTE
}

# Lista de IPs (parámetro o archivo)
if [ -n "$1" ]; then
    IFS=',' read -ra LISTA_IPS <<< "$1"
else
    if [ ! -f "$ARCHIVO_IPS" ]; then
        enviar_mensaje " Error: No se encontró el archivo de IPs en $ARCHIVO_IPS"
        exit 1
    fi
    mapfile -t LI
