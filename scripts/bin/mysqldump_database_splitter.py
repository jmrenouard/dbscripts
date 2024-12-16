import os
import gzip
import argparse


def split_mysqldump(file_path):
    print(f"Ouverture du fichier : {file_path}")
    open_file = gzip.open if file_path.endswith('.gz') else open
    with open_file(file_path, 'rb') as dump_file:
        current_db = None
        db_content = []
        output_folder = os.path.splitext(file_path)[0]

        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
            print(f"Création du dossier de sortie : {output_folder}")

        for line in dump_file:
            line = line.decode('utf-8', errors='ignore')
            if line.startswith('-- Current Database:'):
                # Write the previous database to a file if it exists
                if current_db is not None:
                    db_content.append(f"--\n-- End Dump: {current_db}\n--\n")
                    print(f"Écriture de la base de données précédente : {current_db}")
                    append_database_to_file(output_folder, current_db, db_content)
                    db_content = []
                
                # Extract the database name from the line
                current_db = line.split('`')[1]
                print(f"Détection de la base de données courante : {current_db}")
                db_content.append(line)  # Keep the Current Database line
                continue

            if line.startswith('-- Dump completed on'):
                # Write the last database to a file
                if current_db is not None:
                    db_content.append(f"--\n-- End Dump: {current_db}\n--\n")
                    print(f"Fin du dump détectée, écriture de la base de données : {current_db}")
                    db_content.append(line)
                    append_database_to_file(output_folder, current_db, db_content)
                    db_content = []
                    current_db = None
                continue

            # Append the line to the current database content
            if current_db is not None:
                db_content.append(line)

        # Write the last database if the dump does not end with '-- Dump completed on'
        if current_db is not None and db_content:
            db_content.append(f"--\n-- End Dump: {current_db}\n--\n")
            print(f"Écriture de la dernière base de données : {current_db}")
            append_database_to_file(output_folder, current_db, db_content)


def append_database_to_file(output_folder, db_name, db_content):
    output_file_path = os.path.join(output_folder, f'{db_name}.sql.gz')
    if not os.path.exists(output_file_path):
        mode = 'wt'
        print(f"Création du fichier pour la base de données « {db_name} » : {output_file_path}")
    else:
        mode = 'at'
        print(f"Ajout au fichier existant pour la base de données « {db_name} » : {output_file_path}")
    with gzip.open(output_file_path, mode, encoding='utf-8') as db_file:
        db_file.writelines(db_content)
    print(f'Base de données « {db_name} » écrite dans {output_file_path}')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Split a mysqldump file into separate files for each database.')
    parser.add_argument('dump_file', type=str, help='Path to the mysqldump file (supports .gz compressed files)')
    args = parser.parse_args()

    print(f"Vérification de l'existence du fichier : {args.dump_file}")
    if os.path.exists(args.dump_file):
        split_mysqldump(args.dump_file)
    else:
        print("Le fichier n'existe pas. Veuillez vérifier le chemin fourni.")