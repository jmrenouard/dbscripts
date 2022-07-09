#!/bin/env python
import mysql.connector
import fire
import json
from dotenv import dotenv_values

class MySQLRequest(object):
    """ Execute SQL statements
    """
    requestUser = "select user, host from mysql.user"
    def getUsers(self, format='json', file=""):
        config=dotenv_values(".env")
        result=""
        with mysql.connector.connect(**config) as conn:
            with conn.cursor() as c:
                c.execute(self.requestUser)
                if format == 'json':
                    result=json.dumps(c.fetchall(), sort_keys=True, indent=4)
                elif format == 'md':
                    result="| **User** | **Hostname** |\n|:---:|:---:|"
                    for user in c.fetchall():
                        result=f"{result}\n| {user[0]} | {user[1]} |"
                    result=f"{result}\n:Database users"
        print(result)
        if file != '':
            with open(file, 'w') as f:
                f.write(result)

if __name__ == '__main__':
  fire.Fire(MySQLRequest)