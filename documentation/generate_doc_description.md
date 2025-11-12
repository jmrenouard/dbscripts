# Générateur d'Index de Documentation Markdown

## Description

Ce script Python génère automatiquement un index structuré des fichiers de documentation Markdown et une page regroupant toutes les illustrations présentes dans un répertoire de documentation. Il analyse récursivement un répertoire, extrait les métadonnées des fichiers Markdown et produit un rapport organisé par sous-répertoires.

## Fonctionnalités principales

- Analyse récursive d'un répertoire de documentation
- Extraction des titres, comptage des mots et dates de modification
- Génération d'un index structuré par sous-répertoires
- Création d'une page dédiée aux illustrations
- Personnalisation via arguments en ligne de commande

## Fonctions

### `get_markdown_title(file_path)`
Extrait le titre d'un fichier Markdown (premier titre de niveau 1). Utilise le nom du fichier comme titre de secours.

### `count_words(file_path)`
Compte les mots dans un fichier Markdown en excluant les blocs de code pour une meilleure précision.

### `get_last_modified(file_path)`
Récupère la date de dernière modification d'un fichier au format YYYY-MM-DD.

### `generate_docs_description(docs_dir, exclude_file, base_url)`
Génère une description structurée des fichiers Markdown, organisée par sous-répertoires, avec liens, titres, nombre de mots et dates de modification.

### `generate_illustrations_page(docs_dir, output_file)`
Crée une page dédiée regroupant toutes les images (PNG, JPG, JPEG, GIF) présentes dans le répertoire de documentation.

## Utilisation

```bash
python3 script.py [options]
```

### Options

- `--docs-dir` : Répertoire contenant les fichiers Markdown (défaut: ./docs)
- `--output-file` : Nom du fichier de sortie pour l'index (défaut: README.md)
- `--exclude` : Fichier à exclure de l'index (chemin relatif au répertoire docs)
- `--base-url` : URL de base pour les liens vers les fichiers
- `--generate-illustrations` : Active la génération de la page d'illustrations (activé par défaut)
- `--illustrations-file` : Nom du fichier pour les illustrations (défaut: Illustrations.md)

## Format de sortie

L'index généré est structuré en sections par sous-répertoire, avec un tableau contenant:
- Liens vers les fichiers
- Titres extraits
- Nombre de mots
- Dates de dernière modification

La page d'illustrations organise les images par sous-répertoire, avec le nom et l'aperçu de chaque image.

## Dépendances

- Python 3.x
- Modules standards : os, re, argparse, datetime

## Remarques

Le script traite intelligemment les blocs de code pour un comptage de mots plus précis et gère les erreurs potentielles lors de l'accès aux fichiers.