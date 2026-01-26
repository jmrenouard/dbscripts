# Markdown Documentation Index Generator

## Description

This Python script automatically generates a structured index of Markdown documentation files and a page grouping all illustrations present in a documentation directory. It recursively analyzes a directory, extracts metadata from Markdown files, and produces a report organized by subdirectories.

## Key Features

- Recursive analysis of a documentation directory
- Title extraction, word count, and modification dates
- Structured index generation by subdirectories
- Creation of a dedicated illustration gallery page
- Customization via command-line arguments

## Functions

### `get_markdown_title(file_path)`

Extracts the title of a Markdown file (first level 1 heading). Uses the filename as a fallback.

### `count_words(file_path)`

Counts words in a Markdown file, excluding code blocks for better accuracy.

### `get_last_modified(file_path)`

Retrieves the last modification date of a file in YYYY-MM-DD format.

### `generate_docs_description(docs_dir, exclude_file, base_url)`

Generates a structured description of Markdown files, organized by subdirectories, with links, titles, word counts, and modification dates.

### `generate_illustrations_page(docs_dir, output_file)`

Creates a dedicated page grouping all images (PNG, JPG, JPEG, GIF) present in the documentation directory.

## Usage

```bash
python3 script.py [options]
```

### Options

- `--docs-dir`: Directory containing Markdown files (default: ./docs)
- `--output-file`: Output filename for the index (default: README.md)
- `--exclude`: File to exclude from the index (path relative to docs directory)
- `--base-url`: Base URL for file links
- `--generate-illustrations`: Enable illustration page generation (enabled by default)
- `--illustrations-file`: Filename for illustrations (default: Illustrations.md)

## Output Format

The generated index is structured into sections per subdirectory, with a table containing:

- File links
- Extracted titles
- Word count
- Last modification dates

The illustrations page organizes images by subdirectory, with the name and a preview of each image.

## Dependencies

- Python 3.x
- Standard modules: os, re, argparse, datetime

## Notes

The script intelligently handles code blocks for more precise word counting and manages potential errors when accessing files.
