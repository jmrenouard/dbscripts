-- https://galeracluster.com/library/documentation/system-tables.html

show session variables like '%_trx_%';

set session wsrep_trx_fragment_size=1;
set session wsrep_trx_fragment_unit='rows';
show session variables like '%_trx_%';

SELECT node_uuid, trx_id, seqno, flags FROM mysql.wsrep_streaming_log;


start transaction;
update salaries set salary =salary +10 limit 200;
SELECT node_uuid, trx_id, seqno, flags FROM mysql.wsrep_streaming_log;
select node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;

commit;
select node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;
