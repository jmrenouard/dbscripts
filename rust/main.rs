extern crate mysql;

use mysql as my;
use mysql::prelude::*;


fn main() {
    // Create a connection to the database
    let url="mysql://root:Iiyi3aeCae9queemid@172.20.1.101:3306/mysql";
    let pool = my::Pool::new(url).unwrap();
    let mut conn = pool.get_conn().unwrap();

    // Iterate over the results and print them
    let res:Vec<(String, String)> = conn.query("select user, host from mysql.user").unwrap();
    for row in res {
        let user_name: String = row.0;
        let host: String = row.1;
        println!("user_name: {}, host: {}", user_name, host);
    }
}