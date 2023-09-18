select TABLE_SCHEMA, ENGINE , TABLE_NAME
    from information_schema.tables
    where TABLE_TYPE like 'Base table'
    AND ENGINE <> 'InnoDB'
    and TABLE_SCHEMA NOT IN ('mysql', 'performance_schema', 'sys', 'information_schema')
    ORDER BY TABLE_SCHEMA, ENGINE;

   SELECT DISTINCT t.table_schema, t.table_name
       FROM information_schema.tables AS t
       LEFT JOIN information_schema.columns AS c ON t.table_schema = c.table_schema AND t.table_name = c.table_name
             AND c.column_key = 'PRI'
      WHERE t.table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
        AND c.table_name IS NULL AND t.table_type != 'VIEW';

-- Taille des index et données innodb
SELECT table_schema, 
SUM((data_length + index_length)/ 1024 / 1024) "Size in MB",
SUM(data_length  / 1024 / 1024) "Data Size in MB",
SUM(index_length  / 1024 / 1024) "Index Size in MB", --
SUM(index_length) *100/ SUM(data_length+index_length) "Ratio Index in MB"
from information_schema.tables
where Engine='InnoDB'
GROUP BY table_schema;

-- Taille des index et données innodb
SELECT 
SUM((data_length + index_length)/ 1024 / 1024) "Size in MB",
SUM(data_length  / 1024 / 1024) "Data Size in MB",
SUM(index_length  / 1024 / 1024) "Index Size in MB", --
SUM(index_length) *100/ SUM(data_length+index_length) "Ratio Index in MB"
from information_schema.tables
where Engine='InnoDB'
