#!/bin/bash

_SCRIPT_PATH="$(readlink -f $0)"
_DIR="$(dirname $_SCRIPT_PATH)/.."
_DIR="$(readlink -f $_DIR)"
echo "repo dir: $_DIR"

# Check if there is AWS secret
(
	cd $_DIR
	lRC=0

PATTERN_LIST="#SLACK.*URL
secret
credential
password
alias.*ssh.*
AWS
AWS_SECRET
AWS_SECRET_ACCESS
AWS_ACCESS_KEY
AWS.*KEY
AKIA
(contra|alice|tarif|acquisition|abonnement|facturation|compte|client|service|offre|forfait|tarif)
(datanumia|edelia|reanater|isocel|galec|orange|sfr|bouygues|numericable|vodafone|telecom)

(prod_|prd[-_]|[-_]home[-_]|[-_]ec2[-_])"
for ptn in $PATTERN_LIST; do
	
	echo -n "$ptn" | grep -qE "^\s*$" && continue
	echo -n "$ptn" | grep -qE "^\s*#" && continue
	
	echo "Pattern: $ptn"
	echo "-----------------------------------"
	grep -rEin "$ptn"
	lRC=$(($lRC + $?))

done
find $_DIR -type f -iname ".*secret.*" 
lRC=$(($lRC + $?))

find $_DIR -type f -iname ".*pass.*" 
lRC=$(($lRC + $?))

find $_DIR -type f -iname ".*id.*"
lRC=$(($lRC + $?))

find $_DIR -type f -iname ".*schema.*.sql.*" 
lRC=$(($lRC + $?))

echo "lRC: $lRC"
) | grep -vE '(myconf/checkSecrets.sh|.git/)'
