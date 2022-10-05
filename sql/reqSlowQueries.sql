SELECT ps.*
FROM INFORMATION_SCHEMA.PROCESSLIST ps
WHERE ps.Command <> 'Sleep'
  AND ps.user != 'system_user' ORDER BY TIME_MS DESC\G
