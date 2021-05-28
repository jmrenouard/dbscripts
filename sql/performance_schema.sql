 --  performance_schema=ON
 -- performance-schema-instrument='stage/%=ON'
 -- performance-schema-consumer-events-stages-current=ON
 -- performance-schema-consumer-events-stages-history=ON
 -- performance-schema-consumer-events-stages-history-long=ON
 -- performance-schema-events-statements-history-size=-1
 -- performance-schema-events-statements-history-long-size=-1

SHOW VARIABLES LIKE 'performance_schema';

 --  Tables du PFS
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'performance_schema';

 --  Etat des consommateurs et intruments
SELECT name, enabled, timed FROM performance_schema.setup_instruments;
SELECT * FROM performance_schema.setup_consumers;

 --  Activation de tous les consommateurs et instruments
update performance_schema.setup_instruments set enabled='YES', timed='YES';
update performance_schema.setup_consumers set enabled='YES';

UPDATE performance_schema.setup_instruments SET ENABLED = 'YES', TIMED = 'YES'
WHERE NAME LIKE '%statement/%' OR NAME LIKE '%stage/%';

UPDATE performance_schema.setup_consumers SET ENABLED = 'YES'
WHERE NAME LIKE '%events_statements_%' OR NAME LIKE '%events_stages_%';

 --  Cleanup PFS Information
truncate performance_schema.events_stages_history_long;
truncate performance_schema.events_statements_history_long;

 --  Taille des caches de données PFS
MariaDB [sys]> show global variables like 'performance_schema_%_size';
-- +----------------------------------------------------------+-------+
-- | Variable_name                                            | Value |
-- +----------------------------------------------------------+-------+
-- | performance_schema_accounts_size                         | 100   |
-- | performance_schema_digests_size                          | 200   |
-- | performance_schema_events_stages_history_long_size       | 1000  |
-- | performance_schema_events_stages_history_size            | 10    |
-- | performance_schema_events_statements_history_long_size   | 1000  |
-- | performance_schema_events_statements_history_size        | 10    |
-- | performance_schema_events_transactions_history_long_size | 1000  |
-- | performance_schema_events_transactions_history_size      | 10    |
-- | performance_schema_events_waits_history_long_size        | 10000 |
-- | performance_schema_events_waits_history_size             | 10    |
-- | performance_schema_hosts_size                            | 100   |
-- | performance_schema_session_connect_attrs_size            | 512   |
-- | performance_schema_setup_actors_size                     | 100   |
-- | performance_schema_setup_objects_size                    | 100   |
-- | performance_schema_users_size                            | 100   |
-- +----------------------------------------------------------+-------+
-- 15 rows in set (0.017 sec)

-- Requêtes utilisateurs
SELECT * FROM `performance_schema` . `users`;

-- de la table des requêtes
DESC performance_schema.events_statements_history_long;

SELECT * FROM performance_schema.events_statements_history_long;
SELECT * FROM performance_schema.events_stages_history_long;

-- Quelques requêtes d'analyse
-- for tbl in x\$statement_analysis  x\$statements_with_errors_or_warnings x\$statements_with_full_table_scans x\$statements_with_runtimes_in_95th_percentile x\$statements_with_sorting x\$statements_with_temp_tables;do
-- echo $tbl
-- echo "-------------------------------------------"
--  mysql -Nrs -e "SHOW CREATE TABLE $tbl" sys
-- done

-- Tables without primary key
SELECT DISTINCT t.table_schema, t.table_name
  FROM information_schema.tables AS t
  LEFT JOIN information_schema.columns AS c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
        AND c.column_key = "PRI"
 WHERE t.table_schema NOT IN ('information_schema', 'mysql', 'performance_schema')
   AND c.table_name IS NULL AND t.table_type != 'VIEW';

