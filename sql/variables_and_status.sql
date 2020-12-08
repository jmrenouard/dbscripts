show session variables like '%cache%';
show global variables like '%cache%';

show global variables like 'sql_log_bin';
set session sql_log_bin=OFF;
show global variables like 'sql_log_bin';
show session variables like 'sql_log_bin';
set session sql_log_bin=ON;

show global status like 'Com_select%';
select count(*) from employees.employees e ;

show session status like 'Com_select%';

set session port=3310;

-- Log files
set global general_log=on;
set global general_log_file="/tmp/capture-80122020.log";

show global variables like 'general%';
show global variables like '%error%';


set global general_log=off;
set global general_log_file="";

show global variables like 'general%';
show global variables like '%error%';

show global variables like 'log_warnings';

-- slow queries log
show global variables like 'slow%';
show global variables like 'long_query%';
show global variables like 'log_quer%';

use employees;
set GLOBAL long_query_time=3;
select sleep(6);

