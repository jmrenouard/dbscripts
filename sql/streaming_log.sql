-- https://galeracluster.com/library/documentation/system-tables.html

show session variables like '%_trx_%';

set session wsrep_trx_fragment_size=1;
set session wsrep_trx_fragment_unit='rows';
show session variables like '%_trx_%';

SELECT node_uuid, trx_id, seqno, flags FROM mysql.wsrep_streaming_log;

START TRANSACTION;
update salaries set salary =salary +10 limit 200;
SELECT node_uuid, trx_id, seqno, flags FROM mysql.wsrep_streaming_log;
SELECT node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;
COMMIT;
SELECT node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;

set session wsrep_trx_fragment_size=20;
START TRANSACTION;
update salaries set salary =salary +10 limit 200;
SELECT node_uuid, trx_id, seqno, flags FROM mysql.wsrep_streaming_log;
SELECT node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;
COMMIT;
SELECT node_uuid, count(*) from mysql.wsrep_streaming_log GROUP BY node_uuid;

SET SESSION wsrep_trx_fragment_size=0;

-- $transaction_gtid = SELECT WSREP_LAST_SEEN_GTID();
-- SELECT WSREP_SYNC_WAIT_UPTO_GTID($transaction_gtid);
