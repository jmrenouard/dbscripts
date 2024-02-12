use mysql

select * from information_schema.TABLES t where t.TABLE_TYPE = 'BASE TABLE' ;
select DISTINCT(TABLE_TYPE) from information_schema.TABLES t

select * from information_schema.TABLES t where t.TABLE_TYPE = 'BASE TABLE' and t.ENGINE='Aria' ;
select * from information_schema.TABLES t where t.TABLE_TYPE = 'BASE TABLE' and t.ENGINE='InnoDB' ;

CHECK TABLE mysql.plugin;
CHECK TABLE employees.employees ;

REPAIR TABLE mysql.plugin;
REPAIR TABLE employees.employees ;


ANALYZE TABLE mysql.plugin;
ANALYZE TABLE employees.employees ;

show global variables like 'innodb_stat%';

select max(emp_no) from employees.employees ;
delete from employees.employees where emp_no > 490000;
ANALYZE TABLE employees.employees ;
delete from employees.employees where emp_no > 400000;

-- Defragmentation
OPTIMIZE TABLE mysql.plugin;

OPTIMIZE TABLE employees.dept_emp ;

ALTER TABLE employees.dept_emp ENGINE='InnoDB';
ANALYZE TABLE employees.dept_emp;

ALTER TABLE employees.titles ENGINE='InnoDB';

select t.TABLE_SCHEMA,  t.TABLE_NAME , round(DATA_FREE/DATA_length)*100 FROM information_schema.TABLES t where round(DATA_FREE/DATA_length)*100 > 33;

-- https://mariadb.com/kb/en/defragmenting-innodb-tablespaces/
-- innodb-defragment=1
set global innodb_defragment=1;

-- 
select DISTINCT (engine), t.TABLE_TYPE from information_schema.TABLES t  ;

-- 
show global variables like '%log_error%';

--

SHOW ENGINE INNODB STATUS;

--
select * from sys.schema_unused_indexes sui ;

select count(dept_no) from employees.dept_manager;

--
select * from information_schema.w