--  Connections mal fermées
SELECT ess.user, ess.host
     , (a.total_connections - a.current_connections) - ess.count_star as not_closed
     , ((a.total_connections - a.current_connections) - ess.count_star) * 100 /
       (a.total_connections - a.current_connections) as pct_not_closed
  FROM performance_schema.events_statements_summary_by_account_by_event_name ess
  JOIN performance_schema.accounts a on (ess.user = a.user and ess.host = a.host)
 WHERE ess.event_name = 'statement/com/quit'
   AND (a.total_connections - a.current_connections) > ess.count_star
;

-- Indexes non utilisés
SELECT DISTINCT s.table_schema, s.table_name, s.index_name
--     , i.count_star
  FROM information_schema.statistics AS s
  LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage AS i
         ON (s.table_schema = i.object_schema AND s.table_name = i.object_name AND s.index_name = i.index_Name)
 WHERE s.table_schema NOT IN ('mysql', 'performance_schema', 'sys', 'information_schema')
   AND s.index_name != 'PRIMARY'
   AND i.count_star = 0
 ORDER BY s.table_schema, s.table_name, s.index_name
;

-- Utilisateurs jamais connectés
SELECT DISTINCT m_u.user
  FROM mysql.user m_u
  LEFT JOIN performance_schema.users ps_u ON m_u.user = ps_u.user
 WHERE ps_u.user IS NULL
 ORDER BY m_u.user
;

-- les mauvaises requêtes par utilisateur
SELECT user, host, event_name
     , sum_created_tmp_disk_tables AS tmp_disk_tables
     , sum_select_full_join AS full_join
     , sum_select_range_check AS range_check
     , sum_sort_merge_passes AS sort_merge
  FROM performance_schema.events_statements_summary_by_account_by_event_name
 WHERE sum_created_tmp_disk_tables > 0
    OR sum_select_full_join > 0
    OR sum_select_range_check > 0
    OR sum_sort_merge_passes > 0
 ORDER BY sum_sort_merge_passes DESC
 LIMIT 10
;

-- profile des acces par table
SELECT object_type, object_schema, object_name
     , count_star, count_read, count_write, count_fetch
     , count_insert, count_update, count_delete
  FROM performance_schema.table_io_waits_summary_by_table
 WHERE count_star > 0
 ORDER BY count_star DESC;

SELECT object_type, object_schema, object_name, index_name
     , count_star, count_read, count_write, count_fetch
     , count_insert, count_update, count_delete
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE count_star > 0
   AND index_name IS NOT NULL
 ORDER BY count_star DESC;

-- Long queries
SELECT left(digest_text, 64)
     , ROUND(SUM(timer_end-timer_start)/1000000000, 1) AS tot_exec_ms
     , ROUND(SUM(timer_end-timer_start)/1000000000/COUNT(*), 1) AS avg_exec_ms
     , ROUND(MIN(timer_end-timer_start)/1000000000, 1) AS min_exec_ms
     , ROUND(MAX(timer_end-timer_start)/1000000000, 1) AS max_exec_ms
     , ROUND(SUM(timer_wait)/1000000000, 1) AS tot_wait_ms
     , ROUND(SUM(timer_wait)/1000000000/COUNT(*), 1) AS avg_wait_ms
     , ROUND(MIN(timer_wait)/1000000000, 1) AS min_wait_ms
     , ROUND(MAX(timer_wait)/1000000000, 1) AS max_wait_ms
     , ROUND(SUM(lock_time)/1000000000, 1) AS tot_lock_ms
     , ROUND(SUM(lock_time)/1000000000/COUNT(*), 1) AS avglock_ms
     , ROUND(MIN(lock_time)/1000000000, 1) AS min_lock_ms
     , ROUND(MAX(lock_time)/1000000000, 1) AS max_lock_ms
     , MIN(LEFT(DATE_SUB(NOW(), INTERVAL (isgs.VARIABLE_VALUE - TIMER_START*10e-13) second), 19)) AS first_seen
     , MAX(LEFT(DATE_SUB(NOW(), INTERVAL (isgs.VARIABLE_VALUE - TIMER_START*10e-13) second), 19)) AS last_seen
     , COUNT(*) as cnt
  FROM performance_schema.events_statements_history_long
  JOIN information_schema.global_status AS isgs
 WHERE isgs.variable_name = 'UPTIME'
 GROUP BY LEFT(digest_text,64)
 ORDER BY tot_exec_ms DESC;

