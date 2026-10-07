/*
===============================================================================
Stored Procedure: Load Data Into Bronze Layer
===============================================================================
Loads source CSV files into the Bronze layer using BULK INSERT.

Source data is loaded as NVARCHAR to preserve the original values before
transformation and type conversion in the Silver layer.

Source files are converted to UTF-16 during preprocessing to support loading
into SQL Server running in a Linux-based Docker container.
===============================================================================
*/

USE OlistDWH;
GO

CREATE OR ALTER PROCEDURE bronze.LoadData AS
BEGIN
    DECLARE @StartTime DATETIME2, @EndTime DATETIME2, @BatchStartTime DATETIME2;

    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();

        /* ============================================================================
           Load Bronze Layer
        ============================================================================ */

        BEGIN TRANSACTION;

        PRINT 'Loading Data Into Bronze Layer:'


        /* ----------------------------------------------------------------------------
           Customers
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Geolocation
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Order Items
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Order Payments
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Order Reviews
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Orders
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Products
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Sellers
        ---------------------------------------------------------------------------- */

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


        /* ----------------------------------------------------------------------------
           Product Category Name Translation
        ---------------------------------------------------------------------------- */

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


        /* ============================================================================
           Commit Transaction
        ============================================================================ */

        COMMIT TRANSACTION;

        SET @EndTime = SYSDATETIME();

        PRINT 'Bronze Layer Load Duration: ' + CAST(DATEDIFF(second, @BatchStartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


    END TRY


    /* ============================================================================
       Error Handling
    ============================================================================ */

    BEGIN CATCH

        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;

        PRINT '!!! ERROR OCCURRED DURING LOADING DATA !!!';
        PRINT CAST(ERROR_NUMBER() AS NVARCHAR) + ' - ' + ERROR_MESSAGE() + ' (State: ' + CAST(ERROR_STATE() AS NVARCHAR) + ')';
        PRINT '!!! !!! !!! !!! !!! !!! !!! !!! !!! !!! ';

        THROW;

    END CATCH
END;
GO