import os
import gzip
import argparse


def split_table_dump(file_path):
    print(f"Ouverture du fichier : {file_path}")
    open_file = gzip.open if file_path.endswith('.gz') else open
    with open_file(file_path, 'rb') as dump_file:
        current_table = None
        structure_content = []
        data_content = []
        output_folder = os.path.splitext(file_path)[0]

        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
            print(f"Création du dossier de sortie : {output_folder}")

        for line in dump_file:
            line = line.decode('utf-8', errors='ignore')
            if line.startswith('-- Table structure for table'):
                # Write the previous table's structure and data to files if they exist
                if current_table is not None:
                    structure_content.append("--\n")
                    data_content.append("--\n")
                    print(f"Écriture de la table précédente : {current_table}")
                    write_table_to_file(output_folder, current_table, structure_content, data_content)
                    structure_content = []
                    data_content = []

                # Extract the table name from the line
                current_table = line.split('`')[1]
                print(f"Détection de la table courante : {current_table}")
                structure_content.append(line)  # Keep the Table structure line
                continue

            if line.startswith('-- Dumping data for table'):
                if current_table is not None:
                    structure_content.append("--\n")
                    print(f"Fin de la structure de la table : {current_table}")
                data_content.append(line)  # Keep the Dumping data line
                continue

            # Append the line to the current table structure or data content
            if current_table is not None:
                if structure_content and not data_content:
                    structure_content.append(line)
                elif data_content:
                    data_content.append(line)

        # Write the last table if the dump does not end with '--'
        if current_table is not None:
            structure_content.append("--\n")
            data_content.append("--\n")
            print(f"Écriture de la dernière table : {current_table}")
            write_table_to_file(output_folder, current_table, structure_content, data_content)


def write_table_to_file(output_folder, table_name, structure_content, data_content):
    structure_file_path = os.path.join(output_folder, f'{table_name}_structure.sql.gz')
    data_file_path = os.path.join(output_folder, f'{table_name}_data.sql.gz')

    print(f"Écriture de la structure de la table « {table_name} » dans le fichier : {structure_file_path}")
    with gzip.open(structure_file_path, 'wt', encoding='utf-8') as structure_file:
        structure_file.writelines(structure_content)
    print(f'Structure de la table « {table_name} » écrite dans {structure_file_path}')

    print(f"Écriture des données de la table « {table_name} » dans le fichier : {data_file_path}")
    with gzip.open(data_file_path, 'wt', encoding='utf-8') as data_file:
        data_file.writelines(data_content)
    print(f'Données de la table « {table_name} » écrites dans {data_file_path}')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Split a mysqldump file by table into separate files for structure and data.')
    parser.add_argument('dump_file', type=str, help='Path to the mysqldump file (supports .gz compressed files)')
    args = parser.parse_args()

    print(f"Vérification de l'existence du fichier : {args.dump_file}")
    if os.path.exists(args.dump_file):
        split_table_dump(args.dump_file)
    else:
        print("Le fichier n'existe pas. Veuillez vérifier le chemin fourni.")