-- tables sans écriture
SELECT t.table_schema, t.table_name, t.table_rows, tio.count_read, tio.count_write
  FROM information_schema.tables AS t
  JOIN performance_schema.table_io_waits_summary_by_table AS tio
    ON tio.object_schema = t.table_schema AND tio.object_name = t.table_name
 WHERE t.table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
   AND tio.count_write = 0
 ORDER BY t.table_schema, t.table_name;

-- Req avec erreur et warning
SELECT * FROM performance_schema.events_statements_history
 WHERE errors != 0 OR warnings != 0\G

 -- Verrou InnoDB
 SELECT lock_trx_id, lock_mode, lock_type, lock_table, lock_index FROM information_schema.innodb_locks;

SELECT trx_id, trx_state, trx_started, trx_wait_started, trx_mysql_thread_id, trx_query, trx_tables_in_use, trx_tables_locked, trx_lock_structs, trx_rows_locked, trx_rows_modified
  FROM information_schema.innodb_trx
 ORDER BY trx_started, trx_wait_started;

-- Last SQL statements by thread
SELECT EVENT_ID, SQL_TEXT, CURRENT_SCHEMA   FRom performance_schema.events_statements_history  ORDER BY EVENT_ID DESC  LIMIT 10;

--Comptage par  Evenement
SELECT event_name, COUNT(*)
  FROM performance_schema.events_statements_history
 GROUP BY event_name;

-- Analyse des requêtes
x$statement_analysis
-------------------------------------------
SELECT `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT` AS `query`,`performance_schema`.`events_statements_summary_by_digest`.`SCHEMA_NAME` AS `db`,if(`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_GOOD_INDEX_USED` > 0 or `performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_INDEX_USED` > 0,'*','') AS `full_scan`,`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR` AS `exec_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ERRORS` AS `err_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_WARNINGS` AS `warn_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` AS `total_latency`,`performance_schema`.`events_statements_summary_by_digest`.`MAX_TIMER_WAIT` AS `max_latency`,`performance_schema`.`events_statements_summary_by_digest`.`AVG_TIMER_WAIT` AS `avg_latency`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_LOCK_TIME` AS `lock_latency`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_SENT` AS `rows_sent`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_SENT` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `rows_sent_avg`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_EXAMINED` AS `rows_examined`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_EXAMINED` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `rows_examined_avg`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_AFFECTED` AS `rows_affected`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_AFFECTED` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `rows_affected_avg`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES` AS `tmp_tables`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_DISK_TABLES` AS `tmp_disk_tables`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_ROWS` AS `rows_sorted`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_MERGE_PASSES` AS `sort_merge_passes`,`performance_schema`.`events_statements_summary_by_digest`.`DIGEST` AS `digest`,`performance_schema`.`events_statements_summary_by_digest`.`FIRST_SEEN` AS `first_seen`,`performance_schema`.`events_statements_summary_by_digest`.`LAST_SEEN` AS `last_seen` FROM `performance_schema`.`events_statements_summary_by_digest` order by `performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` desc    utf8     utf8_general_ci

# Requêtes avec erreurs ou warnings
x$statements_with_errors_or_warnings
-------------------------------------------
SELECT `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT` AS `query`,`performance_schema`.`events_statements_summary_by_digest`.`SCHEMA_NAME` AS `db`,`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR` AS `exec_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ERRORS` AS `errors`,ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ERRORS` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0) * 100 AS `error_pct`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_WARNINGS` AS `warnings`,ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_WARNINGS` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0) * 100 AS `warning_pct`,`performance_schema`.`events_statements_summary_by_digest`.`FIRST_SEEN` AS `first_seen`,`performance_schema`.`events_statements_summary_by_digest`.`LAST_SEEN` AS `last_seen`,`performance_schema`.`events_statements_summary_by_digest`.`DIGEST` AS `digest` FROM `performance_schema`.`events_statements_summary_by_digest` where `performance_schema`.`events_statements_summary_by_digest`.`SUM_ERRORS` > 0 or `performance_schema`.`events_statements_summary_by_digest`.`SUM_WARNINGS` > 0 order by `performance_schema`.`events_statements_summary_by_digest`.`SUM_ERRORS` desc,`performance_schema`.`events_statements_summary_by_digest`.`SUM_WARNINGS` desc       utf8    utf8_general_ci

