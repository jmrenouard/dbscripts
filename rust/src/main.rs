extern crate dotenv;
extern crate mysql;
pub mod macros;
pub mod logger;

use dotenv::dotenv;
use std::env;
use log::{info,debug};
use mysql as my;
use mysql::prelude::*;
use mysql::OptsBuilder;
use crate::logger::logger::setup_logger;

fn main() {
    setup_logger().ok();

    dotenv().ok();
    // Create a connection to the database
    //let database_url = "mysql://root:Admin2023:@127.0.0.1:3306/mysql";
    let database_url: String = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
	  let opts =mysql::Opts::from_url(&database_url).expect("Failed to parse Opts");
		debug!("database_url: {}", database_url);
		let pool = my::Pool::new(opts).expect("Failed to create pool");
		let mut conn = pool.get_conn().expect("Failed to get connection");

		// Iterate over the results and print them
		let res:Vec<(String, String)> = conn.query("select user, host from mysql.user").unwrap();
		for row in res {
			info!("user_name: {}, host: {}", row.0, row.1);
		}
}
