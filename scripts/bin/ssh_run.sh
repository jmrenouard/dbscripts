#!/bin/bash

###############################################################################
# SCRIPT: ssh_run.sh
# DESCRIPTION: Executes a given command on a list of nodes defined in a variable.
# AUTHOR: Jean-Marie Renouard
# DATE: 2024-04-18
#
# USAGE:
#   ./ssh_run.sh <variable_name_nodes> <command_to_run>
#
# ARGUMENTS:
#   <variable_name_nodes>: The name of the bash variable containing the list of nodes
#                          (space-separated).
#   <command_to_run>:      The command string to execute on each node.
#
# EXAMPLES:
#   # Define a variable with node names
#   export MY_NODES="node1.example.com node2.example.com 192.168.1.100"
#
#   # Run 'hostname -I' on all nodes in MY_NODES
#   ./ssh_run.sh MY_NODES 'hostname -I'
#
#   # Run 'df -h / | grep /' on all nodes in SERVER_LIST (assuming SERVER_LIST is defined)
#   ./ssh_run.sh SERVER_LIST 'df -h / | grep /'
#
# PREREQUISITES:
#   - SSH access configured (preferably with key-based authentication) to all target nodes
#     from the machine running this script.
#   - The variable containing the node list must be defined and accessible (e.g., exported).
#
# EXIT STATUS:
#   Exits with the sum of the exit codes of the commands executed on each node.
#   A total exit status of 0 indicates success on all nodes.
#   A non-zero value indicates that at least one command failed on one node.
###############################################################################

# Check if the necessary arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <variable_name_nodes> <command_to_run>"
    echo "Example: $0 NODE_LIST 'ls -l /tmp'"
    exit 1
fi

# Variable name containing the list of nodes
NODES_VARIABLE_NAME="$1"

# The command to execute on each node
COMMAND_TO_RUN="$2"

# Retrieve the value of the variable whose name is provided
# Use 'eval echo \$$NODES_VARIABLE_NAME' to get the variable value indirectly
# If the variable is not defined, this will return an empty string
NODES=$(eval echo \$$NODES_VARIABLE_NAME)

# Check if the variable contains a list of nodes
if [ -z "$NODES" ]; then
    echo "Error: Variable '$NODES_VARIABLE_NAME' is not defined or is empty."
    echo "Ensure the variable is exported if defined in another script."
    exit 1
fi

echo "Executing command '$COMMAND_TO_RUN' on the following nodes: $NODES"
echo "--------------------------------------------------"

# Initialize the total sum of exit statuses
TOTAL_EXIT_STATUS=0

# Loop through each node in the list
for NODE in $NODES; do
    echo "Executing on node: $NODE"
    # Execute the command on the node via SSH
    # The -T option disables pseudo-terminal allocation, useful for non-interactive commands
    # The -o BatchMode=yes option prevents password prompts
    # The -o ConnectTimeout=5 option sets a timeout for the SSH connection
    ssh -T -o BatchMode=yes -o ConnectTimeout=5 "$NODE" "$COMMAND_TO_RUN"
    # Capture the exit code of the SSH command
    SSH_EXIT_STATUS=$?

    if [ $SSH_EXIT_STATUS -eq 0 ]; then
        echo "Command executed successfully on $NODE."
    else
        echo "Error ($SSH_EXIT_STATUS) executing command on $NODE."
    fi

    # Add the exit code to the total sum
    TOTAL_EXIT_STATUS=$((TOTAL_EXIT_STATUS + SSH_EXIT_STATUS))

    echo "--------------------------------------------------"
done

echo "Execution finished on all specified nodes."
echo "Total sum of exit statuses: $TOTAL_EXIT_STATUS"

# Exit with the total sum of exit statuses
exit $TOTAL_EXIT_STATUS