# Requêtes avec des balayage complète de tables
x$statements_with_full_table_scans
-------------------------------------------
SELECT `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT` AS `query`,`performance_schema`.`events_statements_summary_by_digest`.`SCHEMA_NAME` AS `db`,`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR` AS `exec_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` AS `total_latency`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_INDEX_USED` AS `no_index_used_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_GOOD_INDEX_USED` AS `no_good_index_used_count`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_INDEX_USED` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0) * 100,0) AS `no_index_used_pct`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_SENT` AS `rows_sent`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_EXAMINED` AS `rows_examined`,round(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_SENT` / `performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0) AS `rows_sent_avg`,round(`performance_schema`.`events_statements_summary_by_digest`.`SUM_ROWS_EXAMINED` / `performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0) AS `rows_examined_avg`,`performance_schema`.`events_statements_summary_by_digest`.`FIRST_SEEN` AS `first_seen`,`performance_schema`.`events_statements_summary_by_digest`.`LAST_SEEN` AS `last_seen`,`performance_schema`.`events_statements_summary_by_digest`.`DIGEST` AS `digest` FROM `performance_schema`.`events_statements_summary_by_digest` where (`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_INDEX_USED` > 0 or `performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_GOOD_INDEX_USED` > 0) and `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT`  not like 'SHOW%' order by round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_NO_INDEX_USED` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0) * 100,0) desc,`performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` desc   utf8    utf8_general_ci

# LEs requêtes en 965% percentile
x$statements_with_runtimes_in_95th_percentile
-------------------------------------------
SELECT `stmts`.`DIGEST_TEXT` AS `query`,`stmts`.`SCHEMA_NAME` AS `db`,if(`stmts`.`SUM_NO_GOOD_INDEX_USED` > 0 or `stmts`.`SUM_NO_INDEX_USED` > 0,'*','') AS `full_scan`,`stmts`.`COUNT_STAR` AS `exec_count`,`stmts`.`SUM_ERRORS` AS `err_count`,`stmts`.`SUM_WARNINGS` AS `warn_count`,`stmts`.`SUM_TIMER_WAIT` AS `total_latency`,`stmts`.`MAX_TIMER_WAIT` AS `max_latency`,`stmts`.`AVG_TIMER_WAIT` AS `avg_latency`,`stmts`.`SUM_ROWS_SENT` AS `rows_sent`,round(ifnull(`stmts`.`SUM_ROWS_SENT` / nullif(`stmts`.`COUNT_STAR`,0),0),0) AS `rows_sent_avg`,`stmts`.`SUM_ROWS_EXAMINED` AS `rows_examined`,round(ifnull(`stmts`.`SUM_ROWS_EXAMINED` / nullif(`stmts`.`COUNT_STAR`,0),0),0) AS `rows_examined_avg`,`stmts`.`FIRST_SEEN` AS `first_seen`,`stmts`.`LAST_SEEN` AS `last_seen`,`stmts`.`DIGEST` AS `digest` FROM (`performance_schema`.`events_statements_summary_by_digest` `stmts` join `sys`.`x$ps_digest_95th_percentile_by_avg_us` `top_percentile` on(round(`stmts`.`AVG_TIMER_WAIT` / 1000000,0) >= `top_percentile`.`avg_us`)) order by `stmts`.`AVG_TIMER_WAIT` desc       utf8    utf8_general_ci

