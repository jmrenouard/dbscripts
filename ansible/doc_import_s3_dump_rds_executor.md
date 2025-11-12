# Playbook: Import S3 dump to RDS

This playbook imports a database dump from an S3 bucket to an Amazon RDS instance.

## Tasks

- **Generate RDS Credentials file**: Creates a temporary file with the RDS credentials.
- **Test RDS Access**: Tests the connection to the RDS instance.
- **Get S3 database list**: Lists the databases to be imported from the S3 bucket.
- **Import S3 dump**: Imports the database dump from S3 to the RDS instance.
- **Check Import From S3 - Number of tables**: Compares the number of tables in the imported database with the original dump.
- **Check Import From S3 - Number of lines**: Compares the number of rows in each table of the imported database with the original dump.

## Variables

- `target`: The target host(s) to run the playbook on. Defaults to `mysql-servers`.
- `dbname`: The name of the database to import. Defaults to `all`.
- `rds_mysql_hostname`: The hostname of the RDS instance.
- `rds_mysql_username`: The username for the RDS instance.
- `rds_mysql_password`: The password for the RDS instance.
- `s3_shared_bucket`: The name of the S3 bucket where the dumps are stored.
- `rds_executor`: The host that will execute the RDS-related tasks.

## Example Usage

To run this playbook, use the following command, providing the required variables:

```bash
ansible-playbook import_s3_dump_rds_executor.yml -e "rds_mysql_hostname=your_rds_hostname rds_mysql_username=your_rds_username rds_mysql_password=your_rds_password s3_shared_bucket=your_s3_bucket rds_executor=your_executor_host"
```
