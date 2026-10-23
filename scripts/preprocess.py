import csv
import time
from pathlib import Path

# Directory paths
PROJECT_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = PROJECT_DIR / "data" / "raw"
TARGET_DIR = PROJECT_DIR / "data" / "prepared"

# Row count manifest, loaded into bronze.SourceRowCounts and compared with the
# Bronze tables after the load (see bronze.LoadData).
MANIFEST_FILE_NAME = "source_row_counts.csv"


def process_csv_file(source_file: Path, target_file: Path) -> int:
    """
    Reads raw CSV file in UTF-8 and writes it in UTF-16LE.
    Stream processing row-by-row saves RAM memory, while the csv module
    standardizes escape characters, quotes, and newlines to ensure a seamless
    BULK INSERT execution in SQL Server (Docker).

    Returns the number of data records (header excluded). The count comes from
    the csv parser, so a quoted multiline field counts as one record - the
    same number of rows that bronze must contain after BULK INSERT.
    """
    with open(source_file, "r", encoding="utf-8", newline="") as src, \
         open(target_file, "w", encoding="utf-16", newline="") as tgt:
        
        reader = csv.reader(src)
        # lineterminator='\n' matches the SQL Server BULK INSERT ROWTERMINATOR
        # ('0x0a00', i.e. LF only). csv.writer's default is '\r\n', which would
        # otherwise leave a stray CR stuck to the last column of every row.
        writer = csv.writer(tgt, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        
        # Row-by-row stream writing
        record_count = 0
        for row in reader:
            writer.writerow(row)
            record_count += 1

    # The first record is the header row (BULK INSERT uses FIRSTROW = 2).
    return max(record_count - 1, 0)


def write_manifest(manifest_file: Path, row_counts: dict[str, int]) -> None:
    """
    Writes the row count manifest in the same format as the prepared data
    files (UTF-16, LF line terminator), so bronze.LoadData can load it with
    the same BULK INSERT options.
    """
    with open(manifest_file, "w", encoding="utf-16", newline="") as tgt:
        writer = csv.writer(tgt, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        writer.writerow(["FileName", "SourceRowCount"])
        for file_name, row_count in sorted(row_counts.items()):
            writer.writerow([file_name, row_count])


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
    row_counts: dict[str, int] = {}

    for source_file in csv_files:
        start_time = time.time()
        target_file = target_dir / source_file.name

        print(f"  --> Processing: {source_file.name}...", flush=True)
        row_count = process_csv_file(source_file, target_file)
        row_counts[source_file.name] = row_count

        duration = round(time.time() - start_time, 2)
        print(
            f"      Status: OK | Rows: {row_count} | Duration: {duration}s",
            flush=True,
        )

        processed_files += 1

    write_manifest(target_dir / MANIFEST_FILE_NAME, row_counts)
    print(f"\n  --> Row count manifest written: {MANIFEST_FILE_NAME}")

    total_duration = round(time.time() - batch_start_time, 2)

    print("\n==================================================")
    print(f"PREPROCESSING COMPLETED IN {total_duration}s")
    print(f"Files processed: {processed_files}")
    print("Data is ready for bronze.LoadData execution.")
    print("==================================================")


if __name__ == "__main__":
    main()