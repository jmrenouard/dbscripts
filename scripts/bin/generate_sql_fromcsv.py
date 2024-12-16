import os
import argparse
import gzip
import csv

def generate_delete_statements(input_file, output_file, separator, batch_size):
    # Charger le fichier CSV compressé GZIP
    with gzip.open(input_file, mode='rt') as file:
        reader = csv.DictReader(file, delimiter=separator)

        # Générer les requêtes DELETE
        delete_statements = []
        batch_count = 1
        for row in reader:
            delete_statement = (
                f"DELETE FROM ma table  WHERE "
                f"source = '{row['source']}' AND "
                f"gen_ts = '{row['gen_ts']}';"
            )
            delete_statements.append(delete_statement)

            # Sauvegarder par lots de n requêtes
            if len(delete_statements) == batch_size:
                batch_output_file = f"{os.path.splitext(output_file)[0]}_batch_{batch_count}.sql"
                with open(batch_output_file, "w") as batch_file:
                    batch_file.write("\n".join(delete_statements))
                delete_statements = []
                batch_count += 1

        # Sauvegarder les requêtes restantes
        if delete_statements:
            batch_output_file = f"{os.path.splitext(output_file)[0]}_batch_{batch_count}.sql"
            with open(batch_output_file, "w") as batch_file:
                batch_file.write("\n".join(delete_statements))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Générer des requêtes DELETE à partir d'un fichier CSV compressé GZIP.")
    parser.add_argument("--input_file", type=str, required=True, help="Chemin du fichier d'entrée CSV compressé GZIP.")
    parser.add_argument("--output_file", type=str, required=True, help="Chemin du fichier de sortie pour les requêtes DELETE.")
    parser.add_argument("--separator", type=str, default=';', help="Séparateur du fichier CSV.")
    parser.add_argument("--batch_size", type=int, default=10000, help="Nombre de requêtes par fichier de sortie.")
    
    args = parser.parse_args()

    # Générer les requêtes DELETE
    generate_delete_statements(args.input_file, args.output_file, args.separator, args.batch_size)
