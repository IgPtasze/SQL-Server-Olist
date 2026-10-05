/*
===============================================================================
Stored Procedure: Load Data Into Bronze Layer
===============================================================================
*/
USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE bronze.LoadData AS
BEGIN
    DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @BatchStartTime DATETIME2;

    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();

        -- Wrap in an atomic transaction for pipeline failure safety (Docker / CI/CD execution)
        BEGIN TRANSACTION;

        PRINT 'Loading Data Into Bronze Layer:'

        -- 1) Load data from olist_customers_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.Customers'
        TRUNCATE TABLE bronze.Customers;
    
        PRINT '    Inserting Data Into: bronze.Customers'
        BULK INSERT bronze.Customers
        FROM '/var/opt/mssql/csv/olist_customers_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                    ';


        -- 2) Load data from olist_geolocation_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.Geolocation'
        TRUNCATE TABLE bronze.Geolocation;

        PRINT '    Inserting Data Into: bronze.Geolocation'
        BULK INSERT bronze.Geolocation
        FROM '/var/opt/mssql/csv/olist_geolocation_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        -- 3) Load data from olist_order_items_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.OrderItems'
        TRUNCATE TABLE bronze.OrderItems;

        PRINT '    Inserting Data Into: bronze.OrderItems'
        BULK INSERT bronze.OrderItems
        FROM '/var/opt/mssql/csv/olist_order_items_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        -- 4) Load data from olist_order_payments_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.OrderPayments'
        TRUNCATE TABLE bronze.OrderPayments;

        PRINT '    Inserting Data Into: bronze.OrderPayments'
        BULK INSERT bronze.OrderPayments
        FROM '/var/opt/mssql/csv/olist_order_payments_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        -- 5) Load data from olist_order_reviews_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.OrderReviews'
        TRUNCATE TABLE bronze.OrderReviews;

        PRINT '    Inserting Data Into: bronze.OrderReviews'
        BULK INSERT bronze.OrderReviews
        FROM '/var/opt/mssql/csv/olist_order_reviews_dataset.csv'
        WITH (
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 6) Load data from olist_orders_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.Orders'
        TRUNCATE TABLE bronze.Orders;

        PRINT '    Inserting Data Into: bronze.Orders'
        BULK INSERT bronze.Orders
        FROM '/var/opt/mssql/csv/olist_orders_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 7) Load data from olist_products_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.Products'
        TRUNCATE TABLE bronze.Products;

        PRINT '    Inserting Data Into: bronze.Products'
        BULK INSERT bronze.Products
        FROM '/var/opt/mssql/csv/olist_products_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 8) Load data from olist_sellers_dataset.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.Sellers'
        TRUNCATE TABLE bronze.Sellers;

        PRINT '    Inserting Data Into: bronze.Sellers'
        BULK INSERT bronze.Sellers
        FROM '/var/opt/mssql/csv/olist_sellers_dataset.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';
        

        -- 9) Load data from product_category_name_translation.csv --
        SET @StartTime = SYSDATETIME();
        PRINT '    Truncating Table: bronze.ProductCategoryNameTranslation'
        TRUNCATE TABLE bronze.ProductCategoryNameTranslation;

        PRINT '    Inserting Data Into: bronze.ProductCategoryNameTranslation'
        BULK INSERT bronze.ProductCategoryNameTranslation
        FROM '/var/opt/mssql/csv/product_category_name_translation.csv'
        WITH (
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            TABLOCK
        );
        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';

        -- Commit transaction if all table loads succeed
        COMMIT TRANSACTION;

        -- Calculate loading time for whole bronze layer --
        SET @EndTime = SYSDATETIME();
        PRINT 'Bronze Layer Load Duration: ' + CAST(DATEDIFF(second, @BatchStartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';

    END TRY
    -- Catch errors --
    BEGIN CATCH
        -- Rollback changes in case of failure to maintain consistent Bronze state
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        PRINT '!!! ERROR OCCURRED DURING LOADING DATA !!!';
        PRINT CAST(ERROR_NUMBER() AS NVARCHAR) + ' - ' + ERROR_MESSAGE() + ' (State: ' + CAST(ERROR_STATE() AS NVARCHAR) + ')';
        PRINT '!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! ';

        -- Re-throw error to trigger exit code in Docker container / pipeline orchestrator
        THROW;
    END CATCH
END;
GO