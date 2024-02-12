OPTIMIZE TABLE oc_filecache;
SELECT USER FROM oc_files_trash WHERE USER LIKE '%lightpath.fr' GROUP BY USER;
SELECT COUNT(*) FROM oc_files_trash;
SELECT COUNT(*) FROM oc_filecache f WHERE path LIKE '%trashbin%' ;

SELECT * FROM oc_filecache f WHERE path LIKE '%trashbin%' LIMIT 50;

oc_jobs
SELECT * INTO OUTFILE '/tmp/filecache_errors.txt' 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM oc_filecache fc
Where fc.fileid in ( 10675, 20576, 1325767) ;

SELECT * INTO OUTFILE '/tmp/share_errors.txt' 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM oc_share s
Where s.file_source in ( 10675, 20576, 1325767) ;


 select * from pocnextclouddb_ppdriveapp1.oc_migrations where app = 'groupfolders';
 select * from pocnextclouddb_ppdriveapp2.oc_migrations where app = 'groupfolders';
 
 
 oc_jobs
 
 WHERE fc.fileid IN ( 1210265 );