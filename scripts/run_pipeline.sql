:on error exit

:r /scripts/01_create_database.sql

USE OlistDWH;
GO

:r /scripts/02_create_bronze_layer.sql
:r /scripts/03_load_bronze_layer.sql

PRINT 'Loading Bronze data...';
EXEC bronze.LoadData;
GO

:r /scripts/04_create_silver_layer.sql
:r /scripts/05_load_silver_layer.sql

PRINT 'Loading Silver data...';
EXEC silver.LoadData;
GO

:r /scripts/06_validate_silver_layer.sql

PRINT 'Validating Silver data...';
EXEC silver.ValidateData;
GO

:r /scripts/07_create_gold_layer.sql
:r /scripts/08_load_gold_layer.sql

PRINT 'Loading Gold data...';
EXEC gold.LoadData;
GO

:r /scripts/09_validate_gold_layer.sql

PRINT 'Validating Gold data...';
EXEC gold.ValidateData;
GO