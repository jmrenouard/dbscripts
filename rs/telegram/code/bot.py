#!/usr/bin/env python

from telegram.ext import Updater, CommandHandler, MessageHandler, Filters
from dotenv import load_dotenv
import os
import logging
from logdecorator import log_on_start, log_on_end, log_on_error, log_exception
import pprint

@log_on_end(logging.INFO, "call /start")
def start(update, context):
    update.message.reply_text("""
Bienvenue sur le bot officiel de tcollart.

Les commandes disponibles sont :
- /site pour obtenir l'adresse du site
- /youtube pour obtenir la chaîne YouTube
- /linkedin pour obtenir son profil Linkedin
    """)

@log_on_end(logging.INFO, "Call /site")
def site(update, context):
    update.message.reply_text('https://www.commentcoder.com')
    logging.info("ARGS: " + pprint.pformat(context.args))
    logging.info("USER: " + pprint.pformat(context.user_data))
    logging.info("BOT: " + pprint.pformat(context.bot_data))

@log_on_end(logging.INFO, "Call /youtube")
def youtube(update, context):
    update.message.reply_text('https://www.youtube.com/channel/UCEztUC2WwKEDkVl9c6oUoTw')

@log_on_end(logging.INFO, "Call /linkedin")
def linkedin(update, context):
    update.message.reply_text('https://www.linkedin.com/in/thomascollart')

@log_on_end(logging.INFO, "Call /unknown")
def pas_compris(update, context):
    update.message.reply_text( f"Je n\'ai pas compris votre message: {update.message.text}" )

def error(update, context):
    """Log Errors caused by Updates."""
    logging.warning('Update "%s" caused error "%s"', update, context.error)

def main():
    logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO)

    load_dotenv()
    TOKEN = os.getenv('TOKEN')
    
    # La classe Updater permet de lire en continu ce qu'il se passe sur le channel
    updater = Updater(TOKEN, use_context=True)

    # Pour avoir accès au dispatcher plus facilement
    dp = updater.dispatcher


    userFilter=Filters.user(username="@jmrenouard2") | Filters.user(username="@jmrenouard")
    # On ajoute des gestionnaires de commandes
    # On donne a CommandHandler la commande textuelle et une fonction associée
    dp.add_handler(CommandHandler("start", callback=start, pass_args=True, pass_user_data=True))
    dp.add_handler(CommandHandler("help", callback=site, pass_args=True, pass_user_data=True))
    dp.add_handler(CommandHandler("site", callback=site, pass_args=True, pass_user_data=True))
    dp.add_handler(CommandHandler("youtube", callback=youtube, pass_args=True, pass_user_data=True, filters=userFilter))
    dp.add_handler(CommandHandler("linkedin", callback=linkedin, pass_args=True, pass_user_data=True))

    # Pour gérer les autres messages qui ne sont pas des commandes
    dp.add_handler(MessageHandler(Filters.text, pas_compris))

    dp.add_error_handler(error)
    # Sert à lancer le bot
    updater.start_polling()

    # Pour arrêter le bot proprement avec CTRL+C
    updater.idle()


if __name__ == '__main__':
    main()