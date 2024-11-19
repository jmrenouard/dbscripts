#!/bin/bash

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
  aws s3 ls ${bucket_url}/${path_prefix} --profile ${aws_profile} | grep 'PRE' | awk '{print $2}'
}

# Function to list all sub-subdirectories
list_all_subsubdirs() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix")
  for subdir in $subdirectories; do
    echo "All sub-subdirectories in ${bucket_url}/${path_prefix}${subdir}:"
    get_subdirectories "$aws_profile" "$bucket_url" "${path_prefix}${subdir}"
  done
}

# Function to list sub-subdirectories to be deleted
list_subsubdirs_to_delete() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  local num_to_keep=$4

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix")
  for subdir in $subdirectories; do
    local subsubdirs=$(get_subdirectories "$aws_profile" "$bucket_url" "${path_prefix}${subdir}" | sort)
    local total_subsubdirs=$(echo "$subsubdirs" | wc -l)
    local num_to_delete=$((total_subsubdirs - num_to_keep))

    if [ "$num_to_delete" -gt 0 ]; then
      local subsubdirs_to_delete=$(echo "$subsubdirs" | head -n $num_to_delete)
      echo "Sub-subdirectories to delete in ${bucket_url}/${path_prefix}${subdir}:"
      echo "$subsubdirs_to_delete"
    else
      echo "Nothing to delete in subdirectory: $subdir"
    fi
  done
}

# Function to delete sub-subdirectories
delete_subsubdirs() {
  local aws_profile=$1
  local bucket_url=$2
  local path_prefix=$3
  local num_to_keep=$4

  local subdirectories=$(get_subdirectories "$aws_profile" "$bucket_url" "$path_prefix")
  for subdir in $subdirectories; do
    local subsubdirs=$(get_subdirectories "$aws_profile" "$bucket_url" "${path_prefix}${subdir}" | sort)
    local total_subsubdirs=$(echo "$subsubdirs" | wc -l)
    local num_to_delete=$((total_subsubdirs - num_to_keep))

    if [ "$num_to_delete" -gt 0 ]; then
      local subsubdirs_to_delete=$(echo "$subsubdirs" | head -n $num_to_delete)
      for dir_to_delete in $subsubdirs_to_delete; do
        echo "Deleting subdirectory: ${bucket_url}/${path_prefix}${subdir}${dir_to_delete}"
        aws s3 rm --recursive ${bucket_url}/${path_prefix}${subdir}${dir_to_delete} --profile ${aws_profile}
      done
    else
      echo "Nothing to delete in subdirectory: $subdir"
    fi
  done
}

# Function to handle command line arguments
usage() {
  echo "Usage: $0 -p <aws_profile> -b <bucket_url> -t <path> -n <num_to_keep> -a <action>"
  echo "Actions: list_all, list_to_delete, delete"
  exit 1
}

while getopts ":p:b:t:n:a:" opt; do
  case $opt in
    p) aws_profile="$OPTARG";;
    b) bucket_url="$OPTARG";;
    t) path_prefix="$OPTARG";;
    n) num_to_keep="$OPTARG";;
    a) action="$OPTARG";;
    *) usage;;
  esac
done

# Verify that all parameters are passed
if [ -z "$aws_profile" ] || [ -z "$bucket_url" ] || [ -z "$path_prefix" ] || [ -z "$num_to_keep" ] || [ -z "$action" ]; then
  usage
fi

# Call the appropriate function based on the action
case $action in
  list_all)
    list_all_subsubdirs "$aws_profile" "$bucket_url" "$path_prefix";;
  list_to_delete)
    list_subsubdirs_to_delete "$aws_profile" "$bucket_url" "$path_prefix" "$num_to_keep";;
  delete)
    delete_subsubdirs "$aws_profile" "$bucket_url" "$path_prefix" "$num_to_keep";;
  *)
    echo "Invalid action: $action"
    usage
    ;;
esac

echo "Operation completed."
