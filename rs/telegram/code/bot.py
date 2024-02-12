#!/usr/bin/env python

from telegram.ext import Updater, CommandHandler, MessageHandler, Filters
from dotenv import load_dotenv
import os
import logging
from logdecorator import log_on_start
import pprint
from functools import wraps
import json

def restricted(func):
    """Restrict usage of func to allowed users only and replies if necessary"""
    @wraps(func)
    def wrapped(update, context, *args, **kwargs):
        logging.info("Message: %s", update)
        username = update.effective_user.username
        if username not in os.getenv('ALLOW_USERS').split(','):
            logging.warning(f"WARNING: Unauthorized access denied for {username}")
            update.message.reply_text('User disallowed.')
            return  # quit function
        return func(update, context, *args, **kwargs)
    return wrapped

@restricted
@log_on_start(logging.INFO, "call /start")
def start(update, context):
    update.message.reply_text("""
Bienvenue sur le bot officiel de tcollart.

Les commandes disponibles sont :
- /site pour obtenir l'adresse du site
- /youtube pour obtenir la chaîne YouTube
- /linkedin pour obtenir son profil Linkedin
    """)

@restricted
@log_on_start(logging.INFO, "Call /site")
def site(update, context):
    update.message.reply_text('https://www.commentcoder.com')
    logging.info("ARGS: " + pprint.pformat(context.args))
    logging.info("USER: " + pprint.pformat(context.user_data))
    logging.info("BOT: " + pprint.pformat(context.bot_data))
    logging.info("UPDATE: " + pprint.pformat(update))

@restricted
@log_on_start(logging.INFO, "Call /youtube")
def youtube(update, context):
    update.message.reply_text('https://www.youtube.com/channel/UCEztUC2WwKEDkVl9c6oUoTw')

@restricted
@log_on_start(logging.INFO, "Call /linkedin")
def linkedin(update, context):
    update.message.reply_text('https://www.linkedin.com/in/thomascollart')

@restricted
@log_on_start(logging.INFO, "Call /id")
def whoami(update, context):
    logging.info("MSG: " + pprint.pformat(update.message.from_user))
    msg=f"""# {update.message.from_user.first_name} {update.message.from_user.last_name}
# ID: {update.message.from_user.id}
# EST UN ROBOT : {update.message.from_user.is_bot}
    """
    #logger.info(f"REPLY: {msg}")
    update.message.reply_text( msg )

@restricted
@log_on_start(logging.INFO, "Call /unknown")
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

    # Définition des liens et des réponses
    config= {
        "start": start,
        "help": help,
        "site": site,
        "youtube": youtube,
        "linkedin": linkedin,
        "id": whoami,
        "whoami": whoami,
        "error": error
    }

    for command in config.keys():
        logging.info("Adding %s command", command)
        dp.add_handler(CommandHandler(command, callback=config[command], pass_args=True, pass_user_data=True))

    # Pour gérer les autres messages qui ne sont pas des commandes
    dp.add_handler(MessageHandler(Filters.text, pas_compris))

    dp.add_error_handler(config['error'])

    updater.start_polling()
    updater.idle()


if __name__ == '__main__':
    main()