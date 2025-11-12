#!/usr/bin/env python3
# generate_rundeck_doc.py - Generate Markdown documentation from Rundeck YAML job files

import os
import sys
import yaml
import argparse
from datetime import datetime
import re
import shutil
import codecs


def sanitize_filename(filename):
    """Sanitize a string to be used as a filename"""
    # Replace spaces and special chars with underscore
    sanitized = re.sub(r'[^\w\-\.]', '_', filename)
    # Remove multiple consecutive underscores
    sanitized = re.sub(r'_+', '_', sanitized)
    # Remove leading/trailing underscores
    return sanitized.strip('_')

def format_bash_script(script_string):
    # Remplacer les séquences d'échappement par leurs caractères
    script_string = script_string.replace("\\n", "\n")
    script_string = script_string.replace("\\t", "\t")
    script_string = script_string.replace("\\\\", "\\")
    script_string = script_string.replace("\\\"", "\"")
    
    # Gérer les caractères spéciaux encodés en hexadécimal
    script_string = script_string.replace("\\xE9", "é")
    script_string = script_string.replace("\\xE8", "è")
    script_string = script_string.replace("\\xE0", "à")
    script_string = script_string.replace("\\xE7", "ç")
    script_string = script_string.replace("\\xD4", "Ô")
    script_string = script_string.replace("\\xC9", "É")
    
    return script_string

def process_escaped_script(script_content):
    """Process escaped script content to make it more readable"""
    if not isinstance(script_content, str):
        return script_content
    
    try:
        # First handle the script: prefix pattern if present
        if script_content.startswith('script: '):
            script_content = script_content[8:]
        
        # Handle quoted strings
        if (script_content.startswith('"') and script_content.endswith('"')) or \
           (script_content.startswith("'") and script_content.endswith("'")):
            script_content = script_content[1:-1]
        
        # Remplacer les séquences d'échappement littérales \\n par de vrais sauts de ligne
        script_content = script_content.replace('\\n', '\n')
        script_content = script_content.replace('\\t', '\t')
        
        # Handle hex encoded characters (like \xD4 for Ô)
        script_content = re.sub(r'\\x([0-9A-Fa-f]{2})', 
                      lambda m: chr(int(m.group(1), 16)), 
                      script_content)
        
        # Remplacer les doubles barres obliques par des simples
        script_content = script_content.replace('\\\\', '\\')
        
        # Gérer les guillemets échappés
        script_content = script_content.replace('\\"', '"')
        script_content = script_content.replace('\\\'', '\'')
        script_content = script_content.replace('\\', '')
        return script_content
    except Exception as e:
        print(f"Warning: Error processing script content: {e}", file=sys.stderr)
        return script_content


