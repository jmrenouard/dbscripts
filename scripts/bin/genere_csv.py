#!/usr/bin/env python3
# ===============================
# CSV Generator Module
# ===============================
#
# A Python module to generate CSV files containing random test data for database testing 
# or data analysis purposes.
#
# Features:
# ---------
# * Generates random names (English and French)
# * Creates vehicle registration numbers
# * Adds timestamps within a configurable date range
# * Includes random status values
# * Configurable number of rows
# * Command line interface support
#
# Usage Examples:
# --------------
# As a module:
#     >>> from genere_csv import generate_csv
#     >>> generate_csv('output.csv', 1000)  # Generate 1000 rows
#
# From command line:
#     $ python genere_csv.py --filename output.csv --rows 1000 --days 30
#
# Output Format:
# -------------
# The generated CSV contains the following columns:
# - id: Sequential identifier
# - client_name: Random generated name (English or French)
# - insertion_time: Random datetime within specified range
# - status: One of [None, "DELETED", "UPDATED", "CREATED"]
# - immat: Random vehicle registration number
#
# Author: JM Ren
# Version: 1.0
#
# ===============================

import csv
import random
import datetime
import time

def generate_random_registration():
    """
    Generate a random vehicle registration number in format 'XX-000-XX'.
    
    Returns:
        str: A formatted registration number
    """
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"
    return f"{random.choice(letters)}{random.choice(letters)}-{random.randint(100, 999)}-{random.choice(letters)}{random.choice(letters)}".upper()

def generate_random_name():
    """
    Generate a random full name by combining a random first name and last name.
    
    Returns:
        str: A full name in format 'First Last'
    """
    first_names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Henry", "Ivy", "Jack", "Kelly", "Liam", "Mia", 
                   "Noah", "Olivia", "Peter", "Quinn", "Ryan", "Sophia", "Thomas", "Emma", "Lucas", "Luna", "Hugo", "Jade", 
                   "Gabriel", "Louise", "Louis", "Nina", "Leo", "Clara", "Jules", "Anna", "Arthur", "Rose", "Paul", "Marie",
                   "Adam", "Sarah", "Alex", "Zoe", "Nathan", "Maya", "Samuel", "Ella", "Daniel", "Julia", "Oscar", "Victoria",
                   "William", "Sofia", "James", "Ava", "Benjamin", "Isabella", "Mason", "Charlotte", "Elijah", "Amelia",
                   "Oliver", "Harper", "Jacob", "Evelyn", "Lucas", "Abigail", "Michael", "Emily", "Alexander", "Elizabeth",
                   "Ethan", "Mila", "Sebastian", "Ella", "Matthew", "Avery", "Joseph", "Scarlett", "Levi", "Eleanor",
                   "Mateo", "Aria", "Leo", "Bella", "John", "Chloe", "Owen", "Aurora", "Julian", "Lucy", "Aiden", "Layla",
                   # Adding French first names
                   "Amélie", "Baptiste", "Camille", "Céline", "Édouard", "Florence", "Gérard", "Henri",
                   "Isabelle", "Jean-Pierre", "Manon", "Nicolas", "Pauline", "Renée", "Sylvie", "Théo",
                   "Valentine", "Yann", "Zoé", "André"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
                  "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
                  "Anderson", "Taylor", "Moore", "Jackson", "White", "Harris", "Clark", "Lewis", "Lee", "Walker",
                  "Hall", "Young", "King", "Wright", "Lopez", "Hill", "Scott", "Green", "Adams", "Baker",
                  "Wilson", "Campbell", "Thompson", "Morgan", "Collins", "Stewart", "Murphy", "Cook", "Rogers", "Cooper",
                  "Phillips", "Wood", "Peterson", "Gray", "Hughes", "Price", "Foster", "Butler", "Sanders", "Ross",
                  "Long", "Patterson", "Hughes", "Flores", "Washington", "Butler", "Simmons", "Foster", "Gonzales", "Bryant",
                  "Alexander", "Russell", "Griffin", "Diaz", "Hayes", "Myers", "Ford", "Hamilton", "Graham", "Sullivan",
                  # Adding French last names
                  "Dupont", "Rousseau", "Lambert", "Bonnet", "Fontaine", "Mercier", "Roux", "Vincent",
                  "Chevalier", "Lemaire", "Girard", "Fournier", "Blanc", "Michel", "Faure", "Morel",
                  "Giraud", "Laurent", "Simon", "Lefebvre"]
    return f"{random.choice(first_names)} {random.choice(last_names)}"

def generate_random_status():
    """
    Generate a random status for a record.
    
    Returns:
        str or None: One of: None, 'DELETED', 'UPDATED', 'CREATED'
    """
    statuses = [None, "DELETED", "UPDATED", "CREATED"]
    return random.choice(statuses)

def generate_random_datetime(start_date, end_date):
    """
    Generate a random datetime between two dates.
    
    Args:
        start_date (date): The lower bound date
        end_date (date): The upper bound date
    
    Returns:
        datetime: A random datetime between start_date and end_date
    """
    time_between_dates = end_date - start_date
    days_between_dates = time_between_dates.days
    random_number_of_days = random.randrange(days_between_dates)
    random_date = start_date + datetime.timedelta(days=random_number_of_days)
    random_time = datetime.time(random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))
    return datetime.datetime.combine(random_date, random_time)

def generate_csv(filename, num_rows):
    """
    Generate a CSV file with random data.
    
    Args:
        filename (str): Name of the output CSV file
        num_rows (int): Number of rows to generate
    
    Creates a CSV file with columns:
    - id: Sequential number
    - client_name: Random generated name
    - insertion_time: Random datetime
    - status: Random status
    - immat: Random registration number
    """
    start_date = datetime.date.today() - datetime.timedelta(days=60)
    end_date = datetime.date.today()
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['id', 'client_name', 'insertion_time', 'status', 'immat']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for i in range(1, num_rows + 1):
            insertion_time = generate_random_datetime(start_date, end_date)
            modification_time = insertion_time + datetime.timedelta(minutes=random.randint(0, 60))
            
            writer.writerow({
                'id': i,
                'client_name': generate_random_name(),
                #'modification_time': modification_time.strftime('%Y-%m-%d %H:%M:%S'),
                'insertion_time': insertion_time.strftime('%Y-%m-%d %H:%M:%S'),
                'status': generate_random_status(),
                'immat': generate_random_registration()
            })

def main(filename='elastic_table_data.csv', num_rows=1000000, days_range=60):
    """
    Main function to generate CSV file with random data.
    
    Args:
        filename (str): Output CSV filename
        num_rows (int): Number of rows to generate
        days_range (int): Number of days in the past for date generation
    """
    generate_csv(filename, num_rows)
    print(f"CSV file '{filename}' generated successfully with {num_rows} rows.")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate a CSV file with random data.')
    parser.add_argument('--filename', default='elastic_table_data.csv', help='Output CSV filename')
    parser.add_argument('--rows', type=int, default=1000000, help='Number of rows to generate')
    parser.add_argument('--days', type=int, default=60, help='Number of days in the past for date generation')
    
    args = parser.parse_args()
    main(args.filename, args.rows, args.days)
