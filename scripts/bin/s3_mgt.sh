#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

# Script to manage S3 subdirectories with AWS CLI.
# This script allows listing all subdirectories, listing the subdirectories to delete, or deleting old subdirectories.
# Parameters:
#   -p <aws_profile>: AWS CLI profile to use
#   -b <bucket_url>: URL of the S3 bucket
#   -t <path>: Path within the bucket
#   -n <num_to_keep>: Number of subdirectories to keep
#   -a <action>: Action to perform (list_all, list_to_delete, delete)
# Actions:
#   list_all: List all subdirectories
#   list_to_delete: List subdirectories that will be deleted
#   delete: Delete old subdirectories, keeping only the specified number

# Generic function to get the list of subdirectories
get_subdirectories() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  path_prefix=$(echo $path_prefix | perl -pe 's#/$##g')
  aws --profile ${aws_profile} s3 ls ${bucket_url}/${path_prefix}/ | grep 'PRE' | awk '{print $2}'
}

# Function to list all subdirectories (non-recursive)
list_all_subdirs() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  path_prefix=$(echo $path_prefix | perl -pe 's#/$##g')

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix")
  echo "All subdirectories in ${bucket_url}/${path_prefix}:"
  echo "$subdirectories" | sort -n
}

# Function to list subdirectories to be deleted (non-recursive)
list_subdirs_to_delete() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  local num_to_keep=${4:-10}
  path_prefix=$(echo $path_prefix | perl -pe 's#/$##g')

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix" | sort)
  local total_subdirs=$(echo "$subdirectories" | wc -l)
  local num_to_delete=$((total_subdirs - num_to_keep))
  if [ "$num_to_delete" -gt 0 ]; then
    local subdirs_to_delete=$(echo "$subdirectories" | head -n $num_to_delete)
    echo "Subdirectories to delete in ${bucket_url}/${path_prefix}:"
    echo "$subdirs_to_delete"
  else
    echo "Nothing to delete in ${bucket_url}/${path_prefix}"
  fi
}

# Function to delete subdirectories (non-recursive)
delete_subdirs() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  local num_to_keep=$4
  path_prefix=$(echo $path_prefix | perl -pe 's#/$##g')

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix" | sort)
  local total_subdirs=$(echo "$subdirectories" | wc -l)
  local num_to_delete=$((total_subdirs - num_to_keep))

  if [ "$num_to_delete" -gt 0 ]; then
    local subdirs_to_delete=$(echo "$subdirectories" | head -n $num_to_delete)
    for dir_to_delete in $subdirs_to_delete; do
      echo "Deleting subdirectory: ${bucket_url}/${path_prefix}/${dir_to_delete}"
      aws --profile ${aws_profile} s3 rm --recursive ${bucket_url}/${path_prefix}/${dir_to_delete}
    done
  else
    echo "Nothing to delete in ${bucket_url}/${path_prefix}"
  fi
}

# Function to handle command line arguments
usage() {
  echo "Usage: $0 -p <aws_profile> -b <bucket_url> -t <path> [-n <num_to_keep>] [-a <action>]"
  echo "Actions: list_all (default), list_to_delete, delete"
  exit 1
}

num_to_keep=10
action="list_all"
while getopts ":p:b:t:n::a::" opt; do
  case $opt in
    p) aws_profile="$OPTARG";;
    b) bucket_url="$OPTARG";;
    t) path_prefix="$OPTARG";;
    n) num_to_keep="${OPTARG:-10}";;
    a) action="${OPTARG:-list_all}";;
    *) usage;;
  esac
done

# Verify that all parameters are passed
if [ -z "$aws_profile" ] || [ -z "$bucket_url" ] || [ -z "$path_prefix" ]; then
  usage
fi

# Call the appropriate function based on the action
case $action in
  list_all)
    list_all_subdirs "$aws_profile" "$bucket_url" "$path_prefix";;
  list_to_delete)
    list_subdirs_to_delete "$aws_profile" "$bucket_url" "$path_prefix" "$num_to_keep";;
  delete)
    delete_subdirs "$aws_profile" "$bucket_url" "$path_prefix" "$num_to_keep";;
  *)
    echo "Invalid action: $action"
    usage
    ;;
esac

echo "Operation completed."