# requêtes avec des tris
x$statements_with_sorting
-------------------------------------------
SELECT `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT` AS `query`,`performance_schema`.`events_statements_summary_by_digest`.`SCHEMA_NAME` AS `db`,`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR` AS `exec_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` AS `total_latency`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_MERGE_PASSES` AS `sort_merge_passes`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_MERGE_PASSES` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `avg_sort_merges`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_SCAN` AS `sorts_using_scans`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_RANGE` AS `sort_using_range`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_ROWS` AS `rows_sorted`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_ROWS` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `avg_rows_sorted`,`performance_schema`.`events_statements_summary_by_digest`.`FIRST_SEEN` AS `first_seen`,`performance_schema`.`events_statements_summary_by_digest`.`LAST_SEEN` AS `last_seen`,`performance_schema`.`events_statements_summary_by_digest`.`DIGEST` AS `digest` FROM `performance_schema`.`events_statements_summary_by_digest` where `performance_schema`.`events_statements_summary_by_digest`.`SUM_SORT_ROWS` > 0 order by `performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` desc        utf8 utf8_general_ci

# requêtes avec des tables temporaires
x$statements_with_temp_tables
-------------------------------------------
SELECT `performance_schema`.`events_statements_summary_by_digest`.`DIGEST_TEXT` AS `query`,`performance_schema`.`events_statements_summary_by_digest`.`SCHEMA_NAME` AS `db`,`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR` AS `exec_count`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_TIMER_WAIT` AS `total_latency`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES` AS `memory_tmp_tables`,`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_DISK_TABLES` AS `disk_tmp_tables`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`COUNT_STAR`,0),0),0) AS `avg_tmp_tables_per_query`,round(ifnull(`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_DISK_TABLES` / nullif(`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES`,0),0) * 100,0) AS `tmp_tables_to_disk_pct`,`performance_schema`.`events_statements_summary_by_digest`.`FIRST_SEEN` AS `first_seen`,`performance_schema`.`events_statements_summary_by_digest`.`LAST_SEEN` AS `last_seen`,`performance_schema`.`events_statements_summary_by_digest`.`DIGEST` AS `digest` FROM `performance_schema`.`events_statements_summary_by_digest` where `performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES` > 0 order by `performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_DISK_TABLES` desc,`performance_schema`.`events_statements_summary_by_digest`.`SUM_CREATED_TMP_TABLES` desc     utf8    utf8_general_ci


for tbl in schema_redundant_indexes schema_unused_indexes;do
echo $tbl
echo "-------------------------------------------"
mysql -Nrs -e "SHOW CREATE TABLE $tbl" sys
done
schema_redundant_indexes
-------------------------------------------
SELECT `redundant_keys`.`table_schema` AS `table_schema`,`redundant_keys`.`table_name` AS `table_name`,`redundant_keys`.`index_name` AS `redundant_index_name`,`redundant_keys`.`index_columns` AS `redundant_index_columns`,`redundant_keys`.`non_unique` AS `redundant_index_non_unique`,`dominant_keys`.`index_name` AS `dominant_index_name`,`dominant_keys`.`index_columns` AS `dominant_index_columns`,`dominant_keys`.`non_unique` AS `dominant_index_non_unique`,if(`redundant_keys`.`subpart_exists` <> 0 or `dominant_keys`.`subpart_exists` <> 0,1,0) AS `subpart_exists`,concat('ALTER TABLE `',`redundant_keys`.`table_schema`,'`.`',`redundant_keys`.`table_name`,'` DROP INDEX `',`redundant_keys`.`index_name`,'`') AS `sql_drop_index` FROM (`sys`.`x$schema_flattened_keys` `redundant_keys` join `sys`.`x$schema_flattened_keys` `dominant_keys` on(`redundant_keys`.`table_schema` = `dominant_keys`.`table_schema` and `redundant_keys`.`table_name` = `dominant_keys`.`table_name`)) where `redundant_keys`.`index_name` <> `dominant_keys`.`index_name` and (`redundant_keys`.`index_columns` = `dominant_keys`.`index_columns` and (`redundant_keys`.`non_unique` > `dominant_keys`.`non_unique` or `redundant_keys`.`non_unique` = `dominant_keys`.`non_unique` and if(`redundant_keys`.`index_name` = 'PRIMARY','',`redundant_keys`.`index_name`) > if(`dominant_keys`.`index_name` = 'PRIMARY','',`dominant_keys`.`index_name`)) or locate(concat(`redundant_keys`.`index_columns`,','),`dominant_keys`.`index_columns`) = 1 and `redundant_keys`.`non_unique` = 1 or locate(concat(`dominant_keys`.`index_columns`,','),`redundant_keys`.`index_columns`) = 1 and `dominant_keys`.`non_unique` = 0)   utf8    utf8_general_ci

