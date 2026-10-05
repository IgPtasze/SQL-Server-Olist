# Olist SQL Server Data Warehouse

Data engineering portfolio project based on the **Brazilian E-Commerce Public Dataset by Olist**.

The project focuses on building a data warehouse in **Microsoft SQL Server**, with the data pipeline and database environment containerized using Docker.

## Project status

Current stage:

* [x] Docker environment
* [x] Data preprocessing
* [x] Bronze layer
* [x] Silver layer
* [ ] Gold layer
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

The current implementation covers the **preprocessing, Bronze and Silver layers**.

## Technologies

* **Microsoft SQL Server 2022**
* **Docker / Docker Compose**
* **Python**
* **T-SQL**
* **Git / GitHub**

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

The Bronze layer uses a dedicated `bronze` schema.

Tables are created to represent the source Olist datasets, with data types selected primarily to safely accommodate the source data rather than optimize it for analytical queries.

### Data loading

Data is loaded into Bronze using the `bronze.LoadData` stored procedure.

The procedure:

1. clears the target Bronze tables,
2. loads the prepared CSV files using `BULK INSERT`,
3. loads the data using SQL Server's Unicode/wide-character support,
4. performs the load within a transaction,
5. records the execution time of the load.

Using a transaction ensures that the Bronze layer is not left in a partially loaded state if an error occurs during the loading process.

This provides a repeatable way of rebuilding the Bronze layer from the converted source files.

## Silver layer

The Silver layer is responsible for cleaning, transforming and validating the data loaded into the Bronze layer.

The main goals of this layer are:

* converting source values to appropriate SQL Server data types,
* handling empty values and `NULL`s,
* trimming text values,
* cleaning problematic characters from source values,
* preparing the data for further transformation in the Gold layer,
* validating the quality of the loaded data.

The Silver layer uses a dedicated `silver` schema.

Tables in the Silver layer use more appropriate data types than the Bronze layer. For example, numeric values are converted to `INT` or `DECIMAL`, date and time values are converted to `DATETIME2`, and text fields use appropriate `NVARCHAR` lengths.

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
* **Orphan sellers:** 3 seller references in order items missing from the seller directory are retained in Silver and will be mapped to an **Unknown Member (`-1`)** in the Gold dimensional schema.

## Running the project

### 1. Clone the repository

```bash
git clone https://github.com/IgPtasze/SQL-Server-Olist.git
cd SQL-Server-Olist
```

### 2. Configure environment variables

Create a `.env` file in the project root with the SQL Server configuration required by `docker-compose.yaml`.

Example:

```env
MSSQL_SA_PASSWORD=YourStrongPassword
```

The `.env` file is excluded from version control.

### 3. Start the containers

```bash
docker compose up -d
```

This starts:

* the SQL Server container,
* the preprocessing container.

### 4. Run preprocessing

The preprocessing container prepares the source CSV files for SQL Server.

### 5. Load Bronze

Connect to the SQL Server instance and execute the database, schema and Bronze layer scripts, followed by the `bronze.LoadData` procedure.

The Bronze layer can then be rebuilt from the prepared source files.

### 6. Load and validate Silver

After the Bronze layer has been loaded, execute the Silver layer scripts and run the `silver.LoadData` procedure.

After the Silver load is completed, run `silver.ValidateData` to verify the row counts, conversions, required fields, value ranges and date consistency.

## Project structure

```text
SQL-Server-Olist/
│
├── data/
│   ├── raw/
│   └── prepared/
│
├── scripts/
│   ├── ...
│   └── preprocess.py
│
├── docker-compose.yaml
├── .env
├── .gitignore
└── README.md
```

## Source data

The project uses the **Brazilian E-Commerce Public Dataset by Olist**, containing information about orders, customers, products, sellers, payments, reviews and related entities.

The dataset is used as the source for building the data warehouse and developing business-oriented analytical questions in later stages.
