#!/bin/bash

source ./utils.sh 
source ./env_info.sh 
count_dir=${1:-"counts"}

rm -f $count_dir/result*
for cpatt in $( ls -1 counts|perl -pe 's/count_(Dump-\d{4}-\d{2}|ARCHIVE_\d{4})//g'|sort|uniq); do
	title1 "AGGREGATE FILES FOR $cpatt"
	output_file="$(echo $count_dir/result$cpatt|sed 's/\.txt/\.tsv/g')"
	info "OUTPUT FILE: "
	lst_cfile=$(ls -1 $count_dir| grep -Ev '^result_' | grep -E "$cpatt$"| sort -n)
	title1 "TABLES FROM FILES FOR $cpatt"
	lst_tables=$(ls -1 $count_dir| grep -E "$cpatt$"| xargs -I{} -n1 cat $count_dir/{} |awk '{print $1}' | sort -n | uniq)
	for tbname in $lst_tables; do
		echo -e "\t$tbname"
	done

	(
	echo -ne "table_name\t"
	for f in $lst_cfile; do
		echo -ne "$(echo $f| sed -e 's/count_//g;s/.txt//g')\t"
	done
	echo -e "total_archive\ttotal_dump\tdiff_arch_dump"

	for tbname in $lst_tables; do
		total_archive=0
		total_dump=0
		echo -ne "$tbname\t"
		for f in $lst_cfile; do
			val=$(grep -E "^$tbname\s" $count_dir/$f | awk '{print $2}')
			if [ -n "$val" ]; then
				echo -ne "$val\t"
				echo $f | grep -q 'Dump'
				if [ $? -eq 0 ];then
					total_dump=$(($total_dump+$val))
				else
					total_archive=$(($total_archive+$val))
				fi

			else
				echo -ne "-\t"
			fi
		done
		echo -ne "${total_archive}\t${total_dump}\t$(($total_archive-$total_dump))\n"
	done
	) > $output_file
	cat $output_file | column -t
done
