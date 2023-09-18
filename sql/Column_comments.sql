SELECT 
table_name,
column_name,
CONCAT('ALTER TABLE `',
        TABLE_SCHEMA,
        '`.`',
        table_name,
        '` CHANGE `',
        column_name,
        '` `',
        column_name,
        '` ',
        column_type,
        ' ',
        IF(is_nullable = 'YES', '' , 'NOT NULL '),
        IF(column_default IS NOT NULL, concat('DEFAULT ', IF(column_default IN ('CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP()', 'NULL', 'b\'0\'', 'b\'1\''), column_default, CONCAT('\'',column_default,'\'') ), ' '), ''),
        IF(column_default IS NULL AND is_nullable = 'YES' AND column_key = '' AND column_type = 'timestamp','NULL ', ''),
        IF(column_default IS NULL AND is_nullable = 'YES' AND column_key = '','DEFAULT NULL ', ''),
        extra,
        ' COMMENT \'',
        column_comment,
        '\' ;') as script
FROM
    information_schema.columns
WHERE
    table_schema = 'sakila'
ORDER BY table_name , column_name;

SELECT 
table_name, TABLE_COMMENT
FROM
    information_schema.tables
WHERE table_schema = 'sakila';
