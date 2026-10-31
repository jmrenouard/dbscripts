# -----------------------------------------------------------------------------
# Script: cassandra_grant_generator_cqlsh.py
# Author: Jean-Marie RENOUARD (jmrenouard)
# Date: 2024-05-22
# Last Modified: 2024-05-23
#
# Description:
# This script connects to a Cassandra cluster using the cqlsh command-line
# utility to retrieve role and permission information from the
# system_auth.roles and system_auth.role_permissions tables.
# It then parses the output from cqlsh and generates the corresponding
# CQL GRANT statements.
# Includes support for SSL connections.
#
# Requirements:
# - Python 3.6+
# - cqlsh executable accessible via CQLSH_PATH, CQLSH environment variables,
#   or system PATH.
# - SSL certificates if SSL is used.
#
# Usage:
# 1. Configure Cassandra connection details (CASSANDRA_CONTACT_POINTS, etc.)
#    and SSL settings (if applicable) in this script.
# 2. Set the CQLSH_PATH or CQLSH environment variable if cqlsh is not in
#    the system PATH.
#    Example: export CQLSH_PATH=/opt/cassandra/bin/cqlsh
# 3. Run the script: python3 cassandra_grant_generator_cqlsh.py
#
# The generated GRANT statements will be printed to the console and saved
# to a .cql file.
# -----------------------------------------------------------------------------

import os
import subprocess
import re

# --- Cassandra Configuration (used for cqlsh arguments) ---
CASSANDRA_CONTACT_POINTS = ['127.0.0.1']  # Replace with your Cassandra contact points
CASSANDRA_PORT = '9042' # Port as a string for cqlsh
# Uncomment and configure if authentication is enabled
# CASSANDRA_USERNAME = 'your_user'
# CASSANDRA_PASSWORD = 'your_password'

# --- SSL Configuration (optional) ---
CASSANDRA_USE_SSL = False  # Set to True to enable SSL
# Path to the client certificate PEM file. This file can also contain the client's private key.
CASSANDRA_SSL_CERTFILE = None # e.g., '/path/to/client_cert_and_key.pem'
# Path to the client private key PEM file, if the key is not included in CASSANDRA_SSL_CERTFILE.
CASSANDRA_SSL_KEYFILE = None  # e.g., '/path/to/client_private.key'
# Path to the CA certificate file for server certificate validation.
# Note: For cqlsh, server validation with a custom CA might also rely on settings
# in the [ssl] section of a cqlshrc file or if the CA is in the system's trust store.
# The command-line options for CA certs are less direct with cqlsh itself.
# CASSANDRA_SSL_CA_CERTS = None # e.g., '/path/to/ca.crt' # cqlsh doesn't have a direct --ssl-ca-certs flag

# Path to the cqlsh executable (try CQLSH_PATH, then CQLSH, then default 'cqlsh')
CQLSH_EXECUTABLE = os.environ.get('CQLSH_PATH', os.environ.get('CQLSH', 'cqlsh'))

def execute_cqlsh_query(query_string):
    """
    Executes a given CQL query via the cqlsh executable and returns the raw output.
    """
    cmd = [CQLSH_EXECUTABLE]
    
    if CASSANDRA_CONTACT_POINTS:
        cmd.append(CASSANDRA_CONTACT_POINTS[0])
    if CASSANDRA_PORT:
        cmd.extend(['--port', CASSANDRA_PORT])

    # Authentication handling
    if 'CASSANDRA_USERNAME' in globals() and CASSANDRA_USERNAME:
        cmd.extend(['-u', CASSANDRA_USERNAME])
    if 'CASSANDRA_PASSWORD' in globals() and CASSANDRA_PASSWORD:
        cmd.extend(['-p', CASSANDRA_PASSWORD])

    # SSL handling
    if CASSANDRA_USE_SSL:
        cmd.append('--ssl')
        if CASSANDRA_SSL_CERTFILE:
            cmd.extend(['--ssl-certificate', CASSANDRA_SSL_CERTFILE])
        if CASSANDRA_SSL_KEYFILE: # Only add if keyfile is separate and specified
            cmd.extend(['--ssl-key', CASSANDRA_SSL_KEYFILE])
        # If CASSANDRA_SSL_CA_CERTS is set, cqlsh typically relies on cqlshrc or system store.
        # There isn't a direct cqlsh command-line flag like --ssl-ca-certs.
        # The Python driver (which cqlsh uses) can take 'ca_certs' in its SSL options,
        # but exposing this via cqlsh command line is limited.
        # Users might need to configure cqlshrc for custom CA validation.
        # Example for cqlshrc:
        # [ssl]
        # certfile = ~/.cassandra/ca.pem
        # validate = true

    cmd.extend(['-e', query_string])

    print(f"⚙️ Executing cqlsh: {' '.join(cmd)}")
    try:
        process = subprocess.run(cmd, capture_output=True, text=True, check=True, encoding='utf-8')
        return process.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ Error executing cqlsh for query: {query_string}")
        print(f"   Command: {' '.join(e.cmd)}")
        print(f"   Return code: {e.returncode}")
        print(f"   Stdout: {e.stdout}")
        print(f"   Stderr: {e.stderr}")
        return None
    except FileNotFoundError:
        print(f"❌ Error: cqlsh executable '{CQLSH_EXECUTABLE}' not found.")
        print(f"   Please check the CQLSH_PATH or CQLSH environment variable, or ensure cqlsh is in the PATH.")
        return None

