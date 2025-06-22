#!/bin/bash

TOKEN="7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"
ID_CHAT="5268491936"
ARCHIVO_LOG="/var/log/servicios.log"

# Servicios por defecto si no se pasan como argumentos
SERVICIOS_POR_DEFECTO=("nginx" "mysql" "ssh")
SERVICIOS=("$@")
if [ ${#SERVICIOS[@]} -eq 0 ]; then
    SERVICIOS=("${SERVICIOS_POR_DEFECTO[@]}")
fi

# Función para enviar notificación a Telegram
enviar_notificacion() {
    local mensaje=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d chat_id="$ID_CHAT" -d text="$mensaje"
}

# Comprobar estado de los servicios
for servicio in "${SERVICIOS[@]}"; do
    estado=$(systemctl is-active "$servicio")
    if [ "$estado" != "active" ]; then
        systemctl start "$servicio"
        mensaje=" El servicio $servicio estaba detenido y fue reiniciado."
        echo "$(date) - $mensaje" >> "$ARCHIVO_LOG"
        enviar_notificacion "$mensaje"
    else
        mensaje=" El servicio $servicio está activo."
        echo "$(date) - $mensaje" >> "$ARCHIVO_LOG"
        enviar_notificacion "$mensaje"
    fi
done
