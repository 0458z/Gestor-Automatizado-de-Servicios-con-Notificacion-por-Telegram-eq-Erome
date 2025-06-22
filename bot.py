# bot.py
import subprocess
from telegram import Update, ReplyKeyboardMarkup
from telegram.ext import (ApplicationBuilder, CommandHandler, ContextTypes, ConversationHandler,
                          MessageHandler, filters)
import logging

# Configurar logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# Token del bot
TOKEN = "7581456498:AAG20kGpSslfNX4JaQio_yTIhVU62fl3auk"

# Ruta base de los scripts
RUTA_SCRIPTS = "/home/zeta/pps_prueba"

# Estados para la conversación de usuarios
SELECCION, NOMBRE = range(2)
ACCION = ""

# /start
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "Hola, soy el bot de administración de servicios. Usa /ayuda para ver las opciones disponibles."
    )

# /ayuda
async def ayuda(update: Update, context: ContextTypes.DEFAULT_TYPE):
    texto = (
        "Comandos disponibles:\n"
        "/ejecutar usuarios crear|eliminar|modificar nombre\n"
        "/ejecutar servicios [lista_de_servicios]\n"
        "/ejecutar respaldo <directorio> [ruta_backup] [hora]\n"
        "/ejecutar remoto <ip1,ip2,...> [ruta_script]\n"
        "/ejecutar monitoreo [umbral_cpu] [umbral_disco]"
    )
    await update.message.reply_text(texto)

# /ejecutar usuarios (interactivo)
async def usuarios_inicio(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Selecciona una opción:\n1. Crear usuario\n2. Eliminar usuario\n3. Modificar usuario\n4. Salir")
    return SELECCION

async def usuarios_accion(update: Update, context: ContextTypes.DEFAULT_TYPE):
    global ACCION
    texto = update.message.text.strip()
    if texto == "1":
        ACCION = "crear"
    elif texto == "2":
        ACCION = "eliminar"
    elif texto == "3":
        ACCION = "modificar"
    elif texto == "4":
        await update.message.reply_text("Operación cancelada.")
        return ConversationHandler.END
    else:
        await update.message.reply_text("Opción no válida")
        return SELECCION
    await update.message.reply_text("Por favor, ingresa el nombre del usuario:")
    return NOMBRE

async def usuarios_nombre(update: Update, context: ContextTypes.DEFAULT_TYPE):
    nombre_usuario = update.message.text
    comando = [f"{RUTA_SCRIPTS}/usuarios.sh", ACCION, nombre_usuario]
    resultado = subprocess.run(comando, capture_output=True, text=True)
    salida = resultado.stdout.strip() + "\n" + resultado.stderr.strip()
    if not salida.strip():
        salida = f"✅ Acción '{ACCION}' ejecutada para el usuario '{nombre_usuario}'."
    await update.message.reply_text(salida[:4000])
    return ConversationHandler.END

async def cancelar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Operación cancelada.")
    return ConversationHandler.END

# /ejecutar general
async def ejecutar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Debes indicar qué script ejecutar. Usa /ayuda para más información.")
        return

    script = context.args[0]
    argumentos = context.args[1:]

    comandos = {
        "usuarios": f"{RUTA_SCRIPTS}/usuarios.sh",
        "servicios": f"{RUTA_SCRIPTS}/servicios.sh",
        "respaldo": f"{RUTA_SCRIPTS}/respaldo.sh",
        "remoto": f"{RUTA_SCRIPTS}/remoto.sh",
        "monitoreo": f"{RUTA_SCRIPTS}/monitoreo.sh",
    }

    if script == "usuarios" and not argumentos:
        return await usuarios_inicio(update, context)

    if script not in comandos:
        await update.message.reply_text(f"Script desconocido: {script}")
        return

    comando = [comandos[script]] + argumentos

    try:
        resultado = subprocess.run(comando, capture_output=True, text=True, timeout=60)
        salida = resultado.stdout.strip() + "\n" + resultado.stderr.strip()
        if not salida.strip():
            salida = "✅ Script ejecutado correctamente."
        await update.message.reply_text(salida[:4000])
    except Exception as e:
        await update.message.reply_text(f"Error al ejecutar el script: {e}")

# main
def main():
    app = ApplicationBuilder().token(TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("ayuda", ayuda))
    app.add_handler(CommandHandler("ejecutar", ejecutar))

    conv_handler = ConversationHandler(
        entry_points=[CommandHandler("usuarios", usuarios_inicio)],
        states={
            SELECCION: [MessageHandler(filters.TEXT & ~filters.COMMAND, usuarios_accion)],
            NOMBRE: [MessageHandler(filters.TEXT & ~filters.COMMAND, usuarios_nombre)],
        },
        fallbacks=[CommandHandler("cancelar", cancelar)],
    )

    app.add_handler(conv_handler)
    app.run_polling()

if __name__ == '__main__':
    main()
