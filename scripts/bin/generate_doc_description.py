#!/usr/bin/env python3
import os
import re
import argparse
from datetime import datetime

def get_markdown_title(file_path):
    """Extract title from markdown file (first # heading)"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Look for the first heading
            title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
            if title_match:
                return title_match.group(1).strip()
            # If no heading found, use filename as title
            return os.path.splitext(os.path.basename(file_path))[0]
    except Exception as e:
        return os.path.splitext(os.path.basename(file_path))[0]

def count_words(file_path):
    """Count words in a markdown file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Remove code blocks to get more accurate word count
            content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)
            # Remove inline code
            content = re.sub(r'`.*?`', '', content)
            # Count words
            return len(re.findall(r'\b\w+\b', content))
    except Exception:
        return 0

def get_last_modified(file_path):
    """Get last modified date of file"""
    try:
        mtime = os.path.getmtime(file_path)
        return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')
    except Exception:
        return "Unknown"

def generate_docs_description(docs_dir="docs", exclude_file=None, base_url=None):
    """Generate description of markdown files in docs directory"""
    if not os.path.exists(docs_dir):
        return f"Le répertoire '{docs_dir}' n'existe pas."
    
    # Dictionary to store files by subdirectory
    dirs_files = {}
    total_files = 0
    
    # Walk through the docs directory
    for root, _, files in os.walk(docs_dir):
        markdown_files = []
        
        for file in files:
            if file.lower().endswith('.md'):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, docs_dir)
                
                # Skip excluded file
                if exclude_file and relative_path == exclude_file:
                    continue
                
                title = get_markdown_title(file_path)
                word_count = count_words(file_path)
                last_modified = get_last_modified(file_path)
                
                # Create markdown link with relative path
                file_name = os.path.basename(relative_path)
                file_name=os.path.splitext(file_name)[0].upper().replace("_"," ")
                file_link = f"[{file_name}]({relative_path})"
                
                # Use base_url if provided
                if base_url:
                    file_link = f"[{relative_path}]({base_url}/{relative_path})"
                
                markdown_files.append({
                    'path': file_link,
                    'relative_path': relative_path,  # Keep original path for sorting
                    'title': title,
                    'words': word_count,
                    'modified': last_modified
                })
                total_files += 1
        
        if markdown_files:
            # Get subdirectory name relative to docs_dir
            subdir = os.path.relpath(root, docs_dir)
            if subdir == ".":
                subdir = "Racine"
            
            # Sort files by path
            markdown_files.sort(key=lambda x: x['relative_path'])
            dirs_files[subdir] = markdown_files
    
    # Generate description
    description = f"# Description des fichiers de documentation\n\n"
    description += f"Total: {total_files} fichiers markdown\n\n"
    
    # Sort subdirectories, but ensure "Racine" appears first
    sorted_dirs = sorted(dirs_files.keys())
    if "Racine" in sorted_dirs:
        # Remove "Racine" from its current position
        sorted_dirs.remove("Racine")
        # Add it to the beginning
        sorted_dirs.insert(0, "Racine")
    
    # Generate a section for each subdirectory
    for subdir in sorted_dirs:
        markdown_files = dirs_files[subdir]
        
        # Add section header
        description += f"## {subdir}\n\n"
        
        # Add table header
        description += "| Fichier | Titre | Mots | Dernière modification |\n"
        description += "|---------|-------|------|----------------------|\n"
        
        # Add table rows
        for file_info in markdown_files:
            description += f"| {file_info['path']} | {file_info['title']} | {file_info['words']} | {file_info['modified']} |\n"
        
        description += "\n"
    
    return description

def generate_illustrations_page(docs_dir="docs", output_file="Illustrations.md"):
    """Generate a markdown page with all PNG images in the docs directory"""
    if not os.path.exists(docs_dir):
        return f"Le répertoire '{docs_dir}' n'existe pas."
    
    # Dictionary to store images by subdirectory
    dir_images = {}
    total_images = 0
    
    # Walk through the docs directory
    for root, _, files in os.walk(docs_dir):
        images_in_dir = []
        
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, docs_dir)
                
                images_in_dir.append({
                    'path': relative_path,
                    'name': os.path.splitext(os.path.basename(file_path))[0]
                })
                total_images += 1
        
        if images_in_dir:
            # Get subdirectory name relative to docs_dir
            subdir = os.path.relpath(root, docs_dir)
            if subdir == ".":
                subdir = "Racine"
            
            # Sort images by path
            images_in_dir.sort(key=lambda x: x['path'])
            dir_images[subdir] = images_in_dir
    
    # Generate the markdown content
    content = "# Illustrations\n\n"
    content += f"Total: {total_images} images\n\n"
    
    # Sort subdirectories, but ensure "Racine" appears first
    sorted_dirs = sorted(dir_images.keys())
    if "Racine" in sorted_dirs:
        # Remove "Racine" from its current position
        sorted_dirs.remove("Racine")
        # Add it to the beginning
        sorted_dirs.insert(0, "Racine")
    
    # Generate a section for each subdirectory
    for subdir in sorted_dirs:
        images = dir_images[subdir]
        
        # Add section header
        content += f"## {subdir}\n\n"
        
        # Add each image in the directory
        for img in images:
            content += f"### {img['name']}\n\n"
            content += f"![{img['name']}]({img['path']})\n\n"
    
    # Save the file in the docs directory
    output_path = os.path.join(docs_dir, output_file)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    return output_path, total_images

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Générer une description des fichiers Markdown.')
    parser.add_argument('--docs-dir', default='./docs',
                      help='Répertoire contenant les fichiers Markdown (défaut: docs)')
    parser.add_argument('--output-file', default='README.md',
                      help='Nom du fichier de sortie (défaut: README.md)')
    parser.add_argument('--exclude', default=None,
                      help='Fichier à exclure (chemin relatif au répertoire docs)')
    parser.add_argument('--base-url', default=None,
                      help='URL de base pour les liens vers les fichiers (ex: https://github.com/user/repo/blob/main/docs)')
    parser.add_argument('--generate-illustrations', action='store_true', default=True,
                      help='Générer une page avec toutes les illustrations PNG')
    parser.add_argument('--illustrations-file', default='Illustrations.md',
                      help='Nom du fichier pour les illustrations (défaut: Illustrations.md)')
    
    args = parser.parse_args()
    
    # Generate illustrations page if requested
    if args.generate_illustrations:
        output_path, img_count = generate_illustrations_page(args.docs_dir, args.illustrations_file)
        print(f"Page d'illustrations générée avec {img_count} images dans '{output_path}'")

    
    description = generate_docs_description(args.docs_dir, args.exclude, args.base_url)
    print(description)
    
    # Save to specified output file in the docs directory
    output_path = os.path.join(args.docs_dir, args.output_file)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(description)
    print(f"\nDescription sauvegardée dans '{output_path}'")