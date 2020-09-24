zcat $1 | time mysql -f -v

(
cd /var/lib/mysql
du -s *| sort -nr | head -n 5 | awk '{ print $2}' | xargs -n 1 du -sh
)
