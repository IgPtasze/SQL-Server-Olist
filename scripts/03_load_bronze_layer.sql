/*
===============================================================================
Stored Procedure: Load Data Into Bronze Layer
===============================================================================
Loads source CSV files into the Bronze layer using BULK INSERT.

Source data is loaded as NVARCHAR to preserve the original values before
transformation and type conversion in the Silver layer.

Source files are converted to UTF-16 during preprocessing to support loading
into SQL Server running in a Linux-based Docker container.

Every BULK INSERT uses MAXERRORS = 0. The default (10) lets BULK INSERT skip
up to 10 rows that fail to load and still report success. This is what hid
the "orphan sellers" bug described in the README (its cause was a missing
FORMAT = 'CSV'). MAXERRORS = 0 is intended to stop the load at the first
failed row.

After the load, the number of rows in each Bronze table is compared with the
row count manifest written by preprocess.py. Any difference raises an error
and rolls back the whole Bronze load. This check does not depend on how
MAXERRORS counts errors: a row that is skipped for any reason, or rows that
are split or merged incorrectly, change the net row count. (Two faults in the
same file that cancel each other out, e.g. one skipped and one split row,
would keep the count.)

Limitation: a parsing problem that moves values between columns inside one
row keeps the row count. Neither check detects it; it is detected only if the
moved value fails a type conversion or a Silver validation rule.
===============================================================================
*/

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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
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
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
            TABLOCK
        );

        SET @EndTime = SYSDATETIME();
        PRINT '    Table Load Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
        PRINT '                         ';


        /* ============================================================================
           Source Row Count Reconciliation
        ============================================================================ */

        SET @StartTime = SYSDATETIME();

        PRINT '    Truncating Table: bronze.SourceRowCounts'
        TRUNCATE TABLE bronze.SourceRowCounts;

        PRINT '    Inserting Data Into: bronze.SourceRowCounts'
        BULK INSERT bronze.SourceRowCounts
        FROM '/var/opt/mssql/csv/source_row_counts.csv'
        WITH (
            FORMAT = 'CSV',
            DATAFILETYPE = 'widechar',
            FIELDQUOTE = '"',
            FIRSTROW = 2,
            FIELDTERMINATOR = '0x2c00',
            ROWTERMINATOR = '0x0a00',
            MAXERRORS = 0,
            TABLOCK
        );

        PRINT '    Comparing source file row counts with Bronze tables'

        DECLARE @RowCountIssues NVARCHAR(MAX);
        DECLARE @RowCountMessage NVARCHAR(2048);

        /*
        FULL OUTER JOIN: a file missing from the manifest, or a manifest entry
        without a matching Bronze table, is also reported as an issue.
        */
        WITH BronzeCounts AS (
            SELECT N'olist_customers_dataset.csv' AS FileName, COUNT_BIG(*) AS BronzeRowCount FROM bronze.Customers
            UNION ALL
            SELECT N'olist_geolocation_dataset.csv', COUNT_BIG(*) FROM bronze.Geolocation
            UNION ALL
            SELECT N'olist_order_items_dataset.csv', COUNT_BIG(*) FROM bronze.OrderItems
            UNION ALL
            SELECT N'olist_order_payments_dataset.csv', COUNT_BIG(*) FROM bronze.OrderPayments
            UNION ALL
            SELECT N'olist_order_reviews_dataset.csv', COUNT_BIG(*) FROM bronze.OrderReviews
            UNION ALL
            SELECT N'olist_orders_dataset.csv', COUNT_BIG(*) FROM bronze.Orders
            UNION ALL
            SELECT N'olist_products_dataset.csv', COUNT_BIG(*) FROM bronze.Products
            UNION ALL
            SELECT N'olist_sellers_dataset.csv', COUNT_BIG(*) FROM bronze.Sellers
            UNION ALL
            SELECT N'product_category_name_translation.csv', COUNT_BIG(*) FROM bronze.ProductCategoryNameTranslation
        ),
        SourceCounts AS (
            SELECT
                TRIM(FileName) AS FileName,
                TRIM(SourceRowCount) AS SourceRowCountText,
                TRY_CONVERT(BIGINT, TRIM(SourceRowCount)) AS SourceRowCount
            FROM bronze.SourceRowCounts
        )
        /*
        CAST to NVARCHAR(MAX): without it, STRING_AGG output is limited to
        8000 bytes and a long list of issues would fail with error 9829
        instead of the readable error below.
        */
        SELECT @RowCountIssues = STRING_AGG(
            CAST(
                CONCAT(
                    COALESCE(b.FileName, s.FileName),
                    N' (source: ',
                    CASE
                        WHEN s.FileName IS NULL
                            THEN N'missing'
                        WHEN s.SourceRowCount IS NULL
                            THEN CONCAT(N'invalid value "', s.SourceRowCountText, N'"')
                        ELSE CAST(s.SourceRowCount AS NVARCHAR(20))
                    END,
                    N', bronze: ', COALESCE(CAST(b.BronzeRowCount AS NVARCHAR(20)), N'missing'),
                    N')'
                ) AS NVARCHAR(MAX)
            ),
            N'; '
        ) WITHIN GROUP (ORDER BY COALESCE(b.FileName, s.FileName))
        FROM BronzeCounts b
        FULL OUTER JOIN SourceCounts s
            ON b.FileName = s.FileName
        WHERE b.BronzeRowCount IS NULL
           OR s.SourceRowCount IS NULL
           OR b.BronzeRowCount <> s.SourceRowCount;

        IF @RowCountIssues IS NOT NULL
        BEGIN
            SET @RowCountMessage = LEFT(
                CONCAT(N'Row count mismatch between source files and Bronze: ', @RowCountIssues),
                2048
            );
            THROW 50001, @RowCountMessage, 1;
        END;

        PRINT '    Row Count Reconciliation: PASS'

        SET @EndTime = SYSDATETIME();
        PRINT '    Reconciliation Duration: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' seconds';
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
