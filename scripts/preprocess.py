import csv
import time
from pathlib import Path

# Directory paths
PROJECT_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = PROJECT_DIR / "data" / "raw"
TARGET_DIR = PROJECT_DIR / "data" / "prepared"


def process_csv_file(source_file: Path, target_file: Path) -> None:
    """
    Reads raw CSV file in UTF-8 and writes it in UTF-16LE.
    Stream processing row-by-row saves RAM memory, while the csv module
    standardizes escape characters, quotes, and newlines to ensure a seamless
    BULK INSERT execution in SQL Server (Docker).
    """
    with open(source_file, "r", encoding="utf-8", newline="") as src, \
         open(target_file, "w", encoding="utf-16", newline="") as tgt:
        
        reader = csv.reader(src)
        writer = csv.writer(tgt, quoting=csv.QUOTE_MINIMAL)
        
        # Row-by-row stream writing
        for row in reader:
            writer.writerow(row)


def main(source_dir: Path = SOURCE_DIR, target_dir: Path = TARGET_DIR) -> None:
    batch_start_time = time.time()
    target_dir.mkdir(parents=True, exist_ok=True)
    
    print("==================================================")
    print("STEP 1: INGESTION & DATA PREPROCESSING (ETL PIPELINE)")
    print("==================================================")
    print(f"Source Directory: {source_dir}")
    print(f"Target Directory: {target_dir}\n")

    csv_files = list(source_dir.glob("*.csv"))
    if not csv_files:
        print("!!! WARNING: No CSV files found to process !!!")
        return

    for source_file in csv_files:
        start_time = time.time()
        target_file = target_dir / source_file.name
        
        print(f"  --> Processing: {source_file.name}...")
        process_csv_file(source_file, target_file)
        
        duration = round(time.time() - start_time, 2)
        print(f"      Status: OK | Duration: {duration}s")

    total_duration = round(time.time() - batch_start_time, 2)
    print("\n==================================================")
    print(f"PREPROCESSING COMPLETED IN {total_duration}s")
    print("Data is ready for bronze.LoadData execution.")
    print("==================================================")


if __name__ == "__main__":
    main()