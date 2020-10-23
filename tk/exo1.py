#!/bin/env python3

from tkinter import *
from pprint import pprint
from functools import partial

# ---------- code for function: event_lambda (begin) --------
def event_lambda(f, *args, **kwds ):
    """A helper function that wraps lambda in a prettier interface.
    Thanks to Chad Netzer for the code."""
    return lambda event, f=f, args=args, kwds=kwds : f( *args, **kwds )
# ---------- code for function: event_lambda (end) -----------

class MyApp:
    def __init__(self, parent):
        self.myParent = parent
        self.myContainer1 = Frame(parent)
        self.myContainer1.pack()

        #------------------ BUTTON #1 ------------------------------------
        button_name = "OK"

        # command binding
        self.button1 = Button(self.myContainer1,
            command = partial(self.buttonHandler ,button_name, 1, "Bien !" ))

        # event binding -- passage del'évènement en tant que paramètre
        self.button1.bind("<Return>", event_lambda( self.buttonHandler, button_name, 1, "Bien !" ) )

        self.button1.configure(text=button_name, background="green")
        self.button1.pack(side=LEFT)
        self.button1.focus_force()  # Place le focus du clavier sur button1

        #------------------ BUTTON #2 ------------------------------------
        button_name = "Cancel"

        # command binding
        self.button2 = Button(self.myContainer1,
            command = partial(self.buttonHandler ,button_name, 2, "Mal !" ) )

        # event binding -- sans passer l'évènement en tant que paramètre
        self.button2.bind("<Return>", event_lambda( self.buttonHandler, button_name, 2, "Mal !" ))

        self.button2.configure(text=button_name, background="red")
        self.button2.pack(side=LEFT)


    def buttonHandler(self, argument1, argument2, argument3):
        print(" la routine buttonHandler a reçu les paramètres :", argument1.ljust(8), argument2, argument3)

    def buttonHandler_a(self, event, argument1, argument2, argument3):
        print("buttonHandler_a a reçu l'évènement ", event)
        self.buttonHandler(argument1, argument2, argument3)


print("\n"*100) # nettoyage de l'écran
print("Démarrage du programme tt078.")

root = Tk()
myapp = MyApp(root)
print("Prêt à commencer l'exécution de l'event loop.")
root.mainloop()
print("Fini d'exécuter l'event loop.")

def report_event(event):     ### (5)
    """Affiche une description de l'"vènement, basé sur ses attributs.
    """
    pprint(event)
