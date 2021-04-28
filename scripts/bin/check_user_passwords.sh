#!/bin/sh

[ -f '/etc/profile.d/utils.sh' ] && source /etc/profile.d/utils.sh

inputFile="/root/.pass_mariadb"
i=1
while IFS= read -r line
do
	muser=$(echo $line| awk '{print $7}')
	mpass=$(echo $line| awk '{print $8}')
  	check_mariadb_password $muser $mpass silent
  	if [ $? -eq 0 ]; then
  		echo -e "$muser => $mpass - Password OK"
#  	else
#  		echo -e "$muser => $mpass - Password FAIL"
  	fi
  	i=$(($i + 1))
done < "$inputFile"

exit $lRC
