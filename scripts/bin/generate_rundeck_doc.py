#!/usr/bin/env python3
# generate_rundeck_doc.py - Generate Markdown documentation from Rundeck YAML job files

import os
import sys
import yaml
import argparse
from datetime import datetime
import re
import shutil


def sanitize_filename(filename):
    """Sanitize a string to be used as a filename"""
    # Replace spaces and special chars with underscore
    sanitized = re.sub(r'[^\w\-\.]', '_', filename)
    # Remove multiple consecutive underscores
    sanitized = re.sub(r'_+', '_', sanitized)
    # Remove leading/trailing underscores
    return sanitized.strip('_')


def create_job_documentation(job_data, output_dir, job_file=None):
    """Create markdown documentation for a single job"""
    # Extract job metadata
    name = job_data.get('name', 'Unnamed Job')
    description = job_data.get('description', 'No description available')
    group = job_data.get('group', 'No group')
    
    # Create directory structure based on group hierarchy
    group_path = os.path.join(output_dir, *group.split('/')) if group != 'No group' else output_dir
    os.makedirs(group_path, exist_ok=True)
    
    # Create filename
    filename = sanitize_filename(name) + ".md"
    file_path = os.path.join(group_path, filename)
    
    # Create the Markdown content
    content = []
    content.append(f"# {name}\n")
    
    # Job source file
    if job_file:
        content.append(f"**Source File**: `{os.path.basename(job_file)}`\n")
    
    # Basic Job Information
    content.append("## Description\n")
    content.append(f"{description}\n")
    
    content.append("## Job Details\n")
    content.append(f"- **Group**: {group}")
    content.append(f"- **UUID**: {job_data.get('uuid', 'N/A')}")
    content.append(f"- **Project**: {job_data.get('project', 'N/A')}")
    
    # Schedule
    schedule = job_data.get('schedule', {})
    if schedule:
        content.append("\n## Schedule\n")
        time_zone = schedule.get('timeZone', 'N/A')
        cron = schedule.get('crontabString', 'N/A')
        content.append(f"- **Timezone**: {time_zone}")
        content.append(f"- **Cron Expression**: `{cron}`")
    
    # Options
    options = job_data.get('options', [])
    if options:
        content.append("\n## Options\n")
        content.append("| Name | Description | Default Value | Required |")
        content.append("|------|-------------|---------------|----------|")
        for option in options:
            name = option.get('name', 'N/A')
            desc = option.get('description', 'No description').replace('\n', ' ')
            default = option.get('value', 'None')
            required = 'Yes' if option.get('required', False) else 'No'
            content.append(f"| {name} | {desc} | {default} | {required} |")

    # Node filters
    node_filters = job_data.get('nodefilters', {})
    if node_filters:
        content.append("\n## Node Filters\n")
        filter_str = node_filters.get('filter', 'N/A')
        content.append(f"- **Filter**: `{filter_str}`")
        
        # Include/exclude
        for filter_type in ['include', 'exclude']:
            if filter_type in node_filters:
                content.append(f"\n### {filter_type.capitalize()} Filters")
                for category, values in node_filters[filter_type].items():
                    content.append(f"- **{category}**: {', '.join(values)}")
    
    # Notification
    notifications = job_data.get('notification', {})
    if notifications:
        content.append("\n## Notifications\n")
        for event_type, notification in notifications.items():
            content.append(f"### {event_type.capitalize()}")
            
            for plugin, config in notification.items():
                content.append(f"\n#### {plugin.capitalize()}")
                if isinstance(config, dict):
                    for key, value in config.items():
                        content.append(f"- **{key}**: {value}")
                else:
                    content.append(f"- {config}")
    
    # Workflow steps
    workflow = job_data.get('sequence', {}).get('commands', [])
    if workflow:
        content.append("\n## Workflow Steps\n")
        for idx, step in enumerate(workflow, 1):
            step_type = list(step.keys())[0] if step else "Unknown"
            content.append(f"### Step {idx}: {step_type}\n")
            
            if step_type == 'exec':
                content.append("```bash")
                content.append(step.get('exec', ''))
                content.append("```\n")
            elif step_type == 'script':
                script = step.get('script', '')
                content.append("Script content:")
                content.append("```")
                content.append(script)
                content.append("```\n")
            elif step_type == 'job':
                job_ref = step.get('job', {})
                job_name = job_ref.get('name', 'Unknown job')
                job_group = job_ref.get('group', 'No group')
                content.append(f"Runs job: **{job_group}/{job_name}**\n")
                
                # Add job options if available
                job_args = job_ref.get('args', '')
                if job_args:
                    content.append(f"With arguments: `{job_args}`\n")
            else:
                # Generic handling for other step types
                content.append(f"```yaml")
                content.append(yaml.dump(step, default_flow_style=False))
                content.append("```\n")
    
    # Write the content to the file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(content))
    
    return file_path