schema_unused_indexes
-------------------------------------------
SELECT `performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_SCHEMA` AS `object_schema`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_NAME` AS `object_name`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` AS `index_name` FROM `performance_schema`.`table_io_waits_summary_by_index_usage` where `performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` is not null and `performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_STAR` = 0 and `performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_SCHEMA` <> 'mysql' and `performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` <> 'PRIMARY' order by `performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_SCHEMA`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_NAME` utf8    utf8_general_ci



for tbl in schema_table_statistics schema_index_statistics schema_table_statistics_with_buffer schema_tables_with_full_table_scans
do
echo $tbl
echo "-------------------------------------------"
mysql -Nrs -e "SHOW CREATE TABLE $tbl" sys
done

schema_table_statistics
-------------------------------------------
SELECT `pst`.`OBJECT_SCHEMA` AS `table_schema`,`pst`.`OBJECT_NAME` AS `table_name`,`sys`.`format_time`(`pst`.`SUM_TIMER_WAIT`) AS `total_latency`,`pst`.`COUNT_FETCH` AS `rows_fetched`,`sys`.`format_time`(`pst`.`SUM_TIMER_FETCH`) AS `fetch_latency`,`pst`.`COUNT_INSERT` AS `rows_inserted`,`sys`.`format_time`(`pst`.`SUM_TIMER_INSERT`) AS `insert_latency`,`pst`.`COUNT_UPDATE` AS `rows_updated`,`sys`.`format_time`(`pst`.`SUM_TIMER_UPDATE`) AS `update_latency`,`pst`.`COUNT_DELETE` AS `rows_deleted`,`sys`.`format_time`(`pst`.`SUM_TIMER_DELETE`) AS `delete_latency`,`fsbi`.`count_read` AS `io_read_requests`,`sys`.`format_bytes`(`fsbi`.`sum_number_of_bytes_read`) AS `io_read`,`sys`.`format_time`(`fsbi`.`sum_timer_read`) AS `io_read_latency`,`fsbi`.`count_write` AS `io_write_requests`,`sys`.`format_bytes`(`fsbi`.`sum_number_of_bytes_write`) AS `io_write`,`sys`.`format_time`(`fsbi`.`sum_timer_write`) AS `io_write_latency`,`fsbi`.`count_misc` AS `io_misc_requests`,`sys`.`format_time`(`fsbi`.`sum_timer_misc`) AS `io_misc_latency` FROM (`performance_schema`.`table_io_waits_summary_by_table` `pst` left join `sys`.`x$ps_schema_table_statistics_io` `fsbi` on(`pst`.`OBJECT_SCHEMA` = `fsbi`.`table_schema` and `pst`.`OBJECT_NAME` = `fsbi`.`table_name`)) order by `pst`.`SUM_TIMER_WAIT` desc        utf8    utf8_general_ci

schema_index_statistics
-------------------------------------------
SELECT `performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_SCHEMA` AS `table_schema`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_NAME` AS `table_name`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` AS `index_name`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_FETCH` AS `rows_SELECTed`,`sys`.`format_time`(`performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_FETCH`) AS `SELECT_latency`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_INSERT` AS `rows_inserted`,`sys`.`format_time`(`performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_INSERT`) AS `insert_latency`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_UPDATE` AS `rows_updated`,`sys`.`format_time`(`performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_UPDATE`) AS `update_latency`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_DELETE` AS `rows_deleted`,`sys`.`format_time`(`performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_INSERT`) AS `delete_latency` FROM `performance_schema`.`table_io_waits_summary_by_index_usage` where `performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` is not null order by `performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_WAIT` desc   utf8    utf8_general_ci
schema_table_statistics_with_buffer
-------------------------------------------
SELECT `pst`.`OBJECT_SCHEMA` AS `table_schema`,`pst`.`OBJECT_NAME` AS `table_name`,`pst`.`COUNT_FETCH` AS `rows_fetched`,`sys`.`format_time`(`pst`.`SUM_TIMER_FETCH`) AS `fetch_latency`,`pst`.`COUNT_INSERT` AS `rows_inserted`,`sys`.`format_time`(`pst`.`SUM_TIMER_INSERT`) AS `insert_latency`,`pst`.`COUNT_UPDATE` AS `rows_updated`,`sys`.`format_time`(`pst`.`SUM_TIMER_UPDATE`) AS `update_latency`,`pst`.`COUNT_DELETE` AS `rows_deleted`,`sys`.`format_time`(`pst`.`SUM_TIMER_DELETE`) AS `delete_latency`,`fsbi`.`count_read` AS `io_read_requests`,`sys`.`format_bytes`(`fsbi`.`sum_number_of_bytes_read`) AS `io_read`,`sys`.`format_time`(`fsbi`.`sum_timer_read`) AS `io_read_latency`,`fsbi`.`count_write` AS `io_write_requests`,`sys`.`format_bytes`(`fsbi`.`sum_number_of_bytes_write`) AS `io_write`,`sys`.`format_time`(`fsbi`.`sum_timer_write`) AS `io_write_latency`,`fsbi`.`count_misc` AS `io_misc_requests`,`sys`.`format_time`(`fsbi`.`sum_timer_misc`) AS `io_misc_latency`,`sys`.`format_bytes`(`ibp`.`allocated`) AS `innodb_buffer_allocated`,`sys`.`format_bytes`(`ibp`.`data`) AS `innodb_buffer_data`,`sys`.`format_bytes`(`ibp`.`allocated` - `ibp`.`data`) AS `innodb_buffer_free`,`ibp`.`pages` AS `innodb_buffer_pages`,`ibp`.`pages_hashed` AS `innodb_buffer_pages_hashed`,`ibp`.`pages_old` AS `innodb_buffer_pages_old`,`ibp`.`rows_cached` AS `innodb_buffer_rows_cached` FROM ((`performance_schema`.`table_io_waits_summary_by_table` `pst` left join `sys`.`x$ps_schema_table_statistics_io` `fsbi` on(`pst`.`OBJECT_SCHEMA` = `fsbi`.`table_schema` and `pst`.`OBJECT_NAME` = `fsbi`.`table_name`)) left join `sys`.`x$innodb_buffer_stats_by_table` `ibp` on(`pst`.`OBJECT_SCHEMA` = `ibp`.`object_schema` and `pst`.`OBJECT_NAME` = `ibp`.`object_name`)) order by `pst`.`SUM_TIMER_WAIT` desc       utf8 utf8_general_ci

schema_tables_with_full_table_scans
-------------------------------------------
SELECT `performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_SCHEMA` AS `object_schema`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`OBJECT_NAME` AS `object_name`,`performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_READ` AS `rows_full_scanned`,`sys`.`format_time`(`performance_schema`.`table_io_waits_summary_by_index_usage`.`SUM_TIMER_WAIT`) AS `latency` FROM `performance_schema`.`table_io_waits_summary_by_index_usage` where `performance_schema`.`table_io_waits_summary_by_index_usage`.`INDEX_NAME` is null and `performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_READ` > 0 order by `performance_schema`.`table_io_waits_summary_by_index_usage`.`COUNT_READ` desc  utf8    utf8_general_ci