def parse_cqlsh_output_for_roles(output):
    """
    Parses cqlsh output for the query on system_auth.roles.
    Returns a list of dictionaries {'role': role_name, 'member_of': set_of_parents}.
    """
    roles_data = []
    if not output:
        return roles_data

    lines = output.splitlines()

    header_index = -1
    separator_index = -1
    for i, line in enumerate(lines):
        if 'role' in line and 'member_of' in line: 
            header_index = i
        if '----' in line and header_index != -1 and i > header_index:
            separator_index = i
            break
    
    if header_index == -1 or separator_index == -1:
        print("⚠️ Could not find header or separator in cqlsh output for roles.")
        return roles_data

    for line in lines[separator_index + 1:]:
        line = line.strip()
        if not line or line.startswith('(') or line.startswith('Warning:'): 
            continue
        
        parts = [p.strip() for p in line.split('|')]
        if len(parts) >= 2: 
            role_name = parts[0]
            member_of_str = parts[1]

            if role_name.lower() == 'role' or role_name == '': 
                continue

            member_of_set = set()
            if member_of_str and member_of_str.lower() != 'null' and member_of_str != '':
                cleaned_member_of_str = member_of_str.replace('{', '').replace('}', '').replace("'", "")
                if cleaned_member_of_str:
                    member_of_set = {m.strip() for m in cleaned_member_of_str.split(',') if m.strip()}
            
            roles_data.append({'role': role_name, 'member_of': member_of_set})
        else:
            print(f"⚠️ Unparseable role line (incorrect number of parts): {line}")
            
    return roles_data


def parse_cqlsh_output_for_permissions(output):
    """
    Parses cqlsh output for the query on system_auth.role_permissions.
    Returns a dictionary {role: [{'resource': res, 'permissions': set_perms}]}.
    """
    permissions_map = {}
    if not output:
        return permissions_map

    lines = output.splitlines()

    header_index = -1
    separator_index = -1
    for i, line in enumerate(lines):
        if 'role' in line and 'resource' in line and 'permissions' in line:
            header_index = i
        if '----' in line and header_index != -1 and i > header_index:
            separator_index = i
            break
            
    if header_index == -1 or separator_index == -1:
        print("⚠️ Could not find header or separator in cqlsh output for permissions.")
        return permissions_map

    for line in lines[separator_index + 1:]:
        line = line.strip()
        if not line or line.startswith('(') or line.startswith('Warning:'):
            continue

        parts = [p.strip() for p in line.split('|')]
        if len(parts) >= 3: 
            role_name = parts[0]
            resource_str = parts[1]
            permissions_str = parts[2]

            if role_name.lower() == 'role' or role_name == '': 
                continue

            permissions_set = set()
            if permissions_str and permissions_str.lower() != 'null' and permissions_str != '':
                cleaned_permissions_str = permissions_str.replace('{', '').replace('}', '').replace("'", "")
                if cleaned_permissions_str:
                    permissions_set = {p.strip().upper() for p in cleaned_permissions_str.split(',') if p.strip()}
            
            if role_name not in permissions_map:
                permissions_map[role_name] = []
            permissions_map[role_name].append({
                "resource": resource_str,
                "permissions": permissions_set
            })
        else:
            print(f"⚠️ Unparseable permission line (incorrect number of parts): {line}")
            
    return permissions_map


def generate_cql_grants():
    """
    Retrieves roles and permissions via cqlsh and generates CQL GRANT statements.
    """
    cql_grants = []

    print("\n📜 Reading roles via cqlsh (system_auth.roles)...")
    roles_query = "SELECT role, member_of FROM system_auth.roles;"
    roles_output = execute_cqlsh_query(roles_query)
    
    if roles_output is None:
        print("❌ Aborting: Could not retrieve roles.")
        return []

    parsed_roles = parse_cqlsh_output_for_roles(roles_output)
    if not parsed_roles:
        print("⚠️ No roles found or parsing failed.")
    else:
        print(f"🔍 Parsed roles: {len(parsed_roles)}")

    print("\n🔑 Reading permissions via cqlsh (system_auth.role_permissions)...")
    permissions_query = "SELECT role, resource, permissions FROM system_auth.role_permissions;"
    permissions_output = execute_cqlsh_query(permissions_query)

    if permissions_output is None:
        print("❌ Aborting: Could not retrieve permissions.")
    
    role_permissions_map = parse_cqlsh_output_for_permissions(permissions_output)
    if not role_permissions_map and permissions_output is not None: 
        print("⚠️ No permissions found or parsing failed.")
    elif role_permissions_map:
         print(f"🔍 Parsed permissions for {len(role_permissions_map)} roles.")

    print("\n⚙️ Generating GRANT ON RESOURCE commands...")
    all_role_names_from_roles_table = {r['role'] for r in parsed_roles if r['role'] and not r['role'].startswith('cassandra')}
    all_role_names_from_perms_table = {role for role in role_permissions_map if role and not role.startswith('cassandra')}
    
    for role_name in sorted(list(all_role_names_from_roles_table.union(all_role_names_from_perms_table))):
        if role_name.startswith('cassandra'): 
            continue
        if role_name in role_permissions_map:
            permissions_list = role_permissions_map[role_name]
            for perm_info in permissions_list:
                resource = perm_info['resource']
                cql_resource = ""

                if resource == 'data':
                    cql_resource = "ALL KEYSPACES"
                elif resource.startswith('data/'):
                    parts = resource.split('/')
                    if len(parts) == 2: 
                        cql_resource = f"KEYSPACE \"{parts[1]}\"" 
                    elif len(parts) == 3: 
                        cql_resource = f"TABLE \"{parts[1]}\".\"{parts[2]}\""
                    else:
                        cql_resource = f"\"{resource}\"" 
                elif resource.startswith('roles/'):
                    cql_resource = f"ROLE \"{resource.split('/')[1]}\""
                elif resource.startswith('keyspaces/'): 
                     cql_resource = f"KEYSPACE \"{resource.split('/')[1]}\""
                else:
                    cql_resource = f"\"{resource}\"" 

                for permission in sorted(list(perm_info['permissions'])):
                    grant_cql = f"GRANT {permission.upper()} ON {cql_resource} TO \"{role_name}\";"
                    cql_grants.append(grant_cql)

    print("\n🔗 Generating GRANT ROLE (membership) commands...")
    for role_info in parsed_roles:
        child_role = role_info['role']
        if child_role.startswith('cassandra'): 
            continue
        if role_info['member_of']:
            for parent_role in sorted(list(role_info['member_of'])):
                if parent_role.startswith('cassandra'): 
                    continue
                grant_role_cql = f"GRANT \"{parent_role}\" TO \"{child_role}\";"
                cql_grants.append(grant_role_cql)
                
    return sorted(list(set(cql_grants)))

if __name__ == "__main__":
    print(f"🚀 Starting CQL GRANT generation script via cqlsh (using: {CQLSH_EXECUTABLE})...")
    
    if not os.path.exists(CQLSH_EXECUTABLE) and '/' not in CQLSH_EXECUTABLE and '\\' not in CQLSH_EXECUTABLE:
        try:
            subprocess.run([CQLSH_EXECUTABLE, '--version'], capture_output=True, check=True)
            print(f"✅ cqlsh executable '{CQLSH_EXECUTABLE}' found and functional.")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"❌ Error: cqlsh executable '{CQLSH_EXECUTABLE}' not found or not executable.")
            print(f"   Please set the CQLSH_PATH or CQLSH environment variable, or ensure 'cqlsh' is in your system PATH.")
            exit(1)
    elif not os.path.exists(CQLSH_EXECUTABLE):
         print(f"❌ Error: cqlsh executable specified by CQLSH_PATH/CQLSH '{CQLSH_EXECUTABLE}' does not exist.")
         exit(1)
    else:
        print(f"✅ Using cqlsh from: {CQLSH_EXECUTABLE}")

    generated_grants = generate_cql_grants()

    if generated_grants:
        print("\n\n--- GENERATED CQL GRANT COMMANDS ---")
        for grant_statement in generated_grants:
            print(grant_statement)
        
        output_filename = "grants_cassandra_from_cqlsh.cql"
        try:
            with open(output_filename, "w", encoding='utf-8') as f:
                for grant_statement in generated_grants:
                    f.write(grant_statement + "\n")
            print(f"\n📝 Commands have been saved to {output_filename}")
        except IOError as e:
            print(f"\n❌ Error writing to file {output_filename}: {e}")
    else:
        print("\n🤷 No GRANT commands were generated (or an error occurred).")