def generate_rundeck_documentation(yaml_dir, output_dir):
    """Generate markdown documentation from Rundeck YAML job files"""
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Track all generated files
    generated_files = []
    
    # Process all YAML files in the directory and subdirectories
    for root, _, files in os.walk(yaml_dir):
        for file in files:
            if file.endswith(('.yaml', '.yml')):
                yaml_file = os.path.join(root, file)
                
                try:
                    with open(yaml_file, 'r', encoding='utf-8') as f:
                        # Rundeck YAML files typically contain an array of job definitions
                        job_data_list = yaml.safe_load(f)
                        
                        # Process each job in the file
                        if isinstance(job_data_list, list):
                            for job_data in job_data_list:
                                file_path = create_job_documentation(job_data, output_dir, yaml_file)
                                generated_files.append(file_path)
                        elif isinstance(job_data_list, dict):
                            # Handle single job case
                            file_path = create_job_documentation(job_data_list, output_dir, yaml_file)
                            generated_files.append(file_path)
                
                except Exception as e:
                    print(f"Error processing {yaml_file}: {e}", file=sys.stderr)
    
    # Generate index file
    index_path = os.path.join(output_dir, "README.md")
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write("# Rundeck Jobs Documentation\n\n")
        f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"Total Jobs: {len(generated_files)}\n\n")
        
        # Create hierarchical job listing
        job_structure = {}
        for file_path in generated_files:
            rel_path = os.path.relpath(file_path, output_dir)
            parts = rel_path.split(os.sep)
            
            # Navigate the job_structure dict to build the tree
            current = job_structure
            for i, part in enumerate(parts[:-1]):  # All parts except the filename
                if part not in current:
                    current[part] = {}
                current = current[part]
            
            # Add the file as a leaf node
            filename = parts[-1]
            current[filename] = rel_path
        
        # Function to write the job structure recursively
        def write_structure(structure, level=0, parent_path=""):
            items = sorted(structure.items())
            for name, value in items:
                indent = "  " * level
                
                if isinstance(value, dict):
                    # This is a directory
                    f.write(f"{indent}- **{name}/**\n")
                    write_structure(value, level + 1, os.path.join(parent_path, name))
                else:
                    # This is a file
                    job_name = os.path.splitext(name)[0].replace('_', ' ')
                    f.write(f"{indent}- [{job_name}]({value})\n")
        
        f.write("## Job List\n\n")
        write_structure(job_structure)
    
    generated_files.append(index_path)
    return generated_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate Markdown documentation from Rundeck YAML job files')
    parser.add_argument('--input-dir', required=True, help='Directory containing Rundeck YAML job files')
    parser.add_argument('--output-dir', required=True, help='Output directory for Markdown files')
    parser.add_argument('--clean', action='store_true', help='Clean output directory before generation')
    
    args = parser.parse_args()
    
    if args.clean and os.path.exists(args.output_dir):
        print(f"Cleaning output directory: {args.output_dir}")
        shutil.rmtree(args.output_dir)
    
    print(f"Generating documentation from {args.input_dir} to {args.output_dir}")
    generated_files = generate_rundeck_documentation(args.input_dir, args.output_dir)
    print(f"Documentation generated successfully. {len(generated_files)} files created.")
