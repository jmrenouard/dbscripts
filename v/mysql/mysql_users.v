module main
import db.mysql

fn main() {
	// Create connection
	mut config := mysql.Config {
		username: 'root'
		password: 'Admin2023:'
		host: '127.0.0.1'
		dbname: 'mysql'
	}

	// Connect to server
	mut connection:=mysql.connect(config)!
	// Change the default database
	connection.select_db('mysql')!

	// Do a query
	get_users_query_result := connection.query('SELECT * FROM mysql.user')!
	
	// Get the result as maps
	for user in get_users_query_result.maps() {
		// Access the name of user
		println(user['User'])
	}
	
	// Free the query result
	unsafe {
		get_users_query_result.free()
	}

	// Close the connection if needed
	connection.close()
}