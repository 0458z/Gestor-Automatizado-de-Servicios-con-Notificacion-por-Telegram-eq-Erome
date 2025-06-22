#!/bin/bash

DIRECTORIO_ORIGEN=$1
RUTA_BACKUP=${2:-/backups}
HORA_PERSONALIZADA=$3
FECHA=$(date +%F)
ARCHIVO="$RUTA_BACKUP/respaldo_$FECHA.tar.gz"
TOKEN="7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"
CHAT_ID="5268491936"

# Función para enviar notificación a Telegram
enviar_notificacion() {
    local mensaje=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id=$CHAT_ID -d text="$mensaje"
}

# Verificar y crear el directorio de respaldo si no existe
if [ ! -d "$RUTA_BACKUP" ]; then
    mkdir -p "$RUTA_BACKUP"
fi

# Comprimir el directorio
tar -czf "$ARCHIVO" "$DIRECTORIO_ORIGEN"

# Verificar si el archivo fue creado correctamente
if [ -f "$ARCHIVO" ]; then
    enviar_notificacion "✅ Respaldo exitoso de '$DIRECTORIO_ORIGEN': $ARCHIVO"
else
    enviar_notificacion "❌ Error al realizar el respaldo de '$DIRECTORIO_ORIGEN'."
fi

# Programar el respaldo en crontab (cada 3 horas)
(crontab -l 2>/dev/null; echo "0 */3 * * * /home/zeta/pps_prueba/respaldo.sh $DIRECTORIO_ORIGEN $RUTA_BACKUP") | crontab -

# Programar respaldo a una hora específica si el usuario la proporciona (formato HH:MM)
if [[ "$HORA_PERSONALIZADA" =~ ^([0-1][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
    MINUTO=$(echo $HORA_PERSONALIZADA | cut -d':' -f2)
    HORA=$(echo $HORA_PERSONALIZADA | cut -d':' -f1)
    (crontab -l 2>/dev/null; echo "$MINUTO $HORA * * * /home/zeta/pps_prueba/respaldo.sh $DIRECTORIO_ORIGEN $RUTA_BACKUP") | crontab -
    enviar_notificacion "⏰ También se ha programado el respaldo diario a las $HORA_PERSONALIZADA."
fi