def create_job_documentation(job_data, output_dir, job_file=None):
    """Create markdown documentation for a single job"""
    # Extract job metadata
    name = job_data.get('name', 'Tâche sans nom')
    description = job_data.get('description', 'Aucune description disponible')
    group = job_data.get('group', 'Sans groupe')
    
    # Create directory structure based on group hierarchy
    group_path = os.path.join(output_dir, *group.split('/')) if group != 'Sans groupe' else output_dir
    os.makedirs(group_path, exist_ok=True)
    
    # Create filename
    filename = sanitize_filename(name) + ".md"
    file_path = os.path.join(group_path, filename)
    
    # Create the Markdown content
    content = []
    content.append(f"# {name}\n")
    
    # Table of contents
    content.append("## Table des matières\n")
    
    # Add TOC entries - start with basic sections that are always present
    toc_entries = ["Description", "Détails de la tâche"]
    
    # Add conditional TOC entries based on job properties
    if job_data.get('schedule'):
        toc_entries.append("Planification")
    if job_data.get('options'):
        toc_entries.append("Options")
    if job_data.get('nodefilters'):
        toc_entries.append("Filtres de nœuds")
    if job_data.get('notification'):
        toc_entries.append("Notifications")
    if job_data.get('sequence', {}).get('commands'):
        toc_entries.append("Étapes du workflow")
    
    # Generate TOC links
    for entry in toc_entries:
        # Create anchor link - lowercase, replace spaces with dashes
        anchor = entry.lower().replace(" ", "-").replace("œ", "oe")
        content.append(f"- [{entry}](#{anchor})")
    
    content.append("\n")
    
    # Job source file
    if job_file:
        content.append(f"**Fichier source**: `{os.path.basename(job_file)}`\n")
    
    # Basic Job Information
    content.append("## Description\n")
    content.append(f"{description}\n")
    
    content.append("## Détails de la tâche\n")
    content.append(f"- **Groupe**: {group}")
    content.append(f"- **UUID**: {job_data.get('uuid', 'N/A')}")
    content.append(f"- **Projet**: {job_data.get('project', 'N/A')}")
    
    # Schedule
    schedule = job_data.get('schedule', {})
    if schedule:
        content.append("\n## Planification\n")
        time_zone = schedule.get('timeZone', 'N/A')
        cron = schedule.get('crontabString', 'N/A')
        content.append(f"- **Fuseau horaire**: {time_zone}")
        content.append(f"- **Expression Cron**: `{cron}`")
    
    # Options
    options = job_data.get('options', [])
    if options:
        content.append("\n## Options\n")
        content.append("| Nom | Description | Valeur par défaut | Obligatoire |")
        content.append("|-----|-------------|-------------------|-------------|")
        for option in options:
            name = option.get('name', 'N/A')
            desc = option.get('description', 'Pas de description').replace('\n', ' ')
            default = option.get('value', 'Aucune')
            required = 'Oui' if option.get('required', False) else 'Non'
            content.append(f"| {name} | {desc} | {default} | {required} |")

    # Node filters
    node_filters = job_data.get('nodefilters', {})
    if node_filters:
        content.append("\n## Filtres de nœuds\n")
        filter_str = node_filters.get('filter', 'N/A')
        content.append(f"- **Filtre**: `{filter_str}`")
        
        # Include/exclude
        filter_types = {'include': 'Inclure', 'exclude': 'Exclure'}
        for filter_type, title in filter_types.items():
            if filter_type in node_filters:
                content.append(f"\n### Filtres {title}")
                for category, values in node_filters[filter_type].items():
                    content.append(f"- **{category}**: {', '.join(values)}")
    
    # Notification
    notifications = job_data.get('notification', {})
    if notifications:
        content.append("\n## Notifications\n")
        event_types = {'onsuccess': 'En cas de succès', 'onfailure': 'En cas d\'échec', 'onstart': 'Au démarrage', 'onavgduration': 'Durée moyenne'}
        for event_type, notification in notifications.items():
            event_title = event_types.get(event_type, event_type.capitalize())
            content.append(f"### {event_title}")
            
            for plugin, config in notification.items():
                content.append(f"\n#### {plugin.capitalize()}")
                if isinstance(config, dict):
                    for key, value in config.items():
                        content.append(f"- **{key}**: {value}")
                else:
                    content.append(f"- {config}")
    
    # Workflow steps
    workflow = job_data.get('sequence', {}).get('commands', [])
    #print(f"Workflow: {workflow}")
    if workflow:
        content.append("\n## Étapes du workflow\n")
        for idx, step in enumerate(workflow, 1):
            step_type = list(step.keys())[0] if step else "Inconnu"
            step_types = {'exec': 'Commande', 'script': 'Script', 'job': 'Tâche', 'plugin': 'Plugin'}
            step_title = step_types.get(step_type, step_type)
            #print(f"..{step_type}..")
            # Extract step description properly depending on step structure
            step_description = ''
            if 'description' in step:
                step_description = step['description']
                # Remove the description from the step to avoid including it twice
                step = {k: v for k, v in step.items() if k != 'description'}
            # For specific step types that might have description in their own structure
            elif step_type == 'script' and isinstance(step.get('script', ''), dict) and 'description' in step.get('script', {}):
                step_description = step['script'].get('description', '')
                # Remove the description from the script dict to avoid including it twice
                if isinstance(step.get('script', ''), dict):
                    step['script'] = {k: v for k, v in step['script'].items() if k != 'description'}
            
            # Use the description of the step as title if it exists
            if step_description:
                content.append(f"### Étape {idx}: {step_description}\n")
            else:
                content.append(f"### Étape {idx}: {step_title}\n")
            
            if step_type == 'exec':
                content.append("```bash")
                content.append(format_bash_script(step.get('exec', '')))
                content.append("```\n")
            elif step_type == 'script':
                script_content = step.get('script', '')
                # Handle script step which can be either a string or a dict
                if isinstance(script_content, dict):
                    script_content = script_content.get('script', '')
                
                # Process escape sequences in the script content using our improved function
                script_content = format_bash_script(script_content)
                #print(f"Script: f{script_content}")
                content.append("Contenu du script:")
                content.append("```bash")
                content.append(script_content)
                content.append("```\n")
            elif step_type == 'job':
                job_ref = step.get('job', {})
                job_name = job_ref.get('name', 'Tâche inconnue')
                job_group = job_ref.get('group', 'Sans groupe')
                content.append(f"Exécute la tâche: **{job_group}/{job_name}**\n")
                
                # Add job options if available
                job_args = job_ref.get('args', '')
                if job_args:
                    content.append(f"Avec les arguments: `{job_args}`\n")
            else:
                # Generic handling for other step types
                content.append(f"```yaml")
                content.append(process_escaped_script(yaml.dump(step, default_flow_style=False)))
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
                print( f'{yaml_file}')
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
        f.write("# Documentation des tâches Rundeck\n\n")
        
        # Table of contents for the README
        f.write("## Table des matières\n\n")
        f.write("- [Aperçu](#aperçu)\n")
        f.write("- [Liste des tâches](#liste-des-tâches)\n\n")
        
        f.write("## Aperçu\n\n")
        f.write(f"Généré le: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"Total des tâches: {len(generated_files)}\n\n")
        
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
        
        f.write("## Liste des tâches\n\n")
        write_structure(job_structure)
    
    generated_files.append(index_path)
    return generated_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Générer la documentation Markdown à partir des fichiers YAML de Rundeck')
    parser.add_argument('--input-dir', required=True, help='Répertoire contenant les fichiers YAML de Rundeck')
    parser.add_argument('--output-dir', required=True, help='Répertoire de sortie pour les fichiers Markdown')
    parser.add_argument('--clean', action='store_true', help='Nettoyer le répertoire de sortie avant la génération')
    
    args = parser.parse_args()
    
    if args.clean and os.path.exists(args.output_dir):
        print(f"Nettoyage du répertoire de sortie: {args.output_dir}")
        shutil.rmtree(args.output_dir)
    
    print(f"Génération de la documentation de {args.input_dir} vers {args.output_dir}")
    generated_files = generate_rundeck_documentation(args.input_dir, args.output_dir)
    print(f"Documentation générée avec succès. {len(generated_files)} fichiers créés.")
