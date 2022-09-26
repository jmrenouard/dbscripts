import mysql.connector as mysql

def connect(db_name):
	try:
		return mysql.connect(
			host='localhost',
			user='root',
			password='secret',
			database='employees')
	except Error as e:
		print(e)

if __name__ == '__main__':
	db = connect("projects")
	cursor = db.cursor()

	cursor.execute("SELECT count(*) FROM employees.salaries")
	project_records = cursor.fetchall()
	print(project_records[0][0])

	db.close()