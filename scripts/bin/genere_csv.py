import csv
import random
import datetime
import time

def generate_random_registration():
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"
    return f"{random.choice(letters)}{random.choice(letters)}-{random.randint(100, 999)}-{random.choice(letters)}{random.choice(letters)}".upper()

def generate_random_name():
    first_names = ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Henry", "Ivy", "Jack", "Kelly", "Liam", "Mia", 
                   "Noah", "Olivia", "Peter", "Quinn", "Ryan", "Sophia", "Thomas", "Emma", "Lucas", "Luna", "Hugo", "Jade", 
                   "Gabriel", "Louise", "Louis", "Nina", "Leo", "Clara", "Jules", "Anna", "Arthur", "Rose", "Paul", "Marie",
                   "Adam", "Sarah", "Alex", "Zoe", "Nathan", "Maya", "Samuel", "Ella", "Daniel", "Julia", "Oscar", "Victoria",
                   "William", "Sofia", "James", "Ava", "Benjamin", "Isabella", "Mason", "Charlotte", "Elijah", "Amelia",
                   "Oliver", "Harper", "Jacob", "Evelyn", "Lucas", "Abigail", "Michael", "Emily", "Alexander", "Elizabeth",
                   "Ethan", "Mila", "Sebastian", "Ella", "Matthew", "Avery", "Joseph", "Scarlett", "Levi", "Eleanor",
                   "Mateo", "Aria", "Leo", "Bella", "John", "Chloe", "Owen", "Aurora", "Julian", "Lucy", "Aiden", "Layla"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
                  "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau",
                  "Anderson", "Taylor", "Moore", "Jackson", "White", "Harris", "Clark", "Lewis", "Lee", "Walker",
                  "Hall", "Young", "King", "Wright", "Lopez", "Hill", "Scott", "Green", "Adams", "Baker",
                  "Wilson", "Campbell", "Thompson", "Morgan", "Collins", "Stewart", "Murphy", "Cook", "Rogers", "Cooper",
                  "Phillips", "Wood", "Peterson", "Gray", "Hughes", "Price", "Foster", "Butler", "Sanders", "Ross",
                  "Long", "Patterson", "Hughes", "Flores", "Washington", "Butler", "Simmons", "Foster", "Gonzales", "Bryant",
                  "Alexander", "Russell", "Griffin", "Diaz", "Hayes", "Myers", "Ford", "Hamilton", "Graham", "Sullivan"]
    return f"{random.choice(first_names)} {random.choice(last_names)}"

def generate_random_status():
    statuses = [None, "DELETED", "UPDATED", "CREATED"]
    return random.choice(statuses)

def generate_random_datetime(start_date, end_date):
    time_between_dates = end_date - start_date
    days_between_dates = time_between_dates.days
    random_number_of_days = random.randrange(days_between_dates)
    random_date = start_date + datetime.timedelta(days=random_number_of_days)
    random_time = datetime.time(random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))
    return datetime.datetime.combine(random_date, random_time)

def generate_csv(filename, num_rows):
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

# Générer un fichier CSV avec 100 lignes de données
generate_csv('elastic_table_data.csv', 1000000)
print("Fichier CSV 'elastic_table_data.csv' généré avec succès.")
