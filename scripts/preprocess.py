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
        # lineterminator='\n' matches the SQL Server BULK INSERT ROWTERMINATOR
        # ('0x0a00', i.e. LF only). csv.writer's default is '\r\n', which would
        # otherwise leave a stray CR stuck to the last column of every row.
        writer = csv.writer(tgt, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        
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

    csv_files = sorted(source_dir.glob("*.csv"))

    if not csv_files:
        raise FileNotFoundError(
            f"No CSV files found in source directory: {source_dir}"
        )

    processed_files = 0

    for source_file in csv_files:
        start_time = time.time()
        target_file = target_dir / source_file.name

        print(f"  --> Processing: {source_file.name}...", flush=True)
        process_csv_file(source_file, target_file)
        
        duration = round(time.time() - start_time, 2)
        print(f"      Status: OK | Duration: {duration}s", flush=True)

        processed_files += 1

    total_duration = round(time.time() - batch_start_time, 2)

    print("\n==================================================")
    print(f"PREPROCESSING COMPLETED IN {total_duration}s")
    print(f"Files processed: {processed_files}")
    print("Data is ready for bronze.LoadData execution.")
    print("==================================================")


if __name__ == "__main__":
    main()