#!/bin/bash

# Definir variables
LOG_FILE="/var/log/acciones_usuarios.log"
TOKEN="7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"
CHAT_ID="5268491936"

# Función para enviar notificación a Telegram
send_notification() {
    local mensaje=$1
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id=$CHAT_ID -d text="$mensaje"
}

# Recibir los parámetros que el bot pasa: acción y nombre de usuario
ACTION=$1
USER=$2

# Verificar la acción y ejecutar el comando correspondiente
case $ACTION in
    crear)
        # Crear el usuario
        useradd $USER
        echo "$(date) - Usuario $USER creado" >> $LOG_FILE
        send_notification "Usuario $USER creado con éxito."
        ;;
    eliminar)
        # Eliminar el usuario
        userdel $USER
        echo "$(date) - Usuario $USER eliminado" >> $LOG_FILE
        send_notification "Usuario $USER eliminado con éxito."
        ;;
    modificar)
        # Modificar la contraseña del usuario
        passwd $USER
        echo "$(date) - Usuario $USER modificado" >> $LOG_FILE
        send_notification "Usuario $USER modificado con éxito."
        ;;
    *)
        # Acción no válida
        send_notification "Acción no válida: $ACTION"
        echo "$(date) - Acción no válida: $ACTION" >> $LOG_FILE
        exit 1
        ;;
esac
