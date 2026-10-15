# Olist SQL Server Data Warehouse

Data engineering portfolio project based on the **Brazilian E-Commerce Public Dataset by Olist**.

The project builds a data warehouse in **Microsoft SQL Server**, using a Bronze / Silver / Gold medallion architecture. The entire pipeline — SQL Server, data preprocessing and the full Bronze-to-Gold load — runs in Docker and can be started with a single script.

## Contents

* [Source data](#source-data)
* [Project status](#project-status)
* [Architecture](#architecture)
* [Technologies](#technologies)
* [Quick start](#quick-start)
* [Data preprocessing](#data-preprocessing)
* [Bronze layer](#bronze-layer)
* [Silver layer](#silver-layer)
* [Gold layer — dimensional model](#gold-layer--dimensional-model)
* [Manual execution](#manual-execution)
* [Project structure](#project-structure)
* [License](#license)

## Source data

The project uses the **Brazilian E-Commerce Public Dataset by Olist**, containing information about orders, customers, products, sellers, payments, reviews and related entities.

The dataset is a static, historical CSV export rather than a live, continuously changing feed, which is a design assumption referenced throughout this document.

## Project status

Current stage:

* [x] Docker environment
* [x] Data preprocessing
* [x] Bronze layer
* [x] Silver layer
* [x] Gold layer
* [ ] Business-oriented analytical queries

## Architecture

The project is built around a layered data warehouse architecture:

```text
Olist CSV files
      │
      ▼
Preprocessing
      │
      ▼
   Bronze
      │
      ▼
    Silver
      │
      ▼
     Gold
      │
      ▼
Business Analysis
```

The preprocessing, Bronze, Silver and Gold layers are fully implemented. Business-oriented analytical queries on top of the Gold layer are the next planned step.

## Technologies

* **Microsoft SQL Server 2022**
* **Docker / Docker Compose**
* **Python**
* **T-SQL**
* **Git / GitHub**

## Quick start

The whole pipeline — starting SQL Server, preprocessing the source files, and loading and validating Bronze, Silver and Gold — runs from a single script.

### 1. Clone the repository

```bash
git clone https://github.com/IgPtasze/SQL-Server-Olist.git
cd SQL-Server-Olist
```

### 2. Configure environment variables

Create a `.env` file in the project root:

```env
MSSQL_SA_PASSWORD=YourStrongPassword123!
```

The `.env` file is excluded from version control.

### 3. Run the pipeline

```bat
run_pipeline.bat
```

The script will:

1. check that Docker, Docker Compose, `.env` and the required script files are present,
2. start the SQL Server container and wait for it to report healthy,
3. run the preprocessing container to convert the source CSV files,
4. execute the full SQL pipeline (Bronze → Silver → Gold, with validation after Silver and Gold),
5. print a short validation summary and write a complete log to `logs/pipeline_<timestamp>.log`.

A `PASS WITH WARNINGS` result for the Silver and Gold validation is expected — see [Validation status: PASS vs. PASS WITH WARNINGS](#validation-status-pass-vs-pass-with-warnings) for why.

### Exploring the results

Once the pipeline has completed, you can query the warehouse directly through the running SQL Server container:

```bash
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "<YOUR_PASSWORD>" -C -d OlistDWH -Q "SELECT TOP 10 * FROM gold.fact_orders"
```

## Data preprocessing

The original Olist CSV files cannot be loaded directly into SQL Server in the Docker environment without preprocessing.

The main issues are:

* **Portuguese characters** in the source data require appropriate Unicode handling.
* Some fields, particularly in the reviews dataset, contain **multiline text**, which requires proper CSV parsing and quoting to preserve the original records.
* SQL Server running in the Linux-based Docker container does not support the `CODEPAGE` option of `BULK INSERT` in the same way as SQL Server on Windows, making direct loading of the original UTF-8 files problematic.

To address these issues, a separate Python preprocessing container is used. It:

* reads the source CSV files using Python's `csv` module,
* correctly handles quoted and multiline fields,
* converts the files from **UTF-8 to UTF-16**,
* writes rows with an LF-only line terminator, matching the `ROWTERMINATOR` used by `BULK INSERT`,
* preserves CSV structure and delimiters,
* writes the prepared files to the `data/prepared` directory.

The prepared files can then be loaded into SQL Server using `BULK INSERT` with Unicode/wide-character support.

The preprocessing environment is kept separate from the SQL Server container.

## Bronze layer

The Bronze layer is responsible for storing the source data in SQL Server with minimal transformation.

The main goals of this layer are:

* preserving the structure and content of the source data,
* providing a reliable landing layer for further processing,
* separating raw data ingestion from subsequent transformations.

The Bronze layer uses a dedicated `bronze` schema. Tables are created to represent the source Olist datasets, with data types selected primarily to safely accommodate the source data rather than optimize it for analytical queries.

### Data loading

Data is loaded into Bronze using the `bronze.LoadData` stored procedure.

The procedure:

1. clears the target Bronze tables,
2. loads the prepared CSV files using `BULK INSERT`,
3. loads the data using SQL Server's Unicode/wide-character support,
4. performs the load within a transaction,
5. records the execution time of the load.

Using a transaction ensures that the Bronze layer is not left in a partially loaded state if an error occurs during the loading process. This provides a repeatable way of rebuilding the Bronze layer from the converted source files.

## Silver layer

The Silver layer is responsible for cleaning, transforming and validating the data loaded into the Bronze layer.

The main goals of this layer are:

* converting source values to appropriate SQL Server data types,
* handling empty values and `NULL`s,
* trimming text values,
* cleaning problematic characters from source values,
* preparing the data for further transformation in the Gold layer,
* validating the quality of the loaded data.

The Silver layer uses a dedicated `silver` schema. Tables in the Silver layer use more appropriate data types than the Bronze layer — numeric values are converted to `INT` or `DECIMAL`, date and time values are converted to `DATETIME2`, and text fields use appropriate `NVARCHAR` lengths.

### Data loading

Data is loaded into Silver using the `silver.LoadData` stored procedure.

The procedure:

1. clears the target Silver tables,
2. reads data from the Bronze layer,
3. cleans and transforms source values,
4. converts values to the appropriate data types,
5. handles empty values and `NULL`s,
6. adds a `LoadTimestamp` to loaded records.

The `LoadTimestamp` is generated during the load using `SYSDATETIME()` and provides information about when the data was loaded into the Silver layer.

### Data validation

The Silver layer includes a dedicated `silver.ValidateData` stored procedure used to verify the quality of the transformed data.

The validation includes:

* **row count checks** between Bronze and Silver,
* **conversion checks** (values that failed to convert to their target data type),
* **required field `NULL` checks**,
* **value range checks** (e.g., non-negative prices, valid review scores),
* **date consistency checks** (chronological timestamp integrity),
* **referential integrity checks** (orphan foreign key identification),
* **duplicate primary key checks** (single and composite primary key uniqueness),
* **audit field checks** (`LoadTimestamp` verification).

The validation procedure is executed after the Silver load to identify unexpected issues introduced during the transformation process before the data is used in the Gold layer.

### Key data quality fixes in Silver

During the Silver load, specific source data anomalies are handled deterministically:

* **Invalid carrier dates:** 166 records with carrier pickup dates earlier than purchase timestamps are converted to `NULL` to preserve order data without distorting logistics KPIs.
* **Zero installments:** Payment records with `0` installments are mapped to `1` (single-lump payment) to prevent division-by-zero errors in downstream calculations.
* **Orphan sellers:** 3 seller references in order items missing from the seller directory are retained in Silver and mapped to an **Unknown Member (`-1`)** in the Gold dimensional schema.

### Validation status: PASS vs. PASS WITH WARNINGS

`run_pipeline.sql` aggregates the row-level results of `silver.ValidateData` (and, analogously, `gold.ValidateData`) into one of two outcomes per layer:

* **PASS** — no validation check reported an issue.
* **PASS WITH WARNINGS (N issues)** — one or more checks reported an issue, but the pipeline is allowed to continue rather than being aborted.

For this project, a warning is not noise to be ignored. The Olist dataset is a static, historical CSV export rather than a live, continuously changing feed. It was fully diagnosed once using `silver.ValidateData`, and every issue it currently reports corresponds exactly to the known, deliberately accepted anomalies documented above: the 166 invalid carrier dates, the 2 zero-installment payments, and the 3 orphan seller references. These are left in the Silver layer on purpose, and the orphan sellers are resolved explicitly in the Gold layer by mapping them to the Unknown Member (`SellerKey = -1`).

A `PASS WITH WARNINGS` result when running the pipeline against the dataset shipped in this repository is therefore expected and acceptable. Since the source data does not change, the issue count and the specific failing checks should always match what is documented here; any deviation from this (a different issue count, or a different check failing) would indicate something worth investigating, not an expected warning.

## Gold layer — dimensional model

The Gold layer is designed according to **Kimball dimensional modeling principles**, with the goal of creating a business-oriented analytical model rather than simply exposing the structure of the source data.

The model was designed by first identifying the **business processes and the grain of each fact table**, and then selecting the dimensions and measures required to support analytical use cases.

### Business processes

The Gold layer covers four main business processes:

1. **Orders & Fulfillment** — tracking orders and their delivery lifecycle.
2. **Sales** — analyzing individual items purchased within orders.
3. **Payments** — analyzing payment methods, values and installments.
4. **Reviews** — analyzing customer reviews and review scores.

### Fact tables

Each fact table has a clearly defined grain:

| Fact Table            | Grain                  |
| ---------------------- | ---------------------- |
| `fact_orders`         | One row per order      |
| `fact_order_items`    | One row per order item |
| `fact_order_payments` | One row per payment    |
| `fact_order_reviews`  | One row per review     |

This grain definition determines which dimensions and measures can be correctly associated with each fact.

### Dimension tables

The model contains four conformed dimensions:

* `dim_customer` — customer information and location.
* `dim_product` — product attributes and category information.
* `dim_seller` — seller information and location.
* `dim_date` — calendar attributes used by the fact tables.

The `dim_date` dimension is used as a **role-playing dimension**, allowing different dates from the same fact table to be analyzed independently — for example purchase date, approval date, carrier date and delivery date.

### Surrogate keys

Dimensions use **surrogate keys** as their primary keys. Source-system identifiers are retained as business keys where appropriate.

This separates the analytical model from source-system identifiers and provides a more robust foundation for future changes to source data or the ETL process.

### Slowly changing dimensions

The dimensions use a **Type 1 Slowly Changing Dimension (SCD)** approach.

Historical attribute changes are not tracked because the Olist dataset represents a static historical dataset and does not provide a meaningful stream of dimension changes over time.

### Business-oriented Gold layer

The Gold layer does not reproduce every column from the Silver layer. Columns were selected based on their analytical or business value.

For example, product attributes such as `NameLength` and `DescriptionLength` were excluded because they do not provide a sufficiently meaningful business use case for this project.

The Gold layer also contains selected **derived business attributes**, such as:

* delivery and processing durations,
* delivery status indicators,
* late-delivery indicators,
* additive count measures.

These attributes are calculated during the Gold transformation rather than copied directly from the source.

### Data relationships

Fact tables are connected to dimensions through surrogate keys. Fact tables are not directly linked to one another.

`OrderId` is retained in the relevant fact tables as a business identifier, allowing the same order to be analyzed across different business processes without introducing fact-to-fact dependencies.

The review fact does not contain a product key because a review is associated with an order rather than with a uniquely identifiable product. An order may contain multiple products, so assigning a review directly to a product would introduce an incorrect relationship.

## Manual execution

`run_pipeline.bat` is the recommended way to run the project. The same steps can also be run manually, for example for debugging or to run a single layer in isolation.

```bash
# Start SQL Server and wait for it to report healthy
docker compose up -d --wait sqlserver

# Convert the source CSV files
docker compose run --rm preprocessing

# Run the full SQL pipeline (Bronze -> Silver -> Gold, with validation)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "<YOUR_PASSWORD>" -C -b -i /scripts/run_pipeline.sql
```

Individual numbered scripts in `scripts/` can also be run on their own (e.g. to rebuild only one layer), as long as the scripts they depend on have already been executed in order.

## Project structure

```text
SQL-Server-Olist/
│
├── data/
│   ├── raw/
│   └── prepared/
│
├── scripts/
│   ├── preprocess.py
│   ├── 01_create_database.sql
│   ├── 02_create_bronze_layer.sql
│   ├── 03_load_bronze_layer.sql
│   ├── 04_create_silver_layer.sql
│   ├── 05_load_silver_layer.sql
│   ├── 06_validate_silver_layer.sql
│   ├── 07_create_gold_layer.sql
│   ├── 08_load_gold_layer.sql
│   ├── 09_validate_gold_layer.sql
│   └── run_pipeline.sql
│
├── logs/
│
├── docker-compose.yaml
├── run_pipeline.bat
├── .env
├── .gitignore
├── LICENSE
└── README.md
```

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
