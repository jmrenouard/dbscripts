# Playbook: Run script

This playbook runs a script on a remote host and fetches the results.

## Tasks

- **Local Cleanup**: Cleans up the output directory on the local machine.
- **Install Dependencies**: Installs dependencies for the script on the remote host.
- **Clean remotely**: Cleans up the temporary directory on the remote host.
- **Copy script**: Copies the script to the remote host.
- **Execute remotely**: Executes the script on the remote host.
- **Collect file list**: Collects the list of files to fetch from the remote host.
- **ansible copy result from remote to local**: Fetches the result files from the remote host.
- **Local Cleanup**: Displays the content of the fetched files.

## Variables

- `target`: The target host(s). Defaults to `mysql`.
- `outputdir`: The output directory on the local machine. Defaults to `result`.
- `script`: The script to run. Defaults to `scripts/export_info.py`.
- `tmpdir`: The temporary directory on the remote host. Defaults to `/var/tmp/generic`.
- `http_proxy`: The HTTP proxy to use. Defaults to `http://myproxy.local:3128`.
- `max_time`: The maximum execution time for the script. Defaults to `180`.
- `params`: The parameters to pass to the script. Defaults to `''`.
- `dependencies`: Whether to install dependencies. Defaults to `False`.

## Example Usage

To run this playbook, use the following command:

```bash
ansible-playbook run_script.yaml -e "target=your_target_host script=your_script.py"
```
