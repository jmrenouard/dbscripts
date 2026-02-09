#!/usr/bin/env python3
import os,win32crypt
encrypted_data = open(f".\\workbench_user_data.dat", "rb").read()
clear_data = win32crypt.CryptUnprotectData(encrypted_data, None, None, None, 0)
print(clear_data)
