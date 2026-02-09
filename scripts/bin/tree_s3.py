#!/usr/bin/env python3
r""" 
Script to display the contents of an AWS S3 bucket in a tree structure.

This script uses the AWS CLI to list the files in an S3 bucket and then displays
them in a tree-like structure with details such as size and last modified date.
It supports filtering the output using regular expressions.

Usage:
    python s3_tree_view_with_aws.py <bucket_name> [path] [filter] [--profile <aws_profile>]

Arguments:
    bucket_name : The name of the S3 bucket to be listed.
    path        : The path within the bucket to list (optional).
    filter      : A raw regular expression (e.g., r".*\.txt") to filter the output (optional).
    --profile   : The AWS profile to use (optional).

Example:
    python s3_tree_view_with_aws.py my-bucket some/path r".*\.txt" --profile myprofile

Dependencies:
    - AWS CLI must be installed and configured with the necessary permissions.
    - Python 3

Modules:
    - subprocess: To execute AWS CLI commands.
    - argparse: To parse command-line arguments.
    - re: To filter results using regular expressions.
"""

import subprocess
import argparse
import re
import math

def get_s3_output(bucket_name, path, profile):
    # Execute the AWS S3 ls command to get the list of files
    command = ["aws", "s3", "ls", f"s3://{bucket_name}/{path}", "--recursive", "--human-readable", "--summarize"]
    # Add profile to the command if specified
    if profile:
        command.extend(["--profile", profile])
    result = subprocess.run(command, capture_output=True, text=True)

    # Check if the command was successful
    if result.returncode != 0:
        print(f"Error executing AWS command: {result.stderr}")
        return None

    # Split the output into lines and return
    return result.stdout.splitlines()

def filter_s3_output(s3_output, regex):
    # If a regex is provided, filter the lines that match the pattern
    if regex:
        pattern = re.compile(r'{}'.format(regex))
        return [line for line in s3_output if pattern.search(line)]
    return s3_output

def parse_size(size_str, unit):
    # Parse the size string and convert it to bytes
    size_map = {"Bytes": 1, "KiB": 1024, "MiB": 1024**2, "GiB": 1024**3}
    return float(size_str) * size_map.get(unit, 1)

def build_tree(s3_output):
    tree = {}
    for line in s3_output:
        # Skip empty lines and summary lines (which start with "Total")
        if line.strip() and not line.startswith("Total"):
            parts = line.split(maxsplit=4)
            if len(parts) > 4:  # Expected format: Date, Time, Size, Unit, Path
                date = f"{parts[0]} {parts[1]}"  # Extract date and time
                size = f"{parts[2]} {parts[3]}"  # Extract size and unit
                path = parts[4]  # Extract the file path
                size_value = parse_size(parts[2], parts[3])  # Parse size value
                
                # Navigate through the tree dictionary to create the hierarchical structure
                current_level = tree
                path_parts = path.split('/')
                for i, part in enumerate(path_parts):
                    if part not in current_level:
                        current_level[part] = {'_files': 0, '_dirs': 0, '_size': 0, '_info': None}
                    current_level = current_level[part]

                # Store size and date information for the final file
                if '.' in path_parts[-1]:
                    current_level['_info'] = {'date': date, 'size': size}
                    current_level['_size'] += size_value
                    # Update file count for all parent directories
                    parent_level = tree
                    for part in path_parts[:-1]:
                        parent_level = parent_level[part]
                        parent_level['_files'] += 1
                        parent_level['_size'] += size_value
                else:
                    # Update directory count for parent directories
                    parent_level = tree
                    for part in path_parts[:-1]:
                        parent_level = parent_level[part]
                        parent_level['_dirs'] += 1
                    current_level['_size'] += size_value

    return tree

def print_tree(tree, prefix=""):
    for key, subtree in tree.items():
        if key == '_info':
            continue  # Skip the '_info' key as it stores metadata, not a tree node

        # If the current node is a directory, print its total size and counts
        if isinstance(subtree, dict) and subtree['_info'] is None:
            size_human_readable = convert_size(subtree['_size'])
            print(f"{prefix}├── {key} (Total size: {size_human_readable}, Files: {subtree['_files']})")
            # Recursively print the subtree with an updated prefix for indentation
            print_tree(subtree, prefix + "│   ")

        # If the current node is a file, print its details (date and human-readable size)
        elif isinstance(subtree, dict) and subtree['_info'] is not None:
            file_info = subtree['_info']
            print(f"{prefix}├── {key} (Size: {file_info['size']}, Date: {file_info['date']})")

def convert_size(size_bytes):
    # Convert the size from bytes to a human-readable format
    if size_bytes == 0:
        return "0B"
    size_name = ("Bytes", "KiB", "MiB", "GiB", "TiB", "PiB")
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Display the contents of an S3 bucket in a tree structure.")
    parser.add_argument("bucket_name", help="Name of the S3 bucket")
    parser.add_argument("path", help="Path within the S3 bucket", nargs='?', default="")
    parser.add_argument("filter", help="Regular expression to filter results", nargs='?', default=None)
    parser.add_argument("--profile", help="AWS profile to use", default=None)
    args = parser.parse_args()

    # Get the S3 output for the specified bucket, path, and profile
    s3_output = get_s3_output(args.bucket_name, args.path, args.profile)

    # If the S3 output is valid, filter and build the tree
    if s3_output:
        filtered_output = filter_s3_output(s3_output, args.filter)
        s3_tree = build_tree(filtered_output)
        # Print the tree structure
        print_tree(s3_tree